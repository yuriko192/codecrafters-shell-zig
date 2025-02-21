const std = @import("std");

const EXIT_COMMAND: *const [4]u8 = "exit";
const ECHO_COMMAND: *const [4]u8 = "echo";
const TYPE_COMMAND: *const [4]u8 = "type";

const EXIT_COMMAND_LEN = EXIT_COMMAND.len;
const ECHO_COMMAND_LEN = ECHO_COMMAND.len;
const TYPE_COMMAND_LEN = TYPE_COMMAND.len;

const BUILTIN_COMMAND_LIST = [_]*const [4]u8{ EXIT_COMMAND, ECHO_COMMAND, TYPE_COMMAND };

const errors = error{ NULL, INVALID };

pub fn check_type(raw_command: ?[]const u8) !void {
    const stdout = std.io.getStdOut().writer();

    if (raw_command == null) {
        return errors.NULL;
    }

    const command = raw_command orelse unreachable;

    for (BUILTIN_COMMAND_LIST) |builtin_command| {
        if (std.mem.eql(u8, command, builtin_command)) {
            try stdout.print("{s} is a shell builtin\n", .{command});
            return;
        }
    }

    try stdout.print("{s}: not found\n", .{command});
}

pub fn main() !void {
    var buffer: [1024]u8 = undefined;

    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();

    while (true) {
        try stdout.print("$ ", .{});

        const user_input = try stdin.readUntilDelimiter(&buffer, '\n');
        var iter = std.mem.splitScalar(u8, user_input, ' ');
        const command = iter.next();

        if (command) |c| {
            if (std.mem.eql(u8, c, EXIT_COMMAND)) {
                return;
            }

            if (std.mem.eql(u8, c, ECHO_COMMAND)) {
                while (iter.next()) |arg| {
                    try stdout.print("{s} ", .{arg});
                }
                try stdout.print("\n", .{});
                continue;
            }

            if (std.mem.eql(u8, c, TYPE_COMMAND)) {
                try check_type(iter.next());
                continue;
            }
        }

        try stdout.print("{s}: command not found\n", .{user_input});
    }
}
