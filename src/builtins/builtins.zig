const std = @import("std");
const Err = @import("../errors/errors.zig").Errors;
const Utils = @import("../utils/utils.zig");
const DebugPrint = @import("../errors/errors.zig").DebugPrint;

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
    errdefer {
        stdout.print("{s}: not found\n", .{command}) catch {};
    }

    for (BUILTIN_COMMAND_LIST) |builtin_command| {
        if (std.mem.eql(u8, command, builtin_command)) {
            try stdout.print("{s} is a shell builtin\n", .{command});
            return;
        }
    }
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    const full_command_path = Utils.GetExternalExecutableFullPath(allocator, command) catch |err| {
        DebugPrint("ExecuteTypeCommand: Utils.GetExternalExecutableFullPath: ERR: {}, command: {s}\n", .{ err, command });
        return err;
    };
    defer allocator.free(full_command_path);

    if (!std.mem.eql(u8, full_command_path, "")) {
        try stdout.print("{s} is {s}\n", .{ command, full_command_path });
        return;
    }

    return Err.INVALID;
}

pub fn ExecuteEchoCommand(argv: [][]u8, argc: usize) !void {
    const stdout = std.io.getStdOut().writer();

    for (argv[1..argc]) |argI| {
        try stdout.print("{s} ", .{argI});
    }
    try stdout.print("\n", .{});
}

pub fn ExecuteBuiltInCommand(argv: [][]u8, argc: usize) !bool {
    const c = argv[0];
    // try std.io.getStdOut().writer().print("C: {s}\n", .{c});
    if (std.mem.eql(u8, c, EXIT_COMMAND)) {
        return Err.EXIT;
    }

    if (std.mem.eql(u8, c, ECHO_COMMAND)) {
        try ExecuteEchoCommand(argv, argc);
        return true;
    }

    if (std.mem.eql(u8, c, TYPE_COMMAND)) {
        ExecuteTypeCommand(argv, argc) catch |err| {
            DebugPrint("ExecuteBuiltInCommand: ExecuteTypeCommand: ERR: {}\n", .{err});
            switch (err) {
                Err.INVALID => return true,
                Err.EMPTY => return true,
                else => return false,
            }
        };
        return true;
    }

    return false;
}
