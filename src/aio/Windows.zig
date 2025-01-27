const builtin = @import("builtin");
const std = @import("std");
const aio = @import("../aio.zig");
const Operation = @import("ops.zig").Operation;
const DynamicThreadPool = @import("minilib").DynamicThreadPool;
const TimerQueue = @import("minilib").TimerQueue;
const Uringlator = @import("uringlator.zig").Uringlator(WindowsOperation);
const Iocp = @import("posix/windows.zig").Iocp;
const wposix = @import("posix/windows.zig");
const win32 = @import("win32");
const windows = std.os.windows;

const checked = wposix.checked;
const wtry = wposix.wtry;
const INVALID_HANDLE = windows.INVALID_HANDLE_VALUE;
const HANDLE = windows.HANDLE;
const CloseHandle = wposix.CloseHandle;
const INFINITE = windows.INFINITE;
const fs = win32.storage.file_system;
const win_sock = windows.ws2_32;
const INVALID_SOCKET = win_sock.INVALID_SOCKET;

// Optimized for Windows and uses IOCP operations whenever possible.
// <https://int64.org/2009/05/14/io-completion-ports-made-easy/>

comptime {
    if (builtin.single_threaded) {
        @compileError(
            \\Windows backend requires building with threads as otherwise it may block the whole program.
        );
    }
}

pub const EventSource = wposix.EventSource;

const IoContext = struct {
    overlapped: windows.OVERLAPPED = std.mem.zeroes(windows.OVERLAPPED),

    // needs to be cleaned up
    owned: union(enum) {
        handle: windows.HANDLE,
        job: windows.HANDLE,
        none: void,
    } = .none,

    // operation specific return value
    res: usize = 0,

    pub fn deinit(self: *@This()) void {
        switch (self.owned) {
            inline .handle, .job => |h| checked(windows.ntdll.NtClose(h) == .SUCCESS),
            .none => {},
        }
        self.* = undefined;
    }
};

const WindowsOperation = struct {
    const State = union {
        event_source: EventSource.OperationContext, // links event sources to iocp completions
        wsabuf: [1]win_sock.WSABUF, // wsabuf for send/recv
        accept: [@sizeOf(std.posix.sockaddr) * 2 + 16 * 2]u8,
    };
    ovl: IoContext, // overlapped struct
    win_state: State, // windows specific state
};

iocp: Iocp,
posix_pool: DynamicThreadPool, // thread pool for performing non iocp operations
tqueue: TimerQueue, // timer queue implementing linux -like timers
signaled: bool = false, // some operations have signaled immediately, optimization to polling iocp when not required
uringlator: Uringlator,

pub fn isSupported(ops: []const Operation) bool {
    for (ops) |op| {
        if (op == .poll) return false;
    }
    return true;
}

pub fn init(allocator: std.mem.Allocator, n: u16) aio.Error!@This() {
    var iocp = try Iocp.init(1);
    errdefer iocp.deinit();
    var tqueue = try TimerQueue.init(allocator);
    errdefer tqueue.deinit();
    var posix_pool = DynamicThreadPool.init(allocator, .{
        .max_threads = aio.options.max_threads,
        .name = "aio:POSIX",
        .stack_size = @import("posix/posix.zig").stack_size,
    }) catch |err| return switch (err) {
        error.TimerUnsupported => error.Unsupported,
        else => |e| e,
    };
    errdefer posix_pool.deinit();
    var uringlator = try Uringlator.init(allocator, n);
    errdefer uringlator.deinit(allocator);
    return .{
        .iocp = iocp,
        .tqueue = tqueue,
        .posix_pool = posix_pool,
        .uringlator = uringlator,
    };
}

pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
    self.uringlator.shutdown(self);
    self.tqueue.deinit();
    self.posix_pool.deinit();
    self.iocp.deinit();
    self.uringlator.deinit(allocator);
    self.* = undefined;
}

pub fn queue(self: *@This(), pairs: anytype, handler: anytype) aio.Error!void {
    try self.uringlator.queue(pairs, self, handler);
}

fn werr() Operation.Error {
    _ = try wtry(@as(i32, 0));
    return error.Success;
}

