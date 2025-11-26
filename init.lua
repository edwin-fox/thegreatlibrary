local modpath = minetest.get_modpath("thegreatlibrary")

-- Initialize thegreatlibrary table first
thegreatlibrary = {}

-- Load the main cataloguing system
dofile(modpath .. "/cataloguing.lua")

-- Load the easy bookshelf system
dofile(modpath .. "/bookshelf.lua")

-- Load recipes
dofile(modpath .. "/recipes.lua")

minetest.log("action", "[thegreatlibrary] Mod loaded successfully!")

-- Initialize the system immediately during mod load
minetest.log("action", "[thegreatlibrary] Initializing The Great Library mod...")
thegreatlibrary.load_catalog()
thegreatlibrary.register_bookshelf_books() -- Use the new bookshelf system
minetest.log("action", "[thegreatlibrary] The Great Library mod initialized successfully!")