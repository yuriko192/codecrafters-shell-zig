const std = @import("std");

const Err = @import("errors/errors.zig").Errors;

pub const MAX_INPUT_LEN = 1024;
pub const MAX_ARGC = 100;
var argv_len: u8 = 10;

pub fn GetArgVLen() u8 {
    return argv_len;
}

pub fn GetUserInput(allocator: std.mem.Allocator, raw_input: *[]u8, argv: *[][]u8, argc: *usize) !void {
    argc.* = 0;
    const stdin = std.io.getStdIn().reader();
    raw_input.* = try stdin.readUntilDelimiterAlloc(allocator, '\n', MAX_INPUT_LEN);

    var iter = std.mem.splitScalar(u8, raw_input.*, ' ');
    while (iter.next()) |command| {
        argv.*[argc.*] = try allocator.dupe(u8, command);
        argc.* += 1;

        if (argc.* >= argv_len) {
            if (argv_len > MAX_ARGC) {
                break;
            }
            argv_len = argv_len + 10;
            argv.* = try allocator.realloc(argv.*, argv_len);
        }
    }

    if (argc.* == 0) {
        return Err.INVALID;
    }
}
