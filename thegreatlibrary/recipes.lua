-- Book crafting recipes
minetest.register_craft({
    output = "thegreatlibrary:manifest",
    recipe = {
        {"blueprint_worldgen:workplace_marker", "blueprint_worldgen:workplace_marker", "blueprint_worldgen:workplace_marker"},
        {"blueprint_worldgen:workplace_marker", "default:book", "blueprint_worldgen:workplace_marker"},
        {"blueprint_worldgen:workplace_marker", "blueprint_worldgen:workplace_marker", "blueprint_worldgen:workplace_marker"}
    }
})
