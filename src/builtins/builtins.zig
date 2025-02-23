const std = @import("std");
const Err = @import("../errors/errors.zig").Errors;

pub const EXIT_COMMAND: *const [4]u8 = "exit";
pub const ECHO_COMMAND: *const [4]u8 = "echo";
pub const TYPE_COMMAND: *const [4]u8 = "type";

pub const EXIT_COMMAND_LEN = EXIT_COMMAND.len;
pub const ECHO_COMMAND_LEN = ECHO_COMMAND.len;
pub const TYPE_COMMAND_LEN = TYPE_COMMAND.len;

pub const BUILTIN_COMMAND_LIST = [_]*const [4]u8{ EXIT_COMMAND, ECHO_COMMAND, TYPE_COMMAND };

pub fn ExecuteTypeCommand(argv: [][]u8, argc: usize) !void {
    const stdout = std.io.getStdOut().writer();

    if (argc < 2) {
        try stdout.print("Type Error: No command name\n", .{});
        return Err.EMPTY;
    }

    const command = argv[1];

    for (BUILTIN_COMMAND_LIST) |builtin_command| {
        if (std.mem.eql(u8, command, builtin_command)) {
            try stdout.print("{s} is a shell builtin\n", .{command});
            return;
        }
    }

    try stdout.print("{s}: not found\n", .{command});
    return Err.INVALID;
}

pub fn ExecuteEchoCommand(argv: [][]u8, argc: usize) !void {
    _ = argc;
    const stdout = std.io.getStdOut().writer();

    for (argv) |argI| {
        try stdout.print("{s} ", .{argI});
    }
    try stdout.print("\n", .{});
}

pub fn ExecuteBuiltInCommand(argv: [][]u8, argc: usize) !bool {
    const c = argv[0];
    if (std.mem.eql(u8, c, EXIT_COMMAND)) {
        return Err.EXIT;
    }

    if (std.mem.eql(u8, c, ECHO_COMMAND)) {
        try ExecuteEchoCommand(argv, argc);
        return true;
    }

    if (std.mem.eql(u8, c, TYPE_COMMAND)) {
        ExecuteTypeCommand(argv, argc) catch |err| {
            switch (err) {
                Err.INVALID => {
                    std.debug.print("command {s} Invalid\n", .{TYPE_COMMAND});
                    return true;
                },
                Err.EMPTY => {
                    std.debug.print("command {s} Empty\n", .{TYPE_COMMAND});
                    return true;
                },
                else => {
                    std.debug.print("command {s} ERROR: {}\n", .{ TYPE_COMMAND, err });
                    return false;
                },
            }
        };
        return true;
    }

    return false;
}
