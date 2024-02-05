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
    b.installArtifact(rom);
}