fn poll(self: *@This(), mode: aio.Dynamic.CompletionMode, comptime safety: Uringlator.Safety) error{Shutdown}!void {
    var transferred: u32 = undefined;
    var key: Iocp.Key = undefined;
    var maybe_ovl: ?*windows.OVERLAPPED = null;
    const res = windows.kernel32.GetQueuedCompletionStatus(self.iocp.port, &transferred, @ptrCast(&key), &maybe_ovl, switch (mode) {
        .blocking => INFINITE,
        .nonblocking => 0,
    });
    if (res != 1 and maybe_ovl == null) return;

    const id: aio.Id = switch (key.type) {
        .nop => return, // non iocp operation finished
        .shutdown, .event_source, .child_exit => key.id,
        .overlapped => blk: {
            const parent: *IoContext = @fieldParentPtr("overlapped", maybe_ovl.?);
            break :blk self.uringlator.ops.unsafeIdFromSlot(@intCast((@intFromPtr(parent) - @intFromPtr(self.uringlator.ops.soa.ovl)) / @sizeOf(IoContext)));
        },
    };

    Uringlator.debug("iocp: {}", .{key.type});

    if (res == 1) {
        switch (key.type) {
            .nop => unreachable, // already handled
            .shutdown => return error.Shutdown,
            .event_source => {
                const source: *EventSource = @ptrCast(@alignCast(maybe_ovl.?));
                source.waitNonBlocking() catch {};
            },
            .child_exit => {
                switch (transferred) {
                    win32.system.system_services.JOB_OBJECT_MSG_EXIT_PROCESS, win32.system.system_services.JOB_OBJECT_MSG_ABNORMAL_EXIT_PROCESS => {},
                    else => return, // not the event we care about
                }
                const state = self.uringlator.ops.getOnePtr(.state, id);
                const out_term = self.uringlator.ops.getOne(.out_result, id).cast(?*std.process.Child.Term);
                if (out_term) |term| {
                    var code: u32 = undefined;
                    if (windows.kernel32.GetExitCodeProcess(state.child_exit.child, &code) == 0) {
                        term.* = .{ .Unknown = 0 };
                    } else {
                        term.* = .{ .Exited = @truncate(code) };
                    }
                }
            },
            .overlapped => {
                const parent: *IoContext = @fieldParentPtr("overlapped", maybe_ovl.?);
                parent.res = transferred;
            },
        }
        self.uringlator.finish(self, id, error.Success, safety);
    } else {
        std.debug.assert(key.type == .overlapped);
        self.uringlator.finish(self, id, werr(), safety);
    }
}

pub fn complete(self: *@This(), mode: aio.Dynamic.CompletionMode, handler: anytype) aio.Error!aio.CompletionResult {
    if (!try self.uringlator.submit(self)) return .{};
    var res: aio.CompletionResult = .{};
    while (res.num_completed == 0 and res.num_errors == 0) {
        if (!self.signaled) self.poll(mode, .thread_unsafe) catch unreachable;
        self.signaled = false;
        res = self.uringlator.complete(self, handler);
        if (mode == .nonblocking) break;
    }
    return res;
}

pub fn immediate(pairs: anytype) aio.Error!u16 {
    const Static = struct {
        threadlocal var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    };
    const allocator = Static.arena.allocator();
    defer _ = Static.arena.reset(.retain_capacity);
    var wrk = try init(allocator, pairs.len);
    defer wrk.deinit(allocator);
    try wrk.queue(pairs, {});
    var n: u16 = pairs.len;
    var num_errors: u16 = 0;
    while (n > 0) {
        const res = try wrk.complete(.blocking, {});
        n -= res.num_completed;
        num_errors += res.num_errors;
    }
    return num_errors;
}

fn blockingPosixExecutor(self: *@This(), comptime op_type: Operation, op: Operation.map.getAssertContains(op_type), id: aio.Id, comptime safety: Uringlator.Safety) void {
    const posix = @import("posix/posix.zig");
    var failure: Operation.Error = error.Success;
    while (true) {
        posix.perform(op_type, op, undefined) catch |err| {
            if (err == error.WouldBlock) continue;
            failure = err;
        };
        break;
    }
    self.uringlator.finish(self, id, failure, safety);
}

