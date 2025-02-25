const std = @import("std");
const builtin = @import("builtin");
const Err = @import("../errors/errors.zig").Errors;
const DebugPrint = @import("../errors/errors.zig").DebugPrint;

const PathDelimiter: u8 = if (builtin.target.os.tag == .windows) ';' else ':';
fn IsExecutableFile(file: std.fs.File) !bool {
    if (comptime builtin.target.os.tag == .windows) {
        return true;
    }

    const mode = try file.mode();

    const is_executable = mode & 0b001 != 0;
    if (!is_executable) {
        return false;
    }

    return true;
}

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

        const file = std.fs.openFileAbsolute(full_command_path, .{ .mode = .read_only }) catch |err| switch (err) {
            std.fs.File.OpenError.BadPathName => continue,
            std.fs.File.OpenError.FileNotFound => continue,
            else => {
                DebugPrint("GetExternalExecutableFullPath: std.fs.openFileAbsolute: full_command_path: {s}, ERR: {}\n", .{ full_command_path, err });
                continue;
            },
        };
        defer file.close();

        const isExecutable = IsExecutableFile(file) catch |err| {
            DebugPrint("GetExternalExecutableFullPath: IsExecutableFile: full_command_path: {s}, ERR: {}\n", .{ full_command_path, err });
            continue;
        };
        if (!isExecutable) {
            continue;
        }

        return try allocator.dupe(u8, full_command_path);
    }

    return "";
}

pub fn ExecuteExternalCommand(allocator: std.mem.Allocator, argv: [][]u8, argc: usize) bool {
    const ExecutablePath = GetExternalExecutableFullPath(allocator, argv[0]) catch |err| {
        DebugPrint("ExecuteExternalCommand: GetExternalExecutableFullPath: ERR: {}, command: {s}\n", .{ err, argv[0] });
        return false;
    };

    if (std.mem.eql(u8, ExecutablePath, "")) {
        return false;
    }

    argv[0] = allocator.dupe(u8, ExecutablePath) catch |err| {
        DebugPrint("ExecuteExternalCommand: allocator.dupe: ERR: {}, ExecutablePath: {s}\n", .{ err, ExecutablePath });
        return false;
    };

    var child = std.process.Child.init(argv[0..argc], allocator);
    _ = child.spawnAndWait() catch |err| {
        DebugPrint("ExecuteExternalCommand: child.spawnAndWait: ERR: {}, processName: {s}\n", .{ err, argv[0] });
        return false;
    };

    return true;
}
