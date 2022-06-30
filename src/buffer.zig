const vec3 = @import("vec3.zig");
pub const RGBA = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,

    pub fn from_vec3(v3c: vec3.Color) RGBA {
        return RGBA{ .r = @floatToInt(u8, v3c.x * 255), .g = @floatToInt(u8, v3c.y * 255), .b = @floatToInt(u8, v3c.z * 255), .a = 255 };
    }
};

// This is... gross
pub const screen_height: usize = 240;
pub const screen_width: usize = 320;

pub const Buffer = struct {
    buf: [screen_height][screen_width]RGBA,
    height: i16,
    width: i16,
};
