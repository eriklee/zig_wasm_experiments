const std = @import("std");
const rt_main = @import("rt_main.zig");
const buffer = @import("buffer.zig");

pub fn to_ppm(filename: []const u8, buf: buffer.Buffer) !void {
    const file = try std.fs.cwd().createFile(
        filename,
        .{ .truncate = true },
    );
    defer file.close();

    try file.writer().print("P3\n {} {}\n255\n", .{ buf.width, buf.height });

    var j = buf.height - 1;
    while (j >= 0) {
        var i: usize = 0;
        while (i < buf.width) {
            const color = buf.buf[@intCast(usize, j)][i];
            try file.writer().print("{} {} {}\n", .{ color.r, color.g, color.b });
            i += 1;
        }
        j -= 1;
    }
}

pub fn main() anyerror!void {
    std.log.info("All your codebase are belong to us.", .{});

    const screen_height = buffer.screen_height;
    const screen_width = buffer.screen_width;

    var screen_buffer = buffer.Buffer{ .buf = std.mem.zeroes([screen_height][screen_width]buffer.RGBA), .height = screen_height, .width = screen_width };

    // this renders upside down in the wasm version, but right side up here, so...
    rt_main.do_render(&screen_buffer);
    try to_ppm("out.ppm", screen_buffer);
}
