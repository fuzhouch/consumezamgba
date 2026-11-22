const std = @import("std");
const gba = @import("zamgba");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});

    // zamgba dependency
    const zamgba_dep = b.dependency("zamgba", .{});
    const zamgba_module = zamgba_dep.module("zamgba");
    const hal_module = zamgba_dep.module("zamgba-hal");
    const engine_module = zamgba_dep.module("zamgba-engine");
    const zurag_exe = zamgba_dep.artifact("zurag");

    // 1. Pong ROM (renamed from first)
    const pong_rom = gba.arm.addROM(b, .{
        .optimize = optimize,
        .name = "pong",
        .root_source_file = b.path("src/pong.zig"),
    });
    pong_rom.root_module.addImport("zamgba", zamgba_module);
    b.installArtifact(pong_rom);

    // 2. Assets for Collision Demo
    // Automatically convert tsetseg flying broom asset to Zig using local assets
    const convert_broom_sprite = b.addRunArtifact(zurag_exe);
    convert_broom_sprite.addArg("sprite");
    convert_broom_sprite.addArg("--png");
    convert_broom_sprite.addFileArg(b.path("assets/tsetseg-ride-on-broom-64x64-0001.png"));
    convert_broom_sprite.addArg("--json");
    convert_broom_sprite.addFileArg(b.path("assets/tsetseg-ride-on-broom-64x64-0001.json"));
    convert_broom_sprite.addArg("--output");
    const broom_sprite_zig = convert_broom_sprite.addOutputFileArg("tsetseg_broom.zig");

    const broom_sprite_mod = b.createModule(.{
        .root_source_file = broom_sprite_zig,
    });
    broom_sprite_mod.addImport("zamgba-engine", engine_module);
    broom_sprite_mod.addImport("zamgba-hal", hal_module);

    // Automatically convert large dirt map LDtk asset to Zig using local assets
    const large_dirt_tileset_png = b.path("assets/tileset/tileset-8x8-dirt.png");
    const convert_large_dirt_map = b.addRunArtifact(zurag_exe);
    convert_large_dirt_map.addArg("tilemap");
    convert_large_dirt_map.addArg("--input");
    convert_large_dirt_map.addFileArg(b.path("assets/tileset/T06-large-map-512-512.ldtk"));
    convert_large_dirt_map.addFileInput(large_dirt_tileset_png);
    convert_large_dirt_map.addArg("--output");
    const large_dirt_map_zig = convert_large_dirt_map.addOutputFileArg("large_dirt_map.zig");

    const large_dirt_map_mod = b.createModule(.{
        .root_source_file = large_dirt_map_zig,
    });
    large_dirt_map_mod.addImport("zamgba-engine", engine_module);
    large_dirt_map_mod.addImport("zamgba-hal", hal_module);

    // 3. Collision Demo ROM
    const collision_rom = gba.arm.addROM(b, .{
        .optimize = optimize,
        .name = "collision_demo",
        .root_source_file = b.path("src/collision_demo.zig"),
    });
    collision_rom.root_module.addImport("zamgba", zamgba_module);
    collision_rom.root_module.addImport("tsetseg_broom", broom_sprite_mod);
    collision_rom.root_module.addImport("large_dirt_map", large_dirt_map_mod);
    b.installArtifact(collision_rom);
}