fn onThreadTimeout(ctx: *anyopaque, user_data: usize) void {
    var self: *@This() = @ptrCast(@alignCast(ctx));
    self.uringlator.finish(self, aio.Id.init(user_data), error.Success, .thread_safe);
}

fn ovlOff(offset: u64) windows.OVERLAPPED {
    return .{
        .Internal = 0,
        .InternalHigh = 0,
        .DUMMYUNIONNAME = .{ .DUMMYSTRUCTNAME = @bitCast(offset) },
        .hEvent = null,
    };
}

const AccessInfo = packed struct {
    read: bool,
    write: bool,
    append: bool,
};

fn getHandleAccessInfo(handle: windows.HANDLE) !fs.FILE_ACCESS_FLAGS {
    var io_status_block: windows.IO_STATUS_BLOCK = undefined;
    var access: windows.FILE_ACCESS_INFORMATION = undefined;
    const rc = windows.ntdll.NtQueryInformationFile(handle, &io_status_block, &access, @sizeOf(windows.FILE_ACCESS_INFORMATION), .FileAccessInformation);
    switch (rc) {
        .SUCCESS => {},
        .INVALID_PARAMETER => unreachable,
        else => return error.Unexpected,
    }
    return @bitCast(access.AccessFlags);
}

pub fn uringlator_queue(self: *@This(), id: aio.Id, comptime op_type: Operation, op: Operation.map.getAssertContains(op_type)) aio.Error!WindowsOperation {
    switch (op_type) {
        .poll => return aio.Error.Unsupported,
        .accept => op.out_socket.* = INVALID_SOCKET,
        else => {},
    }
    return .{
        .ovl = .{},
        .win_state = switch (op_type) {
            .wait_event_source => .{ .event_source = .{ .id = id, .iocp = &self.iocp } },
            inline .recv, .send => .{ .wsabuf = .{.{ .buf = @constCast(@ptrCast(op.buffer.ptr)), .len = @intCast(op.buffer.len) }} },
            .accept => .{ .accept = undefined },
            else => undefined,
        },
    };
}

pub fn uringlator_dequeue(_: *@This(), _: aio.Id, comptime op_type: Operation, _: Operation.map.getAssertContains(op_type)) void {}

