-- bookshelf.lua
-- Easy book registration for The Great Library
-- Users can add their books here without modifying core files

local modpath = minetest.get_modpath("thegreatlibrary")

-- Book registration table - ADD BOOKS HERE
thegreatlibrary.bookshelf_books = {
    {
        id = "manifest",
        title = "O Manifesto do Partido Comunista",
        filename = "manifest.txt",
        description = "Os fundamentos basilares para a construção de um novo mundo"
    },
    
    -- ADD YOUR CUSTOM BOOKS BELOW THIS LINE
    -- Example custom books:
    -- {
    --     id = "my_story",
    --     title = "My Adventure Story", 
    --     filename = "my_story.txt"
    -- },
    -- {
    --     id = "game_guide",
    --     title = "Player's Guide",
    --     filename = "guidebook.txt"
    -- }
    
    -- Add more books here following the same format
    {
        id = "esquerdismo",
        title = "A Doença Infantil do «Esquerdismo» no Comunismo",
        filename = "esquerdismo-lenin.txt",
        description = "Edição em Português da Editorial Avante, 1977, t3, pp 275-349"
    },
    {
        id = "sirenas",
        title = "As Sirenas de Titã",
        filename = "sirenas.txt",
        description = "Tradução do livro Sirens of Titan, de Kurt Vonnegut"
    },
}

-- Function to register all bookshelf books
function thegreatlibrary.register_bookshelf_books()
    local books_path = modpath .. "/books/"
    local registered_count = 0
    
    for _, book_info in ipairs(thegreatlibrary.bookshelf_books) do
        local filepath = books_path .. book_info.filename
        local file = io.open(filepath, "r")
        
        if file then
            local content = file:read("*all")
            file:close()
            
            -- Register the book item and add to catalog
            local book_type, content_length = thegreatlibrary.register_book_item(
                book_info.id, 
                book_info.title, 
                content
            )
            
            thegreatlibrary.register_book_in_catalog(
                book_info.id,
                book_info.title,
                filepath,
                content_length,
                book_type
            )
            
            registered_count = registered_count + 1
            minetest.log("action", "[thegreatlibrary] Registered bookshelf book: " .. book_info.title)
        else
            minetest.log("error", "[thegreatlibrary] Book file not found: " .. filepath)
        end
    end
    
    minetest.log("action", "[thegreatlibrary] Successfully registered " .. registered_count .. " bookshelf books")
    return registered_count
end

-- Function to add a book dynamically (for other mods to use)
function thegreatlibrary.add_book_to_bookshelf(book_id, title, filename, description)
    table.insert(thegreatlibrary.bookshelf_books, {
        id = book_id,
        title = title,
        filename = filename,
        description = description or title
    })
    minetest.log("action", "[thegreatlibrary] Added book to bookshelf: " .. title)
end

-- API for other mods to register books easily
function thegreatlibrary.register_external_book(modname, book_id, title, filename, description)
    local external_path = minetest.get_modpath(modname) .. "/books/" .. filename
    local file = io.open(external_path, "r")
    
    if file then
        local content = file:read("*all")
        file:close()
        
        local book_type, content_length = thegreatlibrary.register_book_item(book_id, title, content)
        thegreatlibrary.register_book_in_catalog(book_id, title, external_path, content_length, book_type)
        
        minetest.log("action", "[thegreatlibrary] Registered external book from " .. modname .. ": " .. title)
        return true
    else
        minetest.log("error", "[thegreatlibrary] Could not find external book file: " .. external_path)
        return false
    end
end