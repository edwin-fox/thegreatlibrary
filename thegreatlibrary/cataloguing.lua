local modpath = minetest.get_modpath("thegreatlibrary")

-- Configuration
local LINES_PER_PAGE = 75
local PAGES_PER_CHAPTER = 15

-- Initialize tables
thegreatlibrary.reading_states = {}
thegreatlibrary.catalog = {}
thegreatlibrary.book_data = {} -- Store book content for later use
thegreatlibrary.catalog_states = {} -- Track catalog UI state per player

-- Core API functions
function thegreatlibrary.show_book_formspec(player_name, book_id, title, book_type, current_page, current_chapter)
    local content = thegreatlibrary.book_data[book_id]
    if not content then
        minetest.chat_send_player(player_name, "Book content not found: " .. book_id)
        return
    end
    
    local formspec = thegreatlibrary.generate_formspec(book_id, title, content, book_type, current_page, current_chapter)
    minetest.show_formspec(player_name, "thegreatlibrary:book_" .. book_id, formspec)
end

function thegreatlibrary.generate_formspec(book_id, title, content, book_type, current_page, current_chapter)
    local formspec = {
        "size[13,10.5]",
        "real_coordinates[true]",
        "label[0.5,0.5;" .. minetest.formspec_escape(title) .. "]",
        "button_exit[11.5,0;1.5,1;exit;X]"
    }
    
    if book_type == "short" then
        table.insert(formspec, "textarea[0.5,1;12,8.5;content;;" .. minetest.formspec_escape(content) .. "]")
    else
        local processed_content = thegreatlibrary.process_content(content, book_type)
        if not processed_content then
            table.insert(formspec, "textarea[0.5,1;12,8.5;content;;" .. minetest.formspec_escape(content) .. "]")
            minetest.log("error", "[thegreatlibrary] Content processing failed for book: " .. book_id)
        else
            formspec = thegreatlibrary.add_navigation_elements(formspec, processed_content, book_id, current_page, current_chapter)
        end
    end
    
    return table.concat(formspec, "")
end

function thegreatlibrary.process_content(content, book_type)
    if not content or content == "" then
        return {
            pages = {"No content available."},
            total_pages = 1,
            total_chapters = 1
        }
    end
    
    local result = {
        pages = {},
        chapters = {},
        total_pages = 1,
        total_chapters = 1
    }
    
    if book_type == "medium" then
        result = thegreatlibrary.split_into_pages(content)
        result.chapters = {
            {
                pages = result.pages,
                title = "Content",
                total_pages = result.total_pages
            }
        }
        result.total_chapters = 1
    elseif book_type == "large" then
        result = thegreatlibrary.split_into_chapters(content)
        result.total_pages = 0
        for _, chapter in ipairs(result.chapters) do
            result.total_pages = result.total_pages + chapter.total_pages
        end
    else
        result.pages[1] = content
        result.total_pages = 1
        result.chapters = {
            {
                pages = result.pages,
                title = "Content",
                total_pages = 1
            }
        }
        result.total_chapters = 1
    end
    
    minetest.log("action", "[thegreatlibrary] Processed " .. book_type .. " book: " .. 
                 result.total_pages .. " pages, " .. result.total_chapters .. " chapters")
    
    return result
end