pub fn uringlator_start(self: *@This(), id: aio.Id, op_type: Operation) !void {
    switch (op_type) {
        .poll => unreachable,
        .read => {
            const state = self.uringlator.ops.getOnePtr(.state, id);
            const ovl = self.uringlator.ops.getOnePtr(.ovl, id);
            const flags = try getHandleAccessInfo(state.read.file.handle);
            if (flags.FILE_READ_DATA != 1) return self.uringlator.finish(self, id, error.NotOpenForReading, .thread_unsafe);
            const h = fs.ReOpenFile(state.read.file.handle, flags, .{ .READ = 1, .WRITE = 1 }, fs.FILE_FLAG_OVERLAPPED);
            _ = wtry(h != null and h.? != INVALID_HANDLE) catch |err| return self.uringlator.finish(self, id, err, .thread_unsafe);
            self.iocp.associateHandle(id, h.?) catch |err| return self.uringlator.finish(self, id, err, .thread_unsafe);
            ovl.* = .{ .overlapped = ovlOff(state.read.offset), .owned = .{ .handle = h.? } };
            var read: u32 = undefined;
            const ret = wtry(windows.kernel32.ReadFile(h.?, state.read.buffer.ptr, @intCast(state.read.buffer.len), &read, &ovl.overlapped)) catch |err| return self.uringlator.finish(self, id, err, .thread_unsafe);
            if (ret != 0) {
                ovl.res = read;
                self.uringlator.finish(self, id, error.Success, .thread_unsafe);
            }
        },
        .write => {
            const state = self.uringlator.ops.getOnePtr(.state, id);
            const ovl = self.uringlator.ops.getOnePtr(.ovl, id);
            const flags = try getHandleAccessInfo(state.write.file.handle);
            if (flags.FILE_WRITE_DATA != 1) return self.uringlator.finish(self, id, error.NotOpenForWriting, .thread_unsafe);
            const h = fs.ReOpenFile(state.write.file.handle, flags, .{ .READ = 1, .WRITE = 1 }, fs.FILE_FLAG_OVERLAPPED);
            _ = wtry(h != null and h.? != INVALID_HANDLE) catch |err| return self.uringlator.finish(self, id, err, .thread_unsafe);
            self.iocp.associateHandle(id, h.?) catch |err| return self.uringlator.finish(self, id, err, .thread_unsafe);
            ovl.* = .{ .overlapped = ovlOff(state.write.offset), .owned = .{ .handle = h.? } };
            var written: u32 = undefined;
            const ret = wtry(windows.kernel32.WriteFile(h.?, state.write.buffer.ptr, @intCast(state.write.buffer.len), &written, &ovl.overlapped)) catch |err| return self.uringlator.finish(self, id, err, .thread_unsafe);
            if (ret != 0) {
                ovl.res = written;
                self.uringlator.finish(self, id, error.Success, .thread_unsafe);
            }
        },
        .accept => {
            const out_socket = self.uringlator.ops.getOne(.out_result, id).cast(*std.posix.socket_t);
            const win_state = self.uringlator.ops.getOnePtr(.win_state, id);
            const state = self.uringlator.ops.getOnePtr(.state, id);
            const ovl = self.uringlator.ops.getOnePtr(.ovl, id);
            self.iocp.associateSocket(id, state.accept.socket) catch |err| return self.uringlator.finish(self, id, err, .thread_unsafe);
            out_socket.* = aio.socket(std.posix.AF.INET, 0, 0) catch |err| return self.uringlator.finish(self, id, err, .thread_unsafe);
            var read: u32 = undefined;
            if (wtry(win_sock.AcceptEx(state.accept.socket, out_socket.*, &win_state.accept, 0, @sizeOf(std.posix.sockaddr) + 16, @sizeOf(std.posix.sockaddr) + 16, &read, &ovl.overlapped) == 1) catch |err| return self.uringlator.finish(self, id, err, .thread_unsafe)) {
                ovl.res = read;
                self.uringlator.finish(self, id, error.Success, .thread_unsafe);
            }
        },
        .recv => {
            const win_state = self.uringlator.ops.getOnePtr(.win_state, id);
            const state = self.uringlator.ops.getOnePtr(.state, id);
            const ovl = self.uringlator.ops.getOnePtr(.ovl, id);
            self.iocp.associateSocket(id, state.recv.socket) catch |err| return self.uringlator.finish(self, id, err, .thread_unsafe);
            switch (wposix.recvEx(state.recv.socket, &win_state.wsabuf, 0, &ovl.overlapped) catch |err| return self.uringlator.finish(self, id, err, .thread_unsafe)) {
                .pending => {},
                .transmitted => |bytes| {
                    ovl.res = bytes;
                    self.uringlator.finish(self, id, error.Success, .thread_unsafe);
                },
            }
        },
        .send => {
            const win_state = self.uringlator.ops.getOnePtr(.win_state, id);
            const state = self.uringlator.ops.getOnePtr(.state, id);
            const ovl = self.uringlator.ops.getOnePtr(.ovl, id);
            self.iocp.associateSocket(id, state.send.socket) catch |err| return self.uringlator.finish(self, id, err, .thread_unsafe);
            switch (wposix.sendEx(state.send.socket, &win_state.wsabuf, 0, &ovl.overlapped) catch |err| return self.uringlator.finish(self, id, err, .thread_unsafe)) {
                .pending => {},
                .transmitted => |bytes| {
                    ovl.res = bytes;
                    self.uringlator.finish(self, id, error.Success, .thread_unsafe);
                },
            }
        },
        .recv_msg => {
            const state = self.uringlator.ops.getOnePtr(.state, id);
            const ovl = self.uringlator.ops.getOnePtr(.ovl, id);
            self.iocp.associateSocket(id, state.recv_msg.socket) catch |err| return self.uringlator.finish(self, id, err, .thread_unsafe);
            switch (wposix.recvmsgEx(state.recv_msg.socket, state.recv_msg.out_msg, 0, &ovl.overlapped) catch |err| return self.uringlator.finish(self, id, err, .thread_unsafe)) {
                .pending => {},
                .transmitted => |bytes| {
                    ovl.res = bytes;
                    self.uringlator.finish(self, id, error.Success, .thread_unsafe);
                },
            }
        },
        .send_msg => {
            const state = self.uringlator.ops.getOnePtr(.state, id);
            const ovl = self.uringlator.ops.getOnePtr(.ovl, id);
            self.iocp.associateSocket(id, state.send_msg.socket) catch |err| return self.uringlator.finish(self, id, err, .thread_unsafe);
            switch (wposix.sendmsgEx(state.send_msg.socket, @constCast(state.send_msg.msg), 0, &ovl.overlapped) catch |err| return self.uringlator.finish(self, id, err, .thread_unsafe)) {
                .pending => {},
                .transmitted => |bytes| {
                    ovl.res = bytes;
                    self.uringlator.finish(self, id, error.Success, .thread_unsafe);
                },
            }
        },
        .timeout => {
            const state = self.uringlator.ops.getOnePtr(.state, id);
            const closure: TimerQueue.Closure = .{ .context = self, .callback = onThreadTimeout };
            self.tqueue.schedule(.monotonic, state.timeout.ns, id.cast(usize), .{ .closure = closure }) catch return self.uringlator.finish(self, id, error.Unexpected, .thread_unsafe);
        },
        .link_timeout => {
            const state = self.uringlator.ops.getOnePtr(.state, id);
            const closure: TimerQueue.Closure = .{ .context = self, .callback = onThreadTimeout };
            self.tqueue.schedule(.monotonic, state.link_timeout.ns, id.cast(usize), .{ .closure = closure }) catch return self.uringlator.finish(self, id, error.Unexpected, .thread_unsafe);
        },
        .child_exit => {
            const state = self.uringlator.ops.getOnePtr(.state, id);
            const ovl = self.uringlator.ops.getOnePtr(.ovl, id);
            const job = win32.system.job_objects.CreateJobObjectW(null, null);
            _ = wtry(job != null and job.? != INVALID_HANDLE) catch |err| return self.uringlator.finish(self, id, err, .thread_unsafe);
            errdefer checked(CloseHandle(job.?));
            _ = wtry(win32.system.job_objects.AssignProcessToJobObject(job.?, state.child_exit.child)) catch return self.uringlator.finish(self, id, error.Unexpected, .thread_unsafe);
            const key: Iocp.Key = .{ .type = .child_exit, .id = id };
            var assoc: win32.system.job_objects.JOBOBJECT_ASSOCIATE_COMPLETION_PORT = .{
                .CompletionKey = @ptrFromInt(@as(usize, @bitCast(key))),
                .CompletionPort = self.iocp.port,
            };
            ovl.* = .{ .owned = .{ .job = job.? } };
            errdefer self.ovls[id] = .{};
            _ = wtry(win32.system.job_objects.SetInformationJobObject(
                job.?,
                win32.system.job_objects.JobObjectAssociateCompletionPortInformation,
                @ptrCast(&assoc),
                @sizeOf(@TypeOf(assoc)),
            )) catch return self.uringlator.finish(self, id, error.Unexpected, .thread_unsafe);
        },
        .wait_event_source => {
            const state = self.uringlator.ops.getOnePtr(.state, id);
            const win_state = self.uringlator.ops.getOnePtr(.win_state, id);
            state.wait_event_source.source.native.addWaiter(&win_state.event_source.link);
        },
        // can be performed without a thread
        inline .notify_event_source, .close_event_source => |tag| {
            const result = self.uringlator.ops.getOne(.out_result, id);
            const state = self.uringlator.ops.getOnePtr(.state, id);
            self.blockingPosixExecutor(tag, state.toOp(tag, result), id, .thread_unsafe);
        },
        inline else => |tag| {
            // perform non IOCP supported operation on a thread
            const result = self.uringlator.ops.getOne(.out_result, id);
            const state = self.uringlator.ops.getOnePtr(.state, id);
            try self.posix_pool.spawn(blockingPosixExecutor, .{ self, tag, state.toOp(tag, result), id, .thread_safe });
        },
    }
}

