const std = @import("std");
const ops = @import("../ops.zig");
const Link = @import("minilib").Link;
const win32 = @import("win32");

const windows = std.os.windows;

const win_sock = windows.ws2_32;
const console = win32.system.console;
const threading = win32.system.threading;

const HANDLE = windows.HANDLE;
const INFINITE = windows.INFINITE;
const INVALID_HANDLE = windows.INVALID_HANDLE_VALUE;
const FILE_SKIP_COMPLETION_PORT_ON_SUCCESS = windows.FILE_SKIP_COMPLETION_PORT_ON_SUCCESS;

const GetLastError = windows.kernel32.GetLastError;

pub fn CloseHandle(hObject: HANDLE) bool {
    return win32.foundation.CloseHandle(hObject) != 0;
}

pub fn unexpectedError(err: windows.Win32Error) error{Unexpected} {
    return windows.unexpectedError(@enumFromInt(@intFromEnum(err)));
}

pub fn unexpectedWSAError(err: win_sock.WinsockError) error{Unexpected} {
    return windows.unexpectedWSAError(@enumFromInt(@intFromEnum(err)));
}

// Light wrapper, mainly to link EventSources to this
pub const Iocp = struct {
    pub const Key = packed struct(usize) {
        type: enum(u8) {
            nop,
            shutdown,
            event_source,
            child_exit,
            overlapped,
        },
        // The ID is only used for custom events, for CreateIoCompletionPort assocations its useless,
        // as it prevents from having multiple keys for a single handle:
        // > Use the CompletionKey parameter to help your application track which I/O operations have completed.
        // > This value is not used by CreateIoCompletionPort for functional control; rather, it is attached to
        // > the file handle specified in the FileHandle parameter at the time of association with an I/O completion port.
        // > This completion key should be unique for each file handle, and it accompanies the file handle throughout the
        // > internal completion queuing process.
        id: ops.Id,
        _: std.meta.Int(.unsigned, @bitSizeOf(usize) - @bitSizeOf(u8) - @bitSizeOf(ops.Id)) = undefined,
    };

    port: windows.HANDLE,
    num_threads: u32,

    pub fn init(num_threads: u32) !@This() {
        const port = windows.kernel32.CreateIoCompletionPort(INVALID_HANDLE, null, 0, num_threads).?;
        if (port == INVALID_HANDLE) {
            switch (GetLastError()) {
                .IO_PENDING, .HANDLE_EOF => {}, // not error
                else => |r| return unexpectedError(r),
            }
        }
        errdefer if (!CloseHandle(port)) unexpectedError(GetLastError()) catch unreachable;
        return .{ .port = port, .num_threads = num_threads };
    }

    pub fn notify(self: *@This(), key: Key, ptr: ?*anyopaque) void {
        // data for notification is put into the transferred bytes, overlapped can be anything
        if (windows.kernel32.PostQueuedCompletionStatus(self.port, 0, @bitCast(key), @ptrCast(@alignCast(ptr))) == 0) {
            switch (GetLastError()) {
                .IO_PENDING, .HANDLE_EOF => {},
                else => |r| unexpectedError(r) catch unreachable,
            }
        }
    }

    pub fn deinit(self: *@This()) void {
        // docs say that GetQueuedCompletionStatus should return if IOCP port is closed
        // this doesn't seem to happen under wine though (wine bug?)
        // anyhow, wakeup the drain thread by hand
        for (0..self.num_threads) |_| self.notify(.{ .type = .shutdown, .id = undefined }, null);
        if (!CloseHandle(self.port)) unexpectedError(GetLastError()) catch unreachable;
        self.* = undefined;
    }

    pub fn associateHandle(self: *@This(), _: ops.Id, handle: HANDLE) !void {
        const fs = win32.storage.file_system;
        const key: Key = .{ .type = .overlapped, .id = undefined };
        if (fs.SetFileCompletionNotificationModes(handle, FILE_SKIP_COMPLETION_PORT_ON_SUCCESS) == 0) {
            switch (GetLastError()) {
                .IO_PENDING, .HANDLE_EOF => {},
                else => |r| return unexpectedError(r),
            }
        }
        const res = windows.kernel32.CreateIoCompletionPort(handle, self.port, @bitCast(key), 0);
        if (res == null or res.? == INVALID_HANDLE) {
            // ignore 87 as it may mean that we just re-registered the handle
            if (GetLastError() == .INVALID_PARAMETER)
                return;
            return unexpectedError(GetLastError());
        }
    }

    pub fn associateSocket(self: *@This(), id: ops.Id, sock: std.posix.socket_t) !void {
        return self.associateHandle(id, @ptrCast(sock));
    }
};