function thegreatlibrary.split_into_pages(content)
    local lines = thegreatlibrary.split_into_lines(content)
    local pages = {}
    local total_pages = math.max(1, math.ceil(#lines / LINES_PER_PAGE))
    
    for page_num = 1, total_pages do
        local start_line = (page_num - 1) * LINES_PER_PAGE + 1
        local end_line = math.min(page_num * LINES_PER_PAGE, #lines)
        local page_content = ""
        
        for i = start_line, end_line do
            if lines[i] then
                page_content = page_content .. lines[i] .. "\n"
            end
        end
        
        pages[page_num] = page_content
    end
    
    return {
        pages = pages,
        total_pages = total_pages,
        total_chapters = 1
    }
end

function thegreatlibrary.split_into_chapters(content)
    local lines = thegreatlibrary.split_into_lines(content)
    local chapters = {}
    local total_lines = #lines
    
    if total_lines == 0 then
        chapters[1] = {
            pages = {content},
            title = "Chapter 1",
            total_pages = 1
        }
        return {
            chapters = chapters,
            total_chapters = 1
        }
    end
    
    local total_pages = math.max(1, math.ceil(total_lines / LINES_PER_PAGE))
    local total_chapters = math.max(1, math.ceil(total_pages / PAGES_PER_CHAPTER))
    
    for chapter_num = 1, total_chapters do
        local chapter_pages = {}
        local chapter_start_page = (chapter_num - 1) * PAGES_PER_CHAPTER + 1
        local chapter_end_page = math.min(chapter_num * PAGES_PER_CHAPTER, total_pages)
        local pages_in_chapter = chapter_end_page - chapter_start_page + 1
        
        for page_in_chapter = 1, pages_in_chapter do
            local actual_page_num = chapter_start_page + page_in_chapter - 1
            local start_line = (actual_page_num - 1) * LINES_PER_PAGE + 1
            local end_line = math.min(actual_page_num * LINES_PER_PAGE, total_lines)
            local page_content = ""
            
            for i = start_line, end_line do
                if lines[i] then
                    page_content = page_content .. lines[i] .. "\n"
                end
            end
            
            chapter_pages[page_in_chapter] = page_content
        end
        
        chapters[chapter_num] = {
            pages = chapter_pages,
            title = "Chapter " .. chapter_num,
            total_pages = pages_in_chapter
        }
    end
    
    return {
        chapters = chapters,
        total_chapters = total_chapters
    }
end

function thegreatlibrary.split_into_lines(text)
    local lines = {}
    if not text or text == "" then
        return {"No content available."}
    end
    
    local normalized_text = text:gsub("\r\n", "\n"):gsub("\r", "\n")
    
    for line in normalized_text:gmatch("([^\n]*)\n?") do
        table.insert(lines, line)
    end
    
    while #lines > 0 and lines[#lines] == "" do
        table.remove(lines)
    end
    
    if #lines == 0 then
        table.insert(lines, text)
    end
    
    return lines
end

function thegreatlibrary.add_navigation_elements(formspec, content, book_id, current_page, current_chapter)
    if not content then
        table.insert(formspec, "textarea[0.5,1;12,8;content;;Error: Invalid content structure]")
        return formspec
    end
    
    if content.chapters and #content.chapters > 0 then
        local current_chapter_data = content.chapters[current_chapter]
        
        minetest.log("action", "[thegreatlibrary] Displaying chapter " .. current_chapter .. ", page " .. current_page .. " of " .. (current_chapter_data and current_chapter_data.total_pages or "?"))
        
        -- Chapter list
        local chapter_items = {}
        for i = 1, #content.chapters do
            if content.chapters[i] and content.chapters[i].title then
                table.insert(chapter_items, minetest.formspec_escape(content.chapters[i].title))
            end
        end
        
        table.insert(formspec, "textlist[0.5,1;2,8;chapters;" .. table.concat(chapter_items, ",") .. ";" .. current_chapter .. ";false]")
        
        local display_text = "No content available for this chapter."
        
        if current_chapter_data and current_chapter_data.pages and current_chapter_data.pages[current_page] then
            display_text = current_chapter_data.pages[current_page]
        else
            minetest.log("error", "[thegreatlibrary] No content for chapter " .. current_chapter .. ", page " .. current_page)
        end
        
        -- Main content area
        table.insert(formspec, "textarea[2.8,1;9.7,7.5;content;;" .. minetest.formspec_escape(display_text) .. "]")
        
        -- Navigation buttons
        local button_y = 8.8
        
        -- Previous Chapter
        if current_chapter > 1 then
            table.insert(formspec, "button[2.8," .. button_y .. ";2.5,1;prev_chapter;< Previous Chapter]")
        else
            table.insert(formspec, "button[2.8," .. button_y .. ";2.5,1;prev_chapter;< Previous Chapter]")
        end
        
        -- Next Chapter
        if current_chapter < #content.chapters then
            table.insert(formspec, "button[5.4," .. button_y .. ";2.5,1;next_chapter;Next Chapter >]")
        else
            table.insert(formspec, "button[5.4," .. button_y .. ";2.5,1;next_chapter;Next Chapter >]")
        end
        
        -- Previous Page
        if current_page > 1 then
            table.insert(formspec, "button[7.9," .. button_y .. ";2.5,1;prev_page;< Previous Page]")
        else
            table.insert(formspec, "button[7.9," .. button_y .. ";2.5,1;prev_page;< Previous Page]")
        end
        
        -- Next Page
        if current_chapter_data and current_page < current_chapter_data.total_pages then
            table.insert(formspec, "button[10.4," .. button_y .. ";2.5,1;next_page;Next Page >]")
        else
            table.insert(formspec, "button[10.4," .. button_y .. ";2.5,1;next_page;Next Page >]")
        end
        
        -- Status labels - FIXED POSITIONING
        -- Chapter label at the bottom left
        table.insert(formspec, "label[0.5,9.2;Chapter " .. current_chapter .. " of " .. #content.chapters .. "]")
        -- Page label positioned below the chapter label
        if current_chapter_data then
            table.insert(formspec, "label[0.5,9.7;Page " .. current_page .. " of " .. current_chapter_data.total_pages .. "]")
        else
            table.insert(formspec, "label[0.5,9.7;Page " .. current_page .. " of ?]")
        end
            
    elseif content.pages and #content.pages > 0 then
        local display_text = content.pages[current_page] or "No content available for this page."
        
        table.insert(formspec, "textarea[0.5,1;12,7.5;content;;" .. minetest.formspec_escape(display_text) .. "]")
        
        local button_y = 8.8
        
        if current_page > 1 then
            table.insert(formspec, "button[0.5," .. button_y .. ";2.5,1;prev_page;< Previous Page]")
        else
            table.insert(formspec, "button[0.5," .. button_y .. ";2.5,1;prev_page;< Previous Page]")
        end
        
        if current_page < #content.pages then
            table.insert(formspec, "button[3.1," .. button_y .. ";2.5,1;next_page;Next Page >]")
        else
            table.insert(formspec, "button[3.1," .. button_y .. ";2.5,1;next_page;Next Page >]")
        end
        
        table.insert(formspec, "label[5.7,9.2;Page " .. current_page .. " of " .. #content.pages .. "]")
    else
        table.insert(formspec, "textarea[0.5,1;12,8;content;;Error: No valid content structure]")
    end
    
    return formspec
end

-- Catalog management
function thegreatlibrary.load_catalog()
    local worldpath = minetest.get_worldpath()
    local catalog_path = worldpath .. "/thegreatlibrary_catalog.txt"
    local file = io.open(catalog_path, "r")
    if file then
        local content = file:read("*all")
        file:close()
        thegreatlibrary.catalog = minetest.deserialize(content) or {}
        minetest.log("action", "[thegreatlibrary] Loaded catalog with " .. count_table_keys(thegreatlibrary.catalog) .. " books")
    else
        thegreatlibrary.catalog = {}
        minetest.log("action", "[thegreatlibrary] No existing catalog found, creating new one")
    end
end

function thegreatlibrary.save_catalog()
    local worldpath = minetest.get_worldpath()
    local catalog_path = worldpath .. "/thegreatlibrary_catalog.txt"
    local file = io.open(catalog_path, "w")
    if file then
        file:write(minetest.serialize(thegreatlibrary.catalog))
        file:close()
        minetest.log("action", "[thegreatlibrary] Saved catalog with " .. count_table_keys(thegreatlibrary.catalog) .. " books")
    else
        minetest.log("error", "[thegreatlibrary] Failed to save catalog")
    end
end

-- Helper function to count table keys
function count_table_keys(tbl)
    local count = 0
    for _ in pairs(tbl or {}) do
        count = count + 1
    end
    return count
end

function thegreatlibrary.register_book_in_catalog(book_id, title, filepath, size, book_type)
    thegreatlibrary.catalog[book_id] = {
        title = title,
        filepath = filepath,
        size = size,
        type = book_type,
        registered_at = os.time()
    }
    minetest.log("action", "[thegreatlibrary] Registered book in catalog: " .. title .. " (" .. book_id .. ")")
    thegreatlibrary.save_catalog()
end

function thegreatlibrary.get_book_info(book_id)
    return thegreatlibrary.catalog[book_id]
end

function thegreatlibrary.list_books()
    local books = {}
    for id, info in pairs(thegreatlibrary.catalog) do
        table.insert(books, {
            id = id,
            title = info.title,
            type = info.type,
            size = info.size
        })
    end
    
    -- Sort books by title for consistent display
    table.sort(books, function(a, b)
        return a.title:lower() < b.title:lower()
    end)
    
    minetest.log("action", "[thegreatlibrary] Listed " .. #books .. " books from catalog")
    return books
end

-- Book registration functions
function thegreatlibrary.register_book_item(book_id, title, content)
    local content_length = #content
    local book_type = "short"
    
    if content_length > 3000 then
        book_type = "large"
    elseif content_length > 500 then
        book_type = "medium"
    end
    
    minetest.log("action", "[thegreatlibrary] Registering book '" .. title .. "' as " .. book_type .. 
                 " (" .. content_length .. " characters)")
    
    thegreatlibrary.book_data[book_id] = content
    
    minetest.register_craftitem("thegreatlibrary:" .. book_id, {
        description = title,
        inventory_image = "manifesto.png",
        groups = {book = 1},
        stack_max = 1,
        
        on_use = function(itemstack, player, pointed_thing)
            local player_name = player:get_player_name()
            thegreatlibrary.show_book_formspec(player_name, book_id, title, book_type, 1, 1)
        end,
    })
    
    return book_type, content_length
end

-- NEW: Library catalog formspec with the specified design
function thegreatlibrary.show_catalog_formspec(player_name)
    local state = thegreatlibrary.catalog_states[player_name] or {
        selected_book_index = 1,
        selected_chapter = 1,
        current_page = 1,
        search_text = "",
        book_states = {}
    }
    
    local books = thegreatlibrary.list_books()
    
    -- Apply search filter if any
    local filtered_books = {}
    if state.search_text and state.search_text ~= "" then
        for _, book in ipairs(books) do
            if book.title:lower():find(state.search_text:lower(), 1, true) then
                table.insert(filtered_books, book)
            end
        end
    else
        filtered_books = books
    end
    
    -- Ensure selected index is valid
    if #filtered_books == 0 then
        state.selected_book_index = 1
    else
        state.selected_book_index = math.max(1, math.min(state.selected_book_index, #filtered_books))
    end
    
    local selected_book = filtered_books[state.selected_book_index]
    local book_content = selected_book and thegreatlibrary.book_data[selected_book.id]
    local processed_content = book_content and thegreatlibrary.process_content(book_content, selected_book and selected_book.type or "short")
    
    -- Get book-specific state
    local book_state = {current_page = 1, current_chapter = 1}
    if selected_book then
        book_state = state.book_states[selected_book.id] or {current_page = 1, current_chapter = 1}
        
        -- Ensure state is valid
        if processed_content then
            local max_chapters = processed_content.total_chapters or 1
            local current_chapter_data = processed_content.chapters and processed_content.chapters[book_state.current_chapter]
            local max_pages = current_chapter_data and current_chapter_data.total_pages or processed_content.total_pages or 1
            
            book_state.current_chapter = math.max(1, math.min(book_state.current_chapter, max_chapters))
            book_state.current_page = math.max(1, math.min(book_state.current_page, max_pages))
            
            -- Update the state with validated values
            state.book_states[selected_book.id] = book_state
        end
    end
    
    -- Build formspec according to the specified design
    local formspec = {
        "formspec_version[6]",
        "size[25,15]",
        "image[0,0;25,15.1;thegreatlibrary.png]",
        "label[14.8,1.2;The Great Library]",
    }
    
    -- Book catalogue list
    local book_items = {}
    for _, book in ipairs(filtered_books) do
        table.insert(book_items, minetest.formspec_escape(book.title))
    end
    
    if #book_items == 0 then
        table.insert(book_items, "No books found")
    end
    
    table.insert(formspec, "textlist[1.3,2.2;6,5.8;catalogue;" .. table.concat(book_items, ",") .. ";" .. state.selected_book_index .. ";false]")
    
    -- Navigation buttons for books
    table.insert(formspec, "button[0.3,2.2;0.8,0.8;prevbook;^]")
    table.insert(formspec, "button[0.3,3.1;0.8,0.8;nextbook;v]")
    
    -- Search field (using field instead of pwdfield for normal text input)
    table.insert(formspec, "field[1.3,1.1;6,0.8;booksearch;Search Book Title;" .. minetest.formspec_escape(state.search_text or "") .. "]")
    
    -- Chapter list (only if a book is selected)
    if selected_book and processed_content and processed_content.chapters and #processed_content.chapters > 0 then
        local chapter_items = {}
        for _, chapter in ipairs(processed_content.chapters) do
            table.insert(chapter_items, minetest.formspec_escape(chapter.title))
        end
        
        table.insert(formspec, "textlist[1.3,8.3;6,5.6;chapter;" .. table.concat(chapter_items, ",") .. ";" .. book_state.current_chapter .. ";false]")
        
        -- Navigation buttons for chapters
        table.insert(formspec, "button[0.3,8.3;0.8,0.8;prevchapter;^]")
        table.insert(formspec, "button[0.3,9.2;0.8,0.8;nextchapter;v]")
    else
        -- Show empty chapter list when no chapters available
        table.insert(formspec, "textlist[1.3,8.3;6,5.6;chapter;No chapters;1;false]")
    end
    
    -- Page navigation and content display
    if selected_book and processed_content then
        local current_chapter_data = processed_content.chapters and processed_content.chapters[book_state.current_chapter]
        local max_pages = current_chapter_data and current_chapter_data.total_pages or processed_content.total_pages or 1
        
        -- Page navigation buttons
        table.insert(formspec, "button[7.5,1.1;0.8,0.8;prevpage;<]")
        table.insert(formspec, "button[8.5,1.1;0.8,0.8;nextpage;>]")
        
        -- Page indicator
        table.insert(formspec, "label[7.5,0.7;Page " .. book_state.current_page .. " of " .. max_pages .. "]")
        
        -- Book content display
        local display_text = "No content available."
        if current_chapter_data and current_chapter_data.pages and current_chapter_data.pages[book_state.current_page] then
            display_text = current_chapter_data.pages[book_state.current_page]
        elseif processed_content.pages and processed_content.pages[book_state.current_page] then
            display_text = processed_content.pages[book_state.current_page]
        elseif book_content then
            display_text = book_content
        end
        
        table.insert(formspec, "textarea[7.6,2.2;16.6,11.7;bookcontent;;" .. minetest.formspec_escape(display_text) .. "]")
    else
        table.insert(formspec, "textarea[7.6,2.2;16.6,11.7;bookcontent;;Select a book to read its content]")
    end
    
    thegreatlibrary.catalog_states[player_name] = state
    
    minetest.show_formspec(player_name, "thegreatlibrary:catalog", table.concat(formspec, ""))
end

-- Formspec handler
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname:find("thegreatlibrary:book_") then
        local book_id = formname:match("thegreatlibrary:book_(.+)")
        local player_name = player:get_player_name()
        
        minetest.log("action", "[thegreatlibrary] Handling fields for book: " .. (book_id or "nil"))
        
        if fields.exit then
            thegreatlibrary.reading_states[player_name] = nil
            return true
        end
        
        local state = thegreatlibrary.reading_states[player_name] or {
            current_page = 1,
            current_chapter = 1,
            book_id = book_id
        }
        
        local book_info = thegreatlibrary.get_book_info(book_id)
        if not book_info then
            minetest.log("error", "[thegreatlibrary] Book info not found for: " .. (book_id or "nil"))
            return true
        end
        
        local content = thegreatlibrary.book_data[book_id]
        local processed_content = thegreatlibrary.process_content(content, book_info.type)
        
        local changed = false
        
        if fields.next_page then
            local current_chapter_data = processed_content.chapters and processed_content.chapters[state.current_chapter]
            local max_pages = current_chapter_data and current_chapter_data.total_pages or processed_content.total_pages
            
            if state.current_page < max_pages then
                state.current_page = state.current_page + 1
                changed = true
                minetest.log("action", "[thegreatlibrary] Next page: " .. state.current_page .. " of " .. max_pages)
            end
        elseif fields.prev_page then
            if state.current_page > 1 then
                state.current_page = state.current_page - 1
                changed = true
                minetest.log("action", "[thegreatlibrary] Previous page: " .. state.current_page)
            end
        elseif fields.next_chapter then
            if state.current_chapter < processed_content.total_chapters then
                state.current_chapter = state.current_chapter + 1
                state.current_page = 1
                changed = true
                minetest.log("action", "[thegreatlibrary] Next chapter: " .. state.current_chapter)
            end
        elseif fields.prev_chapter then
            if state.current_chapter > 1 then
                state.current_chapter = state.current_chapter - 1
                state.current_page = 1
                changed = true
                minetest.log("action", "[thegreatlibrary] Previous chapter: " .. state.current_chapter)
            end
        elseif fields.chapters then
            local event = minetest.explode_textlist_event(fields.chapters)
            if event.type == "CHG" then
                state.current_chapter = event.index
                state.current_page = 1
                changed = true
                minetest.log("action", "[thegreatlibrary] Chapter selected: " .. state.current_chapter)
            end
        end
        
        thegreatlibrary.reading_states[player_name] = state
        
        if changed then
            thegreatlibrary.show_book_formspec(
                player_name, 
                book_id, 
                book_info.title, 
                book_info.type,
                state.current_page,
                state.current_chapter
            )
        end
        
        return true
    elseif formname == "thegreatlibrary:catalog" then
        local player_name = player:get_player_name()
        local state = thegreatlibrary.catalog_states[player_name] or {
            selected_book_index = 1,
            selected_chapter = 1,
            current_page = 1,
            search_text = "",
            book_states = {} -- Store state per book
        }
        
        local books = thegreatlibrary.list_books()
        local filtered_books = {}
        if state.search_text and state.search_text ~= "" then
            for _, book in ipairs(books) do
                if book.title:lower():find(state.search_text:lower(), 1, true) then
                    table.insert(filtered_books, book)
                end
            end
        else
            filtered_books = books
        end
        
        -- Ensure selected index is valid
        if #filtered_books == 0 then
            state.selected_book_index = 1
        else
            state.selected_book_index = math.max(1, math.min(state.selected_book_index, #filtered_books))
        end
        
        local selected_book = filtered_books[state.selected_book_index]
        
        -- Initialize book-specific state if needed
        if selected_book and not state.book_states[selected_book.id] then
            state.book_states[selected_book.id] = {
                current_page = 1,
                current_chapter = 1
            }
        end
        
        -- Get book-specific state
        local book_state = selected_book and state.book_states[selected_book.id] or {current_page = 1, current_chapter = 1}
        
        local changed = false
        
        -- Handle search field
        -- FIX: Only update search if it actually CHANGED
        if fields.booksearch and fields.booksearch ~= state.search_text then
            state.search_text = fields.booksearch
            state.selected_book_index = 1
            changed = true
            minetest.log("action", "[thegreatlibrary] Search: " .. (state.search_text or ""))
        end
        
        -- Handle book navigation
        if fields.prevbook then
            if state.selected_book_index > 1 then
                state.selected_book_index = state.selected_book_index - 1
                changed = true
                minetest.log("action", "[thegreatlibrary] Previous book: " .. state.selected_book_index)
            end
        elseif fields.nextbook then
            if state.selected_book_index < #filtered_books then
                state.selected_book_index = state.selected_book_index + 1
                changed = true
                minetest.log("action", "[thegreatlibrary] Next book: " .. state.selected_book_index)
            end
        elseif fields.catalogue then
            local event = minetest.explode_textlist_event(fields.catalogue)
            if event.type == "CHG" then
                state.selected_book_index = event.index
                changed = true
                minetest.log("action", "[thegreatlibrary] Book selected: " .. state.selected_book_index)
            end
        end
        
        -- Handle chapter and page navigation only if a book is selected
        if selected_book then
            local book_content = thegreatlibrary.book_data[selected_book.id]
            local processed_content = book_content and thegreatlibrary.process_content(book_content, selected_book.type or "short")
            
            if processed_content then
                local max_chapters = processed_content.total_chapters or 1
                local current_chapter_data = processed_content.chapters and processed_content.chapters[book_state.current_chapter]
                local max_pages = current_chapter_data and current_chapter_data.total_pages or processed_content.total_pages or 1
                
                -- Handle chapter navigation
                if fields.prevchapter then
                    if book_state.current_chapter > 1 then
                        book_state.current_chapter = book_state.current_chapter - 1
                        book_state.current_page = 1
                        changed = true
                        minetest.log("action", "[thegreatlibrary] Previous chapter: " .. book_state.current_chapter)
                    end
                elseif fields.nextchapter then
                    if book_state.current_chapter < max_chapters then
                        book_state.current_chapter = book_state.current_chapter + 1
                        book_state.current_page = 1
                        changed = true
                        minetest.log("action", "[thegreatlibrary] Next chapter: " .. book_state.current_chapter)
                    end
                elseif fields.chapter then
                    local event = minetest.explode_textlist_event(fields.chapter)
                    if event.type == "CHG" then
                        book_state.current_chapter = event.index
                        book_state.current_page = 1
                        changed = true
                        minetest.log("action", "[thegreatlibrary] Chapter selected: " .. book_state.current_chapter)
                    end
                end
                
                -- Handle page navigation
                if fields.prevpage then
                    if book_state.current_page > 1 then
                        book_state.current_page = book_state.current_page - 1
                        changed = true
                        minetest.log("action", "[thegreatlibrary] Previous page: " .. book_state.current_page)
                    end
                elseif fields.nextpage then
                    if book_state.current_page < max_pages then
                        book_state.current_page = book_state.current_page + 1
                        changed = true
                        minetest.log("action", "[thegreatlibrary] Next page: " .. book_state.current_page)
                    end
                end
                
                -- Update book state
                if selected_book then
                    state.book_states[selected_book.id] = book_state
                end
            end
        end
        
        thegreatlibrary.catalog_states[player_name] = state
        
        if changed then
            thegreatlibrary.show_catalog_formspec(player_name)
        end
        
        return true
    end
end)

-- Chat command to access catalog
minetest.register_chatcommand("library", {
    description = "Open The Great Library catalog",
    func = function(name, param)
        thegreatlibrary.show_catalog_formspec(name)
        return true
    end
})