pub fn uringlator_cancel(self: *@This(), id: aio.Id, op_type: Operation, err: Operation.Error) bool {
    switch (op_type) {
        .read, .write => {
            const ovl = self.uringlator.ops.getOnePtr(.ovl, id);
            if (windows.kernel32.CancelIoEx(ovl.owned.handle, &ovl.overlapped) != 0) {
                self.uringlator.finish(self, id, err, .thread_unsafe);
                return true;
            }
            return false;
        },
        inline .accept, .recv, .send, .send_msg, .recv_msg => |tag| {
            const result = self.uringlator.ops.getOne(.out_result, id);
            const op = self.uringlator.ops.getOnePtr(.state, id).toOp(tag, result);
            const ovl = self.uringlator.ops.getOnePtr(.ovl, id);
            if (windows.kernel32.CancelIoEx(@ptrCast(op.socket), &ovl.overlapped) != 0) {
                self.uringlator.finish(self, id, err, .thread_unsafe);
                return true;
            }
            return false;
        },
        .child_exit => {
            var ovl = self.uringlator.ops.getOnePtr(.ovl, id);
            ovl.deinit();
            self.uringlator.finish(self, id, err, .thread_unsafe);
            return true;
        },
        .timeout, .link_timeout => {
            self.tqueue.disarm(.monotonic, id.cast(usize)) catch return false; // raced
            self.uringlator.finish(self, id, err, .thread_unsafe);
            return true;
        },
        .wait_event_source => {
            const state = self.uringlator.ops.getOnePtr(.state, id);
            var ctx = &self.uringlator.ops.getOnePtr(.win_state, id).event_source;
            state.wait_event_source.source.native.removeWaiter(&ctx.link);
            self.uringlator.finish(self, id, err, .thread_unsafe);
            return true;
        },
        else => {},
    }
    return false;
}

