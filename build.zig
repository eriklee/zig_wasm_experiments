const std = @import("std");

const page_size = 65536; // wasm page size in bytes

pub fn build(b: *std.build.Builder) void {
    b.setPreferredReleaseMode(.ReleaseSmall);
    const mode = b.standardReleaseOptions();

    const checkerboard_step = b.step("checkerboard", "Compiles checkerboard.zig");
    const checkerboard_lib = b.addSharedLibrary("checkerboard", "./src/checkerboard.zig", .unversioned);
    checkerboard_lib.setBuildMode(mode);
    checkerboard_lib.setTarget(.{
        .cpu_arch = .wasm32,
        .os_tag = .freestanding,
        .abi = .musl,
    });
    checkerboard_lib.setOutputDir(".");

    checkerboard_lib.import_memory = true; // import linear memory from the environment
    checkerboard_lib.initial_memory = 40 * page_size; // initial size of the linear memory
    checkerboard_lib.max_memory = 40 * page_size;
    checkerboard_lib.global_base = 6560; // offset in linear memory to place global data

    checkerboard_lib.install();
    checkerboard_step.dependOn(&checkerboard_lib.step);

    // // Standard target options allows the person running `zig build` to choose
    // // what target to build for. Here we do not override the defaults, which
    // // means any target is allowed, and the default is native. Other options
    // // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // // Standard release options allow the person running `zig build` to select
    // // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    // const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("zig-wasm", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_tests = b.addTest("src/main.zig");
    exe_tests.setTarget(target);
    exe_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}
