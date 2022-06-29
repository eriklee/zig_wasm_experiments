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

const Style = enum {
    Rect,
    Line,
};

var style = Style.Line;

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

fn drawLineH(buffer: *Buffer, x: i16, y: i16, w: i16, col: RGBA) void {
    if (y < 0 or y > buffer.height)
        return;

    var i = @maximum(0, x);
    while (i < @minimum(x + w, buffer.width)) {
        buffer.buf[@intCast(usize, y)][@intCast(usize, i)] = col;
        i += 1;
    }
}

fn drawLineV(buffer: *Buffer, x: i16, y: i16, h: i16, col: RGBA) void {
    if (x < 0 or x > buffer.width)
        return;

    var i = @maximum(0, y);
    while (i < @minimum(y + h, buffer.height)) {
        buffer.buf[@intCast(usize, i)][@intCast(usize, x)] = col;
        i += 1;
    }
}

fn drawLine(buffer: *Buffer, x1: i16, y1: i16, x2: i16, y2: i16, col: RGBA) void {
    // +1 in w/h is to make things a bit more consistent
    if (x1 == x2) {
        if (y1 < y2) drawLineV(buffer, x1, y1, y2 - y1 + 1, col) else drawLineV(buffer, x1, y2, y1 - y2 + 1, col);
        return;
    } else if (y1 == y2) {
        if (x1 < x2) drawLineH(buffer, x1, y1, x2 - x1 + 1, col) else drawLineH(buffer, x2, y1, x1 - x2 + 1, col);
        return;
    }
    // figure out whether line is more horizontal or vertical
    // color a pixel for each step in x or y
    // (x if line more horizontal, y if line more vertical)
    // This is to avoid having lines which are more dots
    const xdiff: i16 = std.math.absInt(x2 - x1) catch unreachable;
    const ydiff: i16 = std.math.absInt(y2 - y1) catch unreachable;
    var slope = @intToFloat(f64, (y2 - y1)) / @intToFloat(f64, (x2 - x1));
    if (xdiff >= ydiff) {
        // make x1 < x2 to simplify things a bit
        const xstart = @maximum(@minimum(x1, x2), 0);
        const xend = @minimum(@maximum(x1, x2), buffer.width - 1);
        const ystart = (if (x1 < x2) y1 else y2) + @floatToInt(i16, (slope * @intToFloat(f64, xstart - @minimum(x1, x2))));
        // horizontalish
        var i = xstart;
        while (i <= xend) {
            const yval = @floatToInt(i16, (slope * @intToFloat(f64, i - xstart))) + ystart;
            if (!(yval >= buffer.height or yval < 0)) {
                buffer.buf[@intCast(usize, yval)][@intCast(usize, i)] = col;
            }
            i += 1;
        }
    } else {
        // verticalish
        // make y1 < y2 to simplify things a bit
        const ystart = @maximum(@minimum(y1, y2), 0);
        const yend = @minimum(@maximum(y1, y2), buffer.height - 1);
        slope = 1 / slope;
        const xstart = (if (y1 < y2) x1 else x2) + @floatToInt(i16, (slope * @intToFloat(f64, ystart - @minimum(y1, y2))));
        var i = ystart;
        while (i <= yend) {
            const xval = @floatToInt(i16, (slope * @intToFloat(f64, i - ystart))) + xstart;
            if (!(xval >= buffer.width or xval < 0)) {
                buffer.buf[@intCast(usize, i)][@intCast(usize, xval)] = col;
            }
            i += 1;
        }
    }
}

fn drawTestLineImage(buffer: *Buffer, line_l: f64, line_count: i16, angle_delta: f64, time: u32) void {
    const mid_x: i16 = @divFloor(buffer.width, 2);
    const mid_y: i16 = @divFloor(buffer.height, 2);

    //consoleLogFmt("Drawing test line image: lc:{} ll:{} angle:{}", .{ line_count, line_l, angle_delta });
    const start_angle: u8 = @truncate(u5, @divFloor(time, 16));
    var i: u8 = 0;
    while (i < line_count) {
        const irad = @intToFloat(f64, i + start_angle) / 360 * angle_delta * std.math.tau;
        const x2 = @floatToInt(i16, line_l * std.math.cos(irad)) + mid_x;
        const y2 = @floatToInt(i16, line_l * std.math.sin(irad)) + mid_y;
        const col = RGBA{ .r = i *% 5, .g = i *% 10, .b = i *% 15, .a = 255 };
        if (style == Style.Line) {
            drawLine(buffer, mid_x, mid_y, x2, y2, col);
        } else if (style == Style.Rect) {
            drawRect(buffer, x2, y2, x2, y2, col);
        }
        i += 1;
    }
}

export fn setStyle(
    new_style: u8,
) void {
    if (new_style == 0)
        style = Style.Rect
    else if (new_style == 1)
        style = Style.Line
    else
        consoleLogFmt("not sure what this style is: {}", .{new_style});
}

export fn drawScreen(
    line_count: i16,
    angle_delta: i16,
    line_length: i16,
    time: u32,
) void {
    consoleLogFmt("draw called: lc:{} ll:{} angle:{}", .{ line_count, line_length, angle_delta });

    // blank out the screen
    const col = RGBA{ .r = 255, .g = 255, .b = 255, .a = 255 };
    drawRect(&screen_buffer, 0, 0, screen_buffer.width, screen_buffer.height, col);

    drawTestLineImage(&screen_buffer, @intToFloat(f64, line_length), line_count, @intToFloat(f64, angle_delta), time);
    //}
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
