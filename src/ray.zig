const vec3 = @import("vec3.zig");

pub const Ray = struct {
    orig: vec3.Point3,
    dir: vec3.Vec3,

    pub fn at(self: Ray, t: f64) vec3.Point3 {
        return self.orig.plus(self.dir.scale(t));
    }
};

const expectEqual = @import("std").testing.expectEqual;
test "ray::at" {
    const r = Ray{ .orig = vec3.Vec3.init(0, 1, 2), .dir = vec3.Vec3.init(3, 2, 1) };

    const p1 = r.at(1);
    try expectEqual(@as(f64, 3.0), p1.x);
    try expectEqual(@as(f64, 3.0), p1.y);
    try expectEqual(@as(f64, 3.0), p1.z);

    const p2 = r.at(2);
    try expectEqual(@as(f64, 6.0), p2.x);
    try expectEqual(@as(f64, 5.0), p2.y);
    try expectEqual(@as(f64, 4.0), p2.z);
}
