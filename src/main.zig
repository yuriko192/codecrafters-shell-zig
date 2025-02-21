const std = @import("std");

const EXIT_COMMAND = "exit";
const EXIT_COMMAND_LEN = EXIT_COMMAND.len;

pub fn main() !void {
    // Uncomment this block to pass the first stage
    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();
    var buffer: [1024]u8 = undefined;

    while (true) {
        try stdout.print("$ ", .{});

        const user_input = try stdin.readUntilDelimiter(&buffer, '\n');
        var iter = std.mem.splitScalar(u8, user_input, ' ');
        const command = iter.next();

        if (command)|c| {
            if (std.mem.eql(u8,c, EXIT_COMMAND)) {
                return;
            }
        }

        try stdout.print("{s}: command not found\n", .{user_input});
    }
}
