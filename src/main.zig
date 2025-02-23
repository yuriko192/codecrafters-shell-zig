const std = @import("std");

const Err = @import("errors/errors.zig").Errors;
const Builtins = @import("builtins/builtins.zig");
const Input = @import("input.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var argv: [][]u8 = try allocator.alloc([]u8, Input.GetArgVLen());
    defer allocator.free(argv);
    var argc: usize = 0;
    var raw_input: []u8 = try allocator.alloc(u8, Input.MAX_INPUT_LEN);
    defer allocator.free(raw_input);

    const stdout = std.io.getStdOut().writer();

    while (true) {
        try stdout.print("$ ", .{});

        Input.GetUserInput(allocator, &raw_input, &argv, &argc) catch |err| switch (err) {
            Err.INVALID => {
                std.debug.print("Invalid input!\n", .{});
                continue;
            },
            else => {
                std.debug.print("INPUT ERR: {}\n", .{err});
                return;
            },
        };

        const is_valid_builtin_command = Builtins.ExecuteBuiltInCommand(argv, argc) catch |err| switch (err) {
            Err.EXIT => return,
            else => continue,
        };

        if (is_valid_builtin_command) {
            continue;
        }

        try stdout.print("{s}: command not found\n", .{raw_input});
    }
}
