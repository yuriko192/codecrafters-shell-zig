const std = @import("std");
const builtin = @import("builtin");
const Err = @import("../errors/errors.zig").Errors;
const DebugPrint = @import("../errors/errors.zig").DebugPrint;

const PathDelimiter: u8 = if (builtin.target.os.tag == .windows) ';' else ':';

pub fn GetExternalExecutableFullPath(allocator: std.mem.Allocator, command: []u8) ![]u8 {
    const env_map = try allocator.create(std.process.EnvMap);
    env_map.* = try std.process.getEnvMap(allocator);
    defer env_map.deinit();

    const env_path = env_map.get("PATH") orelse "";
    var iter = std.mem.splitScalar(u8, env_path, PathDelimiter);
    while (iter.next()) |env_dir| {
        const full_command_path = std.fs.path.join(allocator, &[_][]const u8{ env_dir, command }) catch |err| {
            DebugPrint("GetExternalExecutableFullPath: std.fs.path.join: ERR: {}, env_dir: {s}, command: {s}", .{ err, env_dir, command });
            continue;
        };
        defer allocator.free(full_command_path);

        const file = std.fs.openFileAbsolute(full_command_path, .{}) catch |err| switch (err) {
            std.fs.File.OpenError.BadPathName => continue,
            std.fs.File.OpenError.FileNotFound => continue,
            else => {
                DebugPrint("GetExternalExecutableFullPath: std.fs.openFileAbsolute: ERR: {}, full_command_path: {s}", .{ err, full_command_path });
                continue;
            },
        };
        defer file.close();

        const mode = file.mode() catch |err| {
            DebugPrint("GetExternalExecutableFullPath: file.mode: ERR: {}, full_command_path: {s}", .{ err, full_command_path });
            continue;
        };

        const is_executable = mode & 0b001 != 0;
        if (!is_executable) {
            continue;
        }

        return try allocator.dupe(u8, full_command_path);
    }

    return "";
}