pub fn uringlator_complete(self: *@This(), id: aio.Id, op_type: Operation, failure: Operation.Error) void {
    var ovl = self.uringlator.ops.getOnePtr(.ovl, id);
    defer ovl.deinit();
    if (failure == error.Success) {
        switch (op_type) {
            .wait_event_source => {
                const state = self.uringlator.ops.getOnePtr(.state, id);
                var ctx = &self.uringlator.ops.getOnePtr(.win_state, id).event_source;
                state.wait_event_source.source.native.removeWaiter(&ctx.link);
            },
            .accept => {
                const state = self.uringlator.ops.getOnePtr(.state, id);
                if (state.accept.out_addr) |a| {
                    const win_state = self.uringlator.ops.getOnePtr(.win_state, id);
                    @memcpy(std.mem.asBytes(a), win_state.accept[@sizeOf(std.posix.sockaddr) + 16 .. @sizeOf(std.posix.sockaddr) * 2 + 16]);
                }
            },
            .read, .recv => {
                const out_read = self.uringlator.ops.getOne(.out_result, id).cast(*usize);
                out_read.* = ovl.res;
            },
            .write, .send => {
                const out_written = self.uringlator.ops.getOne(.out_result, id).cast(?*usize);
                if (out_written) |w| w.* = ovl.res;
            },
            else => {},
        }
    } else {
        switch (op_type) {
            .wait_event_source => {
                const state = self.uringlator.ops.getOnePtr(.state, id);
                var ctx = &self.uringlator.ops.getOnePtr(.win_state, id).event_source;
                state.wait_event_source.source.native.removeWaiter(&ctx.link);
            },
            .accept => {
                const out_socket = self.uringlator.ops.getOne(.out_result, id).cast(*std.posix.socket_t);
                if (out_socket.* != INVALID_SOCKET) checked(CloseHandle(out_socket.*));
            },
            else => {},
        }
    }
}

pub fn uringlator_notify(self: *@This(), comptime safety: Uringlator.Safety) void {
    switch (safety) {
        .thread_unsafe => self.signaled = true,
        .thread_safe => self.iocp.notify(.{ .type = .nop, .id = undefined }, null),
    }
}
