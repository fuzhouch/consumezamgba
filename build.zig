const std = @import("std");
const gba = @import("zamgba");

// Use gba.arm.addROM() to define your target. This function defines
// necessary ARM target and steps to create ROM image (*.gba)
// when installing artifact. Reference to ``zamgba/src/build/arm.zig``
// for details.

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const exe = gba.arm.addROM(b, optimize, "testcli", "src/main.zig"); 
    b.installArtifact(exe);
}