pub const EventSource = struct {
    pub const OperationContext = struct {
        id: ops.Id,
        iocp: *Iocp,
        link: WaitList.Node = .{ .data = .{} },
    };

    pub const WaitList = std.SinglyLinkedList(Link(OperationContext, "link", .single));

    fd: HANDLE,
    counter: std.atomic.Value(u32) = std.atomic.Value(u32).init(0),
    waiters: WaitList = .{},
    mutex: std.Thread.Mutex = .{},

    pub fn init() !@This() {
        return .{ .fd = try (threading.CreateEventW(null, 1, 1, null) orelse error.SystemResources) };
    }

    pub fn deinit(self: *@This()) void {
        std.debug.assert(self.waiters.first == null); // having dangling waiters is bad
        if (!CloseHandle(self.fd)) unexpectedError(GetLastError()) catch unreachable;
        self.* = undefined;
    }

    pub fn notify(self: *@This()) void {
        if (self.counter.fetchAdd(1, .monotonic) == 0) {
            if (threading.SetEvent(self.fd) == 0) {
                switch (GetLastError()) {
                    .IO_PENDING, .HANDLE_EOF => {},
                    else => |r| unexpectedError(r) catch @panic("EventSource.notify failed"),
                }
            }
            self.mutex.lock();
            defer self.mutex.unlock();
            while (self.waiters.popFirst()) |w| w.data.cast().iocp.notify(.{ .type = .event_source, .id = w.data.cast().id }, self);
        }
    }

    pub fn waitNonBlocking(self: *@This()) error{WouldBlock}!void {
        while (self.counter.load(.acquire) == 0) {
            const WAIT_TIMEOUT = 0x00000102;
            const res = threading.WaitForSingleObject(self.fd, 0);
            if (res == WAIT_TIMEOUT) return error.WouldBlock;
            if (res != 0) {
                switch (GetLastError()) {
                    .IO_PENDING, .HANDLE_EOF => {},
                    else => |r| unexpectedError(r) catch @panic("EventSource.wait failed"),
                }
            }
        }
        if (self.counter.fetchSub(1, .release) == 1) {
            if (threading.ResetEvent(self.fd) == 0) {
                switch (GetLastError()) {
                    .IO_PENDING, .HANDLE_EOF => {},
                    else => |r| unexpectedError(r) catch @panic("EventSource.wait failed"),
                }
            }
        }
    }

    pub fn wait(self: *@This()) void {
        while (self.counter.load(.acquire) == 0) {
            if (threading.WaitForSingleObject(self.fd, INFINITE) != 0) {
                switch (GetLastError()) {
                    .IO_PENDING, .HANDLE_EOF => {},
                    else => |r| unexpectedError(r) catch @panic("EventSource.wait failed"),
                }
            }
        }
        if (self.counter.fetchSub(1, .release) == 1) {
            if (threading.ResetEvent(self.fd) == 0) {
                switch (GetLastError()) {
                    .IO_PENDING, .HANDLE_EOF => {},
                    else => |r| unexpectedError(r) catch @panic("EventSource.wait failed"),
                }
            }
        }
    }

    pub fn addWaiter(self: *@This(), node: *WaitList.Node) void {
        if (self.counter.load(.acquire) > 0) {
            node.data.cast().iocp.notify(.{ .type = .event_source, .id = node.data.cast().id }, self);
            return;
        }
        self.mutex.lock();
        defer self.mutex.unlock();
        self.waiters.prepend(node);
    }

    pub fn removeWaiter(self: *@This(), node: *WaitList.Node) void {
        blk: {
            self.mutex.lock();
            defer self.mutex.unlock();
            // safer list.remove ...
            if (self.waiters.first == node) {
                self.waiters.first = node.next;
            } else if (self.waiters.first) |first| {
                var current_elm = first;
                while (current_elm.next != node) {
                    if (current_elm.next == null) break :blk;
                    current_elm = current_elm.next.?;
                }
                current_elm.next = node.next;
            }
        }
        node.* = .{ .data = .{} };
    }
};

