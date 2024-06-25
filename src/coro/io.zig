const std = @import("std");
const aio = @import("aio");
const Scheduler = @import("Scheduler.zig");
const Frame = @import("Frame.zig");
const common = @import("common.zig");

pub const Error = aio.Error || error{Canceled};

pub fn do(operations: anytype, status: Frame.Status) Error!u16 {
    std.debug.assert(status == .io or status == .io_cancel);
    if (Frame.current()) |frame| {
        if (frame.canceled) return error.Canceled;

        var work = struct { ops: @TypeOf(operations) }{ .ops = operations };
        var whole: common.WholeContext = .{ .num_operations = operations.len, .frame = frame };
        var ctx_list: [operations.len]common.OperationContext = undefined;

        inline for (&work.ops, &ctx_list) |*op, *ctx| {
            ctx.* = .{ .whole = &whole };
            op.userdata = @intFromPtr(ctx);
        }

        try frame.scheduler.io.queue(work.ops);
        // wait until scheduler actually submits our work
        const ack = frame.scheduler.io_ack;
        while (ack == frame.scheduler.io_ack) {
            Frame.yield(status);
        }

        // check if this was a cancel
        if (whole.num_operations > 0) {
            std.debug.assert(status != .io_cancel);

            var num_cancels: u16 = 0;
            inline for (&ctx_list) |*ctx| {
                if (!ctx.completed and ctx.id != null) {
                    // reuse the same ctx, we don't care about completation status anymore
                    try frame.scheduler.io.queue(aio.Cancel{ .id = ctx.id.?, .userdata = @intFromPtr(ctx) });
                    num_cancels += 1;
                }
            }

            std.debug.assert(num_cancels > 0);
            whole.num_operations += num_cancels;
            Frame.yield(.io_cancel);

            if (whole.num_errors == 0) {
                return error.Canceled;
            }
        }

        return whole.num_errors;
    } else {
        return aio.complete(operations);
    }
}