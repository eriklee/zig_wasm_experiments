const std = @import("std");
const vec3 = @import("vec3.zig");
const ray = @import("ray.zig");
const buffer = @import("buffer.zig");

pub fn ray_color(r: ray.Ray) vec3.Color {
    const unit_dir = r.dir.unit_vector();
    const t = 0.5 * (unit_dir.y + 1);
    return vec3.Color.init(1.0, 1.0, 1.0).scale(1 - t).plus(vec3.Color.init(0.5, 0.7, 1.0).scale(t));
}

pub fn do_render(buf: *buffer.Buffer) void {
    //image
    const aspect_ratio = @intToFloat(f64, buf.width) / @intToFloat(f64, buf.height);

    // camera
    const viewport_height = 2.0;
    const viewport_width = aspect_ratio * viewport_height;
    const focal_length = 1.0;

    const origin = vec3.Point3.init(0, 0, 0);
    const horizontal = vec3.Vec3.init(viewport_width, 0, 0);
    const vertical = vec3.Vec3.init(0, viewport_height, 0);

    const lower_left_corner = origin.minus(horizontal.div(2.0)).minus(vertical.div(2)).minus(vec3.Vec3.init(0, 0, focal_length));

    var j = buf.height - 1;
    while (j >= 0) {
        var i: usize = 0;
        while (i < buf.width) {
            const u = @intToFloat(f64, i) / @intToFloat(f64, buf.width - 1);
            const v = @intToFloat(f64, j) / @intToFloat(f64, buf.height - 1);
            const r = ray.Ray{ .orig = origin, .dir = lower_left_corner.plus(horizontal.scale(u)).plus(vertical.scale(v)).minus(origin) };
            const pixel_color = ray_color(r);
            buf.buf[@intCast(usize, j)][i] = buffer.RGBA.from_vec3(pixel_color);
            i += 1;
        }
        j -= 1;
    }
}

test "ray_color" {
    var r = ray.Ray{ .orig = vec3.Vec3.init(0, 0, 0), .dir = vec3.Vec3.init(0, -1, 0) };

    try std.testing.expectEqual(@as(f64, 1.0), ray_color(r).x);
    try std.testing.expectEqual(@as(f64, 1.0), ray_color(r).y);
    try std.testing.expectEqual(@as(f64, 1.0), ray_color(r).z);
}
