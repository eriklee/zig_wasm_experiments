const std = @import("std");

pub const Vec3 = struct {
    x: f64,
    y: f64,
    z: f64,

    pub fn init(x: f64, y: f64, z: f64) Vec3 {
        return Vec3{ .x = x, .y = y, .z = z };
    }

    pub fn neg(self: Vec3) Vec3 {
        return Vec3{ .x = -self.x, .y = -self.y, .z = -self.z };
    }

    pub fn plus_eq(self: *Vec3, rhs: Vec3) void {
        self.x += rhs.x;
        self.y += rhs.y;
        self.z += rhs.z;
    }

    pub fn scale_inplace(self: *Vec3, factor: f64) void {
        self.x *= factor;
        self.y *= factor;
        self.z *= factor;
    }

    pub fn length(self: Vec3) f64 {
        return std.math.sqrt(self.length_squared());
    }
    pub fn length_squared(self: Vec3) f64 {
        return self.x * self.x + self.y * self.y + self.z * self.z;
    }

    pub fn plus(lhs: Vec3, rhs: Vec3) Vec3 {
        return Vec3{ .x = lhs.x + rhs.x, .y = lhs.y + rhs.y, .z = lhs.z + rhs.z };
    }
    pub fn minus(lhs: Vec3, rhs: Vec3) Vec3 {
        return Vec3{ .x = lhs.x - rhs.x, .y = lhs.y - rhs.y, .z = lhs.z - rhs.z };
    }
    pub fn times(lhs: Vec3, rhs: Vec3) Vec3 {
        return Vec3{ .x = lhs.x * rhs.x, .y = lhs.y * rhs.y, .z = lhs.z * rhs.z };
    }
    pub fn scale(lhs: Vec3, factor: f64) Vec3 {
        return Vec3{ .x = lhs.x * factor, .y = lhs.y * factor, .z = lhs.z * factor };
    }
    pub fn div(lhs: Vec3, factor: f64) Vec3 {
        return lhs.scale(1 / factor);
    }
    pub fn dot(u: Vec3, v: Vec3) f64 {
        return u.x * v.x + u.y * v.y + u.z * v.z;
    }
    pub fn cross(u: Vec3, v: Vec3) Vec3 {
        return Vec3{ .x = u.y * v.z - u.z * v.y, .y = u.z * v.x - u.x * v.z, .z = u.x * v.y - u.y * v.x };
    }
    pub fn unit_vector(u: Vec3) Vec3 {
        return u.div(u.length());
    }
};

pub const Point3 = Vec3;
pub const Color = Vec3;

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
test "neg" {
    const v1 = Vec3.init(1, -2, 0);
    try expectEqual(v1.neg().x, -1);
    try expectEqual(v1.neg().y, 2);
    try expectEqual(v1.neg().z, 0);
}

test "plus_eq" {
    const v1 = Vec3.init(1, -2, 0);
    var v2 = Vec3.init(1, 2, 3);

    v2.plus_eq(v1);
    // v1 unchanged
    try expectEqual(v1.x, 1);
    try expectEqual(v1.y, -2);
    try expectEqual(v1.z, 0);

    try expectEqual(v2.x, 2);
    try expectEqual(v2.y, 0);
    try expectEqual(v2.z, 3);
}

test "scale_inplace" {
    var v1 = Vec3.init(1, -2, 0);
    v1.scale_inplace(3);

    try expectEqual(v1.x, 3);
    try expectEqual(v1.y, -6);
    try expectEqual(v1.z, 0);
}

test "length" {
    const v1 = Vec3.init(1, -2, 0);
    const l = v1.length();
    const l2 = v1.length_squared();

    try expectEqual(@as(f64, 1 + 4 + 0), l2);
    try expectEqual(@as(f64, std.math.sqrt(1.0 + 4.0 + 0.0)), l);
}
