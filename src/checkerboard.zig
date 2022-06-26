const std = @import("std");

extern fn consoleLogEx(location: [*]const u8, size: usize) void;

fn consoleLog(sl: []const u8) void {
    consoleLogEx(@ptrCast([*]const u8, sl), sl.len);
}

var logBuf: [4096]u8 = std.mem.zeroes([4096]u8);

fn consoleLogFmt(comptime fmt: []const u8, args: anytype) void {
    var lb = std.io.fixedBufferStream(&logBuf).writer();
    lb.print(fmt, args) catch unreachable;
    const written: usize = lb.context.pos;
    consoleLogEx(@ptrCast([*]const u8, &logBuf), written);
}

const screen_height: usize = 240;
const screen_width: usize = 320;

// pixels where each pixel is 4 bytes (rgba)
var screen_buffer = Buffer{ .buf = std.mem.zeroes([screen_height][screen_width]RGBA), .height = screen_height, .width = screen_width };

// The returned pointer gets used as an offset integer to the wasm memory
export fn getScreenBufferPointer() [*]u8 {
    return @ptrCast([*]u8, &screen_buffer.buf);
}

const Buffer = struct {
    buf: [screen_height][screen_width]RGBA,
    height: i16,
    width: i16,
};

const RGBA = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,
};

fn drawRect(buffer: *Buffer, x: i16, y: i16, w: i16, h: i16, col: RGBA) void {
    var i = @maximum(0, x);
    while (i < @minimum(x + w, buffer.width)) {
        var j = @maximum(0, y);
        while (j < @minimum(y + h, buffer.height)) {
            buffer.buf[@intCast(usize, j)][@intCast(usize, i)] = col;
            j += 1;
        }
        i += 1;
    }
}

export fn drawScreen(
    dark_value_red: u8,
    dark_value_green: u8,
    dark_value_blue: u8,
    light_value_red: u8,
    light_value_green: u8,
    light_value_blue: u8,
) void {
    const col = RGBA{ .r = dark_value_red, .g = dark_value_green, .b = dark_value_blue, .a = 255 };

    consoleLog("hello");
    drawRect(&screen_buffer, light_value_blue, light_value_green, dark_value_blue, light_value_red, col);

    // for (screen_buffer) |*row, y| {
    //     for (row) |*square, x| {
    //         var is_dark_square = true;

    //         if ((y % 2) == 0) {
    //             is_dark_square = false;
    //         }

    //         if ((x % 2) == 0) {
    //             is_dark_square = !is_dark_square;
    //         }

    //         var square_value_r = dark_value_red;
    //         var square_value_g = dark_value_green;
    //         var square_value_b = dark_value_blue;
    //         if (!is_dark_square) {
    //             square_value_r = light_value_red;
    //             square_value_g = light_value_green;
    //             square_value_b = light_value_blue;
    //         }

    //         square.*[0] = square_value_r;
    //         square.*[1] = square_value_g;
    //         square.*[2] = square_value_b;
    //         square.*[3] = 255;
    //     }
    // }
}
