const std = @import("std");
const builtin = @import("builtin");

pub const Errors = error{ EMPTY, NULL, INVALID, EXIT };

pub fn DebugPrint(
    comptime format: []const u8,
    args: anytype,
) void {
    if (comptime builtin.target.os.tag == .windows) {
        std.debug.print(format, args);
    } else {
        return;
    }
}
