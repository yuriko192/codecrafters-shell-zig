const std = @import("std");

const EXIT_COMMAND: *const [4]u8 = "exit";
const ECHO_COMMAND: *const [4]u8 = "echo";
const TYPE_COMMAND: *const [4]u8 = "type";

const EXIT_COMMAND_LEN = EXIT_COMMAND.len;
const ECHO_COMMAND_LEN = ECHO_COMMAND.len;
const TYPE_COMMAND_LEN = TYPE_COMMAND.len;

const BUILTIN_COMMAND_LIST = [_]*const [4]u8{ EXIT_COMMAND, ECHO_COMMAND, TYPE_COMMAND };

const errors = error{ NULL, INVALID };

pub fn checkType(argv: [][]u8, argc: usize) !void {
    const stdout = std.io.getStdOut().writer();

    if (argc < 2) {
        return errors.INVALID;
    }

    const command = argv[1];

    for (BUILTIN_COMMAND_LIST) |builtin_command| {
        if (std.mem.eql(u8, command, builtin_command)) {
            try stdout.print("{s} is a shell builtin\n", .{command});
            return;
        }
    }

    try stdout.print("{s}: not found\n", .{command});
}

pub fn executeEcho(argv: [][]u8, argc: usize) !void {
    _ = argc;
    const stdout = std.io.getStdOut().writer();

    for (argv) |argI| {
        try stdout.print("{s} ", .{argI});
    }
    try stdout.print("\n", .{});
}

const MAX_INPUT_LEN = 1024;
const MAX_ARGC = 100;
var argv_len: u8 = 10;
pub fn getUserInput(allocator: std.mem.Allocator, raw_input: *[]u8, argv: *[][]u8, argc: *usize) !void {
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
        return errors.INVALID;
    }
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var argv: [][]u8 = try allocator.alloc([]u8, argv_len);
    defer allocator.free(argv);
    var argc: usize = 0;
    var raw_input: []u8 = try allocator.alloc(u8, MAX_INPUT_LEN);
    defer allocator.free(raw_input);

    const stdout = std.io.getStdOut().writer();

    while (true) {
        try stdout.print("$ ", .{});

        getUserInput(allocator, &raw_input, &argv, &argc) catch |err| switch (err) {
            errors.INVALID => {
                std.debug.print("Invalid input!\n", .{});
                continue;
            },
            else => {
                std.debug.print("INPUT ERR: {}\n", .{err});
                return;
            },
        };

        const c = argv[0];
        if (std.mem.eql(u8, c, EXIT_COMMAND)) {
            return;
        }

        if (std.mem.eql(u8, c, ECHO_COMMAND)) {
            try executeEcho(argv, argc);
            continue;
        }

        if (std.mem.eql(u8, c, TYPE_COMMAND)) {
            checkType(argv, argc) catch |err| {
                std.debug.print("command {s} ERROR: {}\n", .{ TYPE_COMMAND, err });
                try stdout.print("{s}: command not found\n", .{raw_input});
            };
            continue;
        }

        try stdout.print("{s}: command not found\n", .{raw_input});
    }
}
