The Great Library

The Great Library is a Minetest mod that transforms plain text files into fully functional, readable in-game books. It features an intelligent formatting system that automatically organizes content into pages and chapters based on length, and a central catalog GUI for browsing the entire collection.

Features

    Dynamic Formatting: Automatically detects text length and formats books as:

        Short: Single scrollable page.

        Medium: Multi-page paginated book.

        Large: Multi-chapter, multi-page tome.

    Central Catalog: A searchable GUI (accessed via /library) listing all registered books.

    Read State Tracking: Remembers the last page and chapter a player was reading.

    External API: Easy support for other mods to register their own books into the library.

For Modders & Server Admins

How to Add Books

There are two ways to add books to The Great Library: directly inside the mod or via an external mod.

Method 1: The "Bookshelf" Method (Easiest)

Use this method if you are editing the mod directly.

    Place your .txt file into the thegreatlibrary/books/ folder.

    Open bookshelf.lua.

    Add a new entry to the thegreatlibrary.bookshelf_books table:


----------
thegreatlibrary.bookshelf_books = {

    -- Existing books...
    
    {
        id = "my_new_book",          -- Unique internal ID (no spaces)
        title = "The History of Mining", -- Display title
        filename = "mining_history.txt", -- The filename in the /books/ folder
        description = "A comprehensive guide to ores." -- Optional tooltip
    },
}
----------

Method 2: The External API (Recommended for Modpacks)

If you are creating a separate mod and want to inject books into The Great Library without modifying its core files:

    Create a books/ folder inside your own mod.

    Place your .txt files there.

    In your mod's init.lua, add a dependency on thegreatlibrary.

    Call the registration function:

----------

if minetest.get_modpath("thegreatlibrary") then
    thegreatlibrary.register_external_book(
        minetest.get_current_modname(), -- Your mod name
        "custom_guide",                 -- Unique ID
        "Survival Guide",               -- Book Title
        "guide.txt",                    -- Filename in YOUR mod's /books/ folder
        "A guide to surviving the wilds" -- Description
    )
end
----------

How to Add Crafting Recipes

Books registered in the library become standard craftitems. You can define recipes for them in recipes.lua (or your own mod's code) using the format thegreatlibrary:<book_id>.

Example: If you registered a book with the ID esquerdismo, the item name is thegreatlibrary:esquerdismo.

----------
minetest.register_craft({
    output = "thegreatlibrary:esquerdismo",
    recipe = {
        {"default:paper", "default:paper", "default:paper"},
        {"default:paper", "default:book",  "default:paper"},
        {"default:paper", "default:paper", "default:paper"}
    }
})
----------

Text Formatting Tips

    File Encoding: Ensure your text files are saved as UTF-8.

    Line Breaks: The mod automatically wraps text, but respects paragraph breaks (empty lines) in your .txt file.

    Length:

        < 500 chars: Creates a Pamphlet (Single view).

        500 - 3000 chars: Creates a Book (Paged).

        > 3000 chars: Creates a Tome (Chapters + Pages).

Commands

    /library - Opens the global catalog formspec to browse and read all registered books.