pub fn translateTty(_: std.posix.fd_t, _: []u8, _: *ops.ReadTty.TranslationState) ops.ReadTty.Error!usize {
    if (true) @panic("TODO");
    return 0;
}

pub fn readTty(fd: std.posix.fd_t, buf: []u8, mode: ops.ReadTty.Mode) ops.ReadTty.Error!usize {
    return switch (mode) {
        .direct => {
            if (buf.len < @sizeOf(console.INPUT_RECORD)) {
                return error.NoSpaceLeft;
            }
            var read: u32 = 0;
            const n_fits: u32 = @intCast(buf.len / @sizeOf(console.INPUT_RECORD));
            if (console.ReadConsoleInputW(fd, @ptrCast(@alignCast(buf.ptr)), n_fits, &read) == 0) {
                return unexpectedError(windows.GetLastError());
            }
            return read * @sizeOf(console.INPUT_RECORD);
        },
        .translation => |state| translateTty(fd, buf, state),
    };
}

pub const PendingOrTransmitted = union(enum) {
    transmitted: usize,
    pending: void,
};

pub fn sendEx(sockfd: std.posix.socket_t, buf: [*]win_sock.WSABUF, flags: u32, overlapped: ?*windows.OVERLAPPED) !PendingOrTransmitted {
    var written: u32 = 0;
    while (true) {
        const rc = win_sock.WSASend(sockfd, buf, 1, &written, flags, overlapped, null);
        if (rc == win_sock.SOCKET_ERROR) {
            switch (win_sock.WSAGetLastError()) {
                .WSAEWOULDBLOCK, .WSAEINTR, .WSAEINPROGRESS => continue,
                .WSA_IO_PENDING => if (overlapped != null) return .pending else unreachable,
                .WSAEACCES => return error.AccessDenied,
                .WSAEADDRNOTAVAIL => return error.AddressNotAvailable,
                .WSAECONNRESET => return error.ConnectionResetByPeer,
                .WSAEMSGSIZE => return error.MessageTooBig,
                .WSAENOBUFS => return error.SystemResources,
                .WSAENOTSOCK => return error.FileDescriptorNotASocket,
                .WSAEAFNOSUPPORT => return error.AddressFamilyNotSupported,
                .WSAEDESTADDRREQ => unreachable, // A destination address is required.
                .WSAEFAULT => unreachable, // The lpBuffers, lpTo, lpOverlapped, lpNumberOfBytesSent, or lpCompletionRoutine parameters are not part of the user address space, or the lpTo parameter is too small.
                .WSAEHOSTUNREACH => return error.NetworkUnreachable,
                .WSAEINVAL => unreachable,
                .WSAENETDOWN => return error.NetworkSubsystemFailed,
                .WSAENETRESET => return error.ConnectionResetByPeer,
                .WSAENETUNREACH => return error.NetworkUnreachable,
                .WSAENOTCONN => return error.SocketNotConnected,
                .WSAESHUTDOWN => unreachable, // The socket has been shut down; it is not possible to WSASendTo on a socket after shutdown has been invoked with how set to SD_SEND or SD_BOTH.
                .WSANOTINITIALISED => unreachable, // A successful WSAStartup call must occur before using this function.
                else => |err| return unexpectedWSAError(err),
            }
        }
        break;
    }
    return .{ .transmitted = @intCast(written) };
}

