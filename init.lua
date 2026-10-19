local modname = minetest.get_current_modname()
local storage = minetest.get_mod_storage()
local selected_kit = {}

local function get_kits()
    local raw = storage:get_string("kits")
    if raw == "" then return {} end
    local ok, data = pcall(minetest.deserialize, raw)
    if ok and type(data) == "table" then return data end
    return {}
end
local function save_kits(kits) storage:set_string("kits", minetest.serialize(kits)) end
local function names_of(kits)
    local names = {}
    for name in pairs(kits) do names[#names + 1] = name end
    table.sort(names)
    return names
end
local function valid_name(name)
    return type(name) == "string" and #name > 0 and #name <= 32 and name:match("^[%w_%-]+$") ~= nil
end
local function create_kit(player, kit_name)
    kit_name = (kit_name or ""):match("^%s*(.-)%s*$")
    if not valid_name(kit_name) then return false, "Kit names may use letters, numbers, underscores, and hyphens (up to 32 characters)." end
    local items = {}
    for _, stack in ipairs(player:get_inventory():get_list("main") or {}) do
        if not stack:is_empty() then items[#items + 1] = stack:to_string() end
    end
    if #items == 0 then return false, "Your main inventory is empty. Put the kit items in your inventory first." end
    local kits = get_kits()
    kits[kit_name] = { items = items, created_by = player:get_player_name() }
    save_kits(kits)
    return true, "Saved kit '" .. kit_name .. "' with " .. #items .. " item stack(s)."
end
local function give_kit(player, kit_name)
    local kit = get_kits()[kit_name]
    if not kit or type(kit.items) ~= "table" then return false, "Kit not found. Use /kit to list available kits." end
    local inv, leftovers = player:get_inventory(), {}
    for _, itemstring in ipairs(kit.items) do
        local stack = ItemStack(itemstring)
        if not stack:is_empty() then
            local rest = inv:add_item("main", stack)
            if not rest:is_empty() then leftovers[#leftovers + 1] = rest end
        end
    end
    for _, stack in ipairs(leftovers) do
        local rest = inv:add_item("main", stack)
        if not rest:is_empty() then minetest.add_item(player:get_pos(), rest) end
    end
    if #leftovers > 0 then return true, "Kit '" .. kit_name .. "' given; extra items were dropped nearby because your inventory was full." end
    return true, "Kit '" .. kit_name .. "' given."
end
local function show_admin_menu(player)
    local kits, name = get_kits(), player:get_player_name()
    local names, escaped = names_of(kits), {}
    for _, kit_name in ipairs(names) do escaped[#escaped + 1] = minetest.formspec_escape(kit_name) end
    local list = table.concat(escaped, ",")
    if list == "" then list = "(no kits yet)" end
    local formspec = "formspec_version[4]size[10,7.5]" ..
        "label[0.4,0.35;Kit Manager — Admin]" ..
        "label[0.4,0.8;Put the desired kit items in your main inventory, then save them under a name.]" ..
        "field[0.5,1.65;3.8,0.8;kit_name;Kit name;]" ..
        "button[4.4,1.35;4.8,0.8;save_kit;Save kit from my inventory]" ..
        "label[0.5,2.25;Existing kits (select one)]" ..
        "textlist[0.5,2.6;3.8,3.5;kit_list;" .. list .. ";1;false]" ..
        "button[4.4,2.8;4.8,0.8;give_preview;Give selected kit to me]" ..
        "button[4.4,3.8;4.8,0.8;delete_kit;Delete selected kit]" ..
        "button_exit[7.5,6.4;1.7,0.7;close;Close]"
    minetest.show_formspec(name, modname .. ":admin", formspec)
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= modname .. ":admin" then return false end
    local name = player:get_player_name()
    if not minetest.check_player_privs(name, { server = true }) then
        minetest.chat_send_player(name, "You need the server privilege to manage kits.")
        return true
    end
    local kits = get_kits()
    if fields.kit_list then
        local event = minetest.explode_textlist_event(fields.kit_list)
        if event and (event.type == "CHG" or event.type == "DCL") then
            local names = names_of(kits)
            selected_kit[name] = names[event.index]
        end
    end
    if fields.save_kit then
        local ok, msg = create_kit(player, fields.kit_name or "")
        minetest.chat_send_player(name, msg)
        show_admin_menu(player)
    elseif fields.give_preview then
        local kit_name = selected_kit[name]
        if kit_name and kits[kit_name] then
            local _, msg = give_kit(player, kit_name)
            minetest.chat_send_player(name, msg)
        else
            minetest.chat_send_player(name, "Select a kit first.")
        end
        show_admin_menu(player)
    elseif fields.delete_kit then
        local kit_name = selected_kit[name]
        if kit_name and kits[kit_name] then
            kits[kit_name] = nil
            save_kits(kits)
            selected_kit[name] = nil
            minetest.chat_send_player(name, "Deleted kit '" .. kit_name .. "'.")
        else
            minetest.chat_send_player(name, "Select a kit to delete.")
        end
        show_admin_menu(player)
    end
    return true
end)
minetest.register_on_leaveplayer(function(player) selected_kit[player:get_player_name()] = nil end)

minetest.register_chatcommand("kit", {
    params = "[name]", description = "List available kits or claim one",
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if not player then return false, "Player not found." end
        param = (param or ""):match("^%s*(.-)%s*$")
        if param == "" then
            local names = names_of(get_kits())
            if #names == 0 then return true, "No kits are available yet." end
            return true, "Available kits: " .. table.concat(names, ", ") .. " — claim one with /kit <name>."
        end
        return give_kit(player, param)
    end,
})
minetest.register_chatcommand("kitadmin", {
    description = "Open the in-game kit manager (server privilege required)", privs = { server = true },
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then return false, "Player not found." end
        show_admin_menu(player)
        return true, "Opening Kit Manager."
    end,
})
minetest.register_chatcommand("kitcreate", {
    params = "<name>", description = "Save a kit from your main inventory", privs = { server = true },
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if not player then return false, "Player not found." end
        return create_kit(player, param)
    end,
})
minetest.register_chatcommand("kitdelete", {
    params = "<name>", description = "Delete a kit", privs = { server = true },
    func = function(_, param)
        local kit_name = (param or ""):match("^%s*(.-)%s*$")
        local kits = get_kits()
        if not kits[kit_name] then return false, "Kit not found." end
        kits[kit_name] = nil
        save_kits(kits)
        return true, "Deleted kit '" .. kit_name .. "'."
    end,
})
