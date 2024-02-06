const std = @import("std");
const gba = @import("zamgba");

// Use gba.arm.addROM() to define your target. This function defines
// necessary ARM target and steps to create ROM image (*.gba)
// when installing artifact. Reference to zamgba project,
// ``src/build/arm.zig`` for details.
pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const rom = gba.arm.addROM(b, .{
        .optimize = optimize,
        .name = "first",
        .root_source_file = "src/main.zig",
    });

    // zamgba exposes itself as a module that contains its
    // functionality. Client project may rename the import name
    // in addImport() call, if there's any naming conflict.
    const zamgba_module = b.dependency("zamgba", .{}).module("zamgba");
    rom.root_module.addImport("gba", zamgba_module);

    b.installArtifact(rom);
}