pub fn recvEx(sockfd: std.posix.socket_t, buf: [*]win_sock.WSABUF, flags: u32, overlapped: ?*windows.OVERLAPPED) !PendingOrTransmitted {
    var read: u32 = 0;
    var inout_flags: u32 = flags;
    while (true) {
        const rc = win_sock.WSARecv(sockfd, buf, 1, &read, &inout_flags, overlapped, null);
        if (rc == win_sock.SOCKET_ERROR) {
            switch (win_sock.WSAGetLastError()) {
                .WSAEWOULDBLOCK, .WSAEINTR, .WSAEINPROGRESS => continue,
                .WSA_IO_PENDING => if (overlapped != null) return .pending else unreachable,
                .WSAEACCES => return error.AccessDenied,
                .WSAEADDRNOTAVAIL => return error.AddressNotAvailable,
                .WSAECONNRESET => return error.ConnectionResetByPeer,
                .WSAEMSGSIZE => return error.MessageTooBig,
                .WSAENOBUFS => return error.SystemResources,
                .WSAENOTSOCK => return error.FileDescriptorNotASocket,
                .WSAEAFNOSUPPORT => return error.AddressFamilyNotSupported,
                .WSAEDESTADDRREQ => unreachable, // A destination address is required.
                .WSAEFAULT => unreachable, // The lpBuffers, lpTo, lpOverlapped, lpNumberOfBytesSent, or lpCompletionRoutine parameters are not part of the user address space, or the lpTo parameter is too small.
                .WSAEHOSTUNREACH => return error.NetworkUnreachable,
                .WSAEINVAL => unreachable,
                .WSAENETDOWN => return error.NetworkSubsystemFailed,
                .WSAENETRESET => return error.ConnectionResetByPeer,
                .WSAENETUNREACH => return error.NetworkUnreachable,
                .WSAENOTCONN => return error.SocketNotConnected,
                .WSAESHUTDOWN => unreachable, // The socket has been shut down; it is not possible to WSASendTo on a socket after shutdown has been invoked with how set to SD_SEND or SD_BOTH.
                .WSANOTINITIALISED => unreachable, // A successful WSAStartup call must occur before using this function.
                else => |err| return unexpectedWSAError(err),
            }
        }
        break;
    }
    return .{ .transmitted = @intCast(read) };
}

pub const msghdr = win_sock.msghdr;
pub const msghdr_const = win_sock.msghdr_const;

pub fn sendmsgEx(sockfd: std.posix.socket_t, msg: *const msghdr_const, flags: u32, overlapped: ?*windows.OVERLAPPED) !PendingOrTransmitted {
    var written: u32 = 0;
    while (true) {
        const rc = win_sock.WSASendMsg(sockfd, @constCast(msg), flags, &written, overlapped, null);
        if (rc == win_sock.SOCKET_ERROR) {
            switch (win_sock.WSAGetLastError()) {
                .WSAEWOULDBLOCK, .WSAEINTR, .WSAEINPROGRESS => continue,
                .WSA_IO_PENDING => if (overlapped != null) return .pending else unreachable,
                .WSAEACCES => return error.AccessDenied,
                .WSAEADDRNOTAVAIL => return error.AddressNotAvailable,
                .WSAECONNRESET => return error.ConnectionResetByPeer,
                .WSAEMSGSIZE => return error.MessageTooBig,
                .WSAENOBUFS => return error.SystemResources,
                .WSAENOTSOCK => return error.FileDescriptorNotASocket,
                .WSAEAFNOSUPPORT => return error.AddressFamilyNotSupported,
                .WSAEDESTADDRREQ => unreachable, // A destination address is required.
                .WSAEFAULT => unreachable, // The lpBuffers, lpTo, lpOverlapped, lpNumberOfBytesSent, or lpCompletionRoutine parameters are not part of the user address space, or the lpTo parameter is too small.
                .WSAEHOSTUNREACH => return error.NetworkUnreachable,
                .WSAEINVAL => unreachable,
                .WSAENETDOWN => return error.NetworkSubsystemFailed,
                .WSAENETRESET => return error.ConnectionResetByPeer,
                .WSAENETUNREACH => return error.NetworkUnreachable,
                .WSAENOTCONN => return error.SocketNotConnected,
                .WSAESHUTDOWN => unreachable, // The socket has been shut down; it is not possible to WSASendTo on a socket after shutdown has been invoked with how set to SD_SEND or SD_BOTH.
                .WSANOTINITIALISED => unreachable, // A successful WSAStartup call must occur before using this function.
                else => |err| return unexpectedWSAError(err),
            }
        }
        break;
    }
    return .{ .transmitted = @intCast(written) };
}

pub fn sendmsg(sockfd: std.posix.socket_t, msg: *const msghdr_const, flags: u32) !usize {
    return sendmsgEx(sockfd, msg, flags, null);
}

pub fn recvmsgEx(sockfd: std.posix.socket_t, msg: *msghdr, _: u32, overlapped: ?*windows.OVERLAPPED) !PendingOrTransmitted {
    const DumbStuff = struct {
        var once = std.once(do_once);
        var fun: win_sock.LPFN_WSARECVMSG = undefined;
        var have_fun = false;
        fn do_once() void {
            const sock = std.posix.socket(std.posix.AF.INET, std.posix.SOCK.DGRAM, 0) catch unreachable;
            defer std.posix.close(sock);
            var trash: u32 = 0;
            const res = win_sock.WSAIoctl(
                sock,
                win_sock.SIO_GET_EXTENSION_FUNCTION_POINTER,
                // not in zigwin32
                @ptrCast(&win_sock.WSAID_WSARECVMSG),
                @sizeOf(windows.GUID),
                @ptrCast(&fun),
                @sizeOf(win_sock.LPFN_WSARECVMSG),
                &trash,
                null,
                null,
            );
            have_fun = res != win_sock.SOCKET_ERROR;
        }
    };
    DumbStuff.once.call();
    if (!DumbStuff.have_fun) return error.Unexpected;
    var read: u32 = 0;
    while (true) {
        const rc = DumbStuff.fun(sockfd, msg, &read, overlapped, null);
        if (rc == win_sock.SOCKET_ERROR) {
            switch (win_sock.WSAGetLastError()) {
                .WSAEWOULDBLOCK, .WSAEINTR, .WSAEINPROGRESS => continue,
                .WSA_IO_PENDING => if (overlapped != null) return .pending else unreachable,
                .WSAEACCES => return error.AccessDenied,
                .WSAEADDRNOTAVAIL => return error.AddressNotAvailable,
                .WSAECONNRESET => return error.ConnectionResetByPeer,
                .WSAEMSGSIZE => return error.MessageTooBig,
                .WSAENOBUFS => return error.SystemResources,
                .WSAENOTSOCK => return error.FileDescriptorNotASocket,
                .WSAEAFNOSUPPORT => return error.AddressFamilyNotSupported,
                .WSAEDESTADDRREQ => unreachable, // A destination address is required.
                .WSAEFAULT => unreachable, // The lpBuffers, lpTo, lpOverlapped, lpNumberOfBytesSent, or lpCompletionRoutine parameters are not part of the user address space, or the lpTo parameter is too small.
                .WSAEHOSTUNREACH => return error.NetworkUnreachable,
                .WSAEINVAL => unreachable,
                .WSAENETDOWN => return error.NetworkSubsystemFailed,
                .WSAENETRESET => return error.ConnectionResetByPeer,
                .WSAENETUNREACH => return error.NetworkUnreachable,
                .WSAENOTCONN => return error.SocketNotConnected,
                .WSAESHUTDOWN => unreachable, // The socket has been shut down; it is not possible to WSASendTo on a socket after shutdown has been invoked with how set to SD_SEND or SD_BOTH.
                .WSANOTINITIALISED => unreachable, // A successful WSAStartup call must occur before using this function.
                else => |err| return unexpectedWSAError(err),
            }
        }
        break;
    }
    return .{ .transmitted = @intCast(read) };
}

pub fn recvmsg(sockfd: std.posix.socket_t, msg: *msghdr, flags: u32) !usize {
    return recvmsgEx(sockfd, msg, flags, null);
}

pub fn socket(domain: u32, socket_type: u32, protocol: u32) std.posix.SocketError!std.posix.socket_t {
    // NOTE: windows translates the SOCK.NONBLOCK/SOCK.CLOEXEC flags into
    // windows-analagous operations
    const filtered_sock_type = socket_type & ~@as(u32, std.posix.SOCK.NONBLOCK | std.posix.SOCK.CLOEXEC);
    const flags: u32 = if ((socket_type & std.posix.SOCK.CLOEXEC) != 0)
        win_sock.WSA_FLAG_NO_HANDLE_INHERIT
    else
        0;
    const rc = try windows.WSASocketW(
        @bitCast(domain),
        @bitCast(filtered_sock_type),
        @bitCast(protocol),
        null,
        0,
        flags | win_sock.WSA_FLAG_OVERLAPPED,
    );
    errdefer windows.closesocket(rc) catch unreachable;
    if ((socket_type & std.posix.SOCK.NONBLOCK) != 0) {
        var mode: c_ulong = 1; // nonblocking
        if (win_sock.SOCKET_ERROR == win_sock.ioctlsocket(rc, win_sock.FIONBIO, &mode)) {
            switch (win_sock.WSAGetLastError()) {
                // have not identified any error codes that should be handled yet
                else => unreachable,
            }
        }
    }
    return rc;
}
