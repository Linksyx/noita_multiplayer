-- First experiments for inventory fixes. I'll be continuing depending on Killua's gui library advancement.

---@diagnostic disable: lowercase-global
local base64 = require('mods/multiplayer/base64')

dofile_once("mods/multiplayer/NoitaPatcher/load.lua")
local np = require("noitapatcher")

ModMagicNumbersFileAdd("mods/multiplayer/files/magic_numbers/camera_fix.xml") -- Set debug camera speed to 0 to get full control
if ModSettingGet("multiplayer.zoom") == "out1" then
	ModMagicNumbersFileAdd("mods/multiplayer/files/magic_numbers/zoom_out1.xml")
elseif ModSettingGet("multiplayer.zoom") == "out2" then
	ModMagicNumbersFileAdd("mods/multiplayer/files/magic_numbers/zoom_out2.xml")
end

local ffi = require("ffi")

ffi.cdef[[
	// udp_server.dll (based on libuv for udp and threads for non blocking)
    typedef long ssize_t;

    typedef struct {
        void* handle;
        void* loop;
        void* packets;
        void* last_packet;
        int lock;
        int thread;
        int sem;
        int running;
        int sleep_interval;
    } udp_server_t;

    typedef struct {
        long __align;
        char __size[24];
    } pthread_mutex_t;

    typedef struct {
        long __align;
        char __size[4];
    } sem_t;

    udp_server_t* start_udp_server(const char* ip, int port, int sleep_interval);
    char* get_pending_packets(udp_server_t* server, ssize_t* length, char* sender_ip);
    void free_packet_data(char* data);
    void stop_server(udp_server_t* server);

]]

-- UDP server to receive inputs init
local upd_server = ffi.load("mods/multiplayer/udp_server")  -- libuv-1.dll (32 bits) may be necessary too

local port = tonumber(ModSettingGet("multiplayer.used_port"))

local server = upd_server.start_udp_server("0.0.0.0", port, 10) -- Settings
-- 0.0.0.0 to receive from any IP adress, port and sleep interval of 10 ms by default for the collecting loop

if server == nil then
    GamePrint("Failed to start UDP server")
    print("Failed to start UDP server")
    error("Failed to start UDP server")
end

local function getPackets()
    local length = ffi.new("ssize_t[1]")
    local sender_ip = ffi.new("char[16]")
    local packets = {}

    while true do
        local data = upd_server.get_pending_packets(server, length, sender_ip)
        if data == nil or length[0] == 0 then
            break
        end
        local packet_data = ffi.string(data, length[0])
        local sender_ip_str = ffi.string(sender_ip)
        table.insert(packets, {data = packet_data, ip = sender_ip_str})
        upd_server.free_packet_data(data)
    end
    return packets
end


function get_screen_data() -- SOURCE: nameless_abomination
    local gui = GuiCreate()
    GuiStartFrame( gui )

    local w, h = GuiGetScreenDimensions( gui )
    local real_w, real_h = 1280, 720 -- literally no way to get it properly
    
    GuiDestroy( gui )

    return w, h, real_w, real_h
end

function world2gui( x, y, player_x, player_y, is_raw ) -- SOURCE: nameless_abomination
    is_raw = is_raw or false
    
    local w, h, real_w, real_h = get_screen_data()
    local view_x = MagicNumbersGetValue( "VIRTUAL_RESOLUTION_X" ) + MagicNumbersGetValue( "VIRTUAL_RESOLUTION_OFFSET_X" )
    local view_y = MagicNumbersGetValue( "VIRTUAL_RESOLUTION_Y" ) + MagicNumbersGetValue( "VIRTUAL_RESOLUTION_OFFSET_Y" )
    local massive_balls_x, massive_balls_y = w/view_x, h/view_y
    
    if( not( is_raw )) then
        local cam_x, cam_y = player_x, player_y
        x, y = ( x - ( cam_x - view_x/2 )), ( y - ( cam_y - view_y/2 ))
    end
    x, y = massive_balls_x*x, massive_balls_y*y
    
    return x, y, {massive_balls_x,massive_balls_y}
end
-- Utility Functions
local w, h, real_w, real_h = get_screen_data()

function norme(x,y)
	return math.sqrt((x^2) + (y^2))
end

function normalize(x,y)
	local d = norme(x,y)
	if d > 0 then
		return x/d, y/d
	else
		return x, y
	end
end

function get_inventory_position(entity)
	local item_component = EntityGetFirstComponentIncludingDisabled(entity, "ItemComponent")
	return ComponentGetValue2(item_component, "inventory_slot")
end

function get_active_item(entity)
	local inv = EntityGetFirstComponentIncludingDisabled(entity, "Inventory2Component")
	if inv then
		local item = ComponentGetValue2(inv, "mActualActiveItem")
		if item>0 then
			return item
		end
	end
	return nil
end

function is_wand(entity)
	local ability_component = EntityGetFirstComponentIncludingDisabled(entity, "AbilityComponent")
	return ComponentGetValue2(ability_component, "use_gun_script")
end

function get_inventory(entity)
	for i, child in ipairs(EntityGetAllChildren(entity) or {}) do
		if EntityGetName(child) == "inventory_quick" then
			return child
		end
	end
end

function get_inventory_items(entity)
	local items = {}
	local inv = get_inventory(entity)
	if inv then
		for i, item in ipairs(EntityGetAllChildren(inv) or {}) do
			table.insert(items, item)
		end
	end
	return items
end

-- Horscht functions (from Inventory Bags), some previous inventory functions are inspired from him too

local sprite_xml_path_cache = {}

local function ends_with(str, ending)
	if not str then error("str is nil", 2) end
  return ending == "" or str:sub(-#ending) == ending
end

function get_xml_sprite(sprite_xml_path)
	if sprite_xml_path_cache[sprite_xml_path] then
		return sprite_xml_path_cache[sprite_xml_path]
	end
	local xml = nxml.parse(ModTextFileGetContent(sprite_xml_path))
	sprite_xml_path_cache[sprite_xml_path] = xml.attr.filename
	return xml.attr.filename
end

-- Apply controls

local use_wand = function(player_entity, data, frame)
    local controls = EntityGetFirstComponentIncludingDisabled( player_entity, "ControlsComponent" )
	if data == 1 then
		ComponentSetValue2(controls, "mButtonDownFire", true)
		ComponentSetValue2(controls, "mButtonFrameFire", frame+1)
	else
		ComponentSetValue2(controls, "mButtonDownFire", false)
	end
end
local spray_flask = function(player_entity, data, frame)
    local controls = EntityGetFirstComponentIncludingDisabled( player_entity, "ControlsComponent" )
	if data == 1 then
		ComponentSetValue2(controls, "mButtonDownFire2", true)
		ComponentSetValue2(controls, "mButtonFrameFire2", frame+1)
	else
		ComponentSetValue2(controls, "mButtonDownFire2", false)
	end
end
local throw = function(player_entity, data, frame)
    local controls = EntityGetFirstComponentIncludingDisabled( player_entity, "ControlsComponent" )
	if data == 1 then
		ComponentSetValue2(controls, "mButtonDownThrow", true)
		ComponentSetValue2(controls, "mButtonFrameThrow", frame+1)
	else
		ComponentSetValue2(controls, "mButtonDownThrow", false)
	end
end
local kick = function(player_entity, data, frame)
    local controls = EntityGetFirstComponentIncludingDisabled( player_entity, "ControlsComponent" )
	if data == 1 then
		ComponentSetValue2(controls, "mButtonDownKick", true)
		ComponentSetValue2(controls, "mButtonFrameKick", frame+1)
	else
		ComponentSetValue2(controls, "mButtonDownKick", false)
	end
end
local move_x = function(player_entity, data, frame)
    local controls = EntityGetFirstComponentIncludingDisabled( player_entity, "ControlsComponent" )
	local mouse_x, mouse_y = ComponentGetValue2(controls, "mMousePosition")
	ComponentSetValue2(controls, "mMousePosition", math.min(data/3, w-5), mouse_y) -- TODO: recheck why those values (it made sens when I made it...)
end
local move_y = function(player_entity, data, frame)
    local controls = EntityGetFirstComponentIncludingDisabled( player_entity, "ControlsComponent" )
	local mouse_x, mouse_y = ComponentGetValue2(controls, "mMousePosition")
	ComponentSetValue2(controls, "mMousePosition", mouse_x, math.min(data/3, h-8)) -- recheck why those values
end
local partial_x = function(player_entity, data, frame)
	local controls = EntityGetFirstComponentIncludingDisabled( player_entity, "ControlsComponent" )
	local mouse_x, mouse_y = ComponentGetValue2(controls, "mMousePosition")
	ComponentSetValue2(controls, "mMousePosition", math.max(math.min((mouse_x+data), w-5),0), mouse_y)
end
local partial_y = function(player_entity, data, frame)
	local controls = EntityGetFirstComponentIncludingDisabled( player_entity, "ControlsComponent" )
	local mouse_x, mouse_y = ComponentGetValue2(controls, "mMousePosition")
	ComponentSetValue2(controls, "mMousePosition", mouse_x, math.max(math.min((mouse_y+data),h-8), 0))
end
local wheel = function(player_entity, data, frame)
    local controls = EntityGetFirstComponentIncludingDisabled( player_entity, "ControlsComponent" )
	if data > 0 then
		ComponentSetValue2(controls, "mButtonDownChangeItemL", true)
    	ComponentSetValue2(controls, "mButtonFrameChangeItemL", frame+1)
    	ComponentSetValue2(controls, "mButtonCountChangeItemL", data)
		ComponentSetValue2(controls, "mButtonCountChangeItemR", 0)
		ComponentSetValue2(controls, "mButtonDownChangeItemR", false)
    elseif data < 0 then
        ComponentSetValue2(controls, "mButtonDownChangeItemR", true)
    	ComponentSetValue2(controls, "mButtonFrameChangeItemR", frame+1)
    	ComponentSetValue2(controls, "mButtonCountChangeItemR", -data)
		ComponentSetValue2(controls, "mButtonCountChangeItemL", 0)
		ComponentSetValue2(controls, "mButtonDownChangeItemL", false)
    else
		ComponentSetValue2(controls, "mButtonCountChangeItemL", 0)
		ComponentSetValue2(controls, "mButtonCountChangeItemR", 0)
		ComponentSetValue2(controls, "mButtonDownChangeItemL", false)
        ComponentSetValue2(controls, "mButtonDownChangeItemR", false)
	end
end
local left = function(player_entity, data, frame)
    local controls = EntityGetFirstComponentIncludingDisabled( player_entity, "ControlsComponent" )
	if data == 1 then
		ComponentSetValue2(controls, "mButtonDownLeft", true)
		ComponentSetValue2(controls, "mButtonFrameLeft", frame+1)
	else
		ComponentSetValue2(controls, "mButtonDownLeft", false)
	end
end
local right = function(player_entity, data, frame)
    local controls = EntityGetFirstComponentIncludingDisabled( player_entity, "ControlsComponent" )
	if data == 1 then
		ComponentSetValue2(controls, "mButtonDownRight", true)
		ComponentSetValue2(controls, "mButtonFrameRight", frame+1)
	else
		ComponentSetValue2(controls, "mButtonDownRight", false)
	end
end
local down = function(player_entity, data, frame)
    local controls = EntityGetFirstComponentIncludingDisabled( player_entity, "ControlsComponent" )
	if data == 1 then
		ComponentSetValue2(controls, "mButtonDownDown", true)
		ComponentSetValue2(controls, "mButtonFrameDown", frame+1)
	else
		ComponentSetValue2(controls, "mButtonDownDown", false)
	end
end
local fly = function(player_entity, data, frame)
    local controls = EntityGetFirstComponentIncludingDisabled( player_entity, "ControlsComponent" )
	if data == 1 then
		ComponentSetValue2(controls, "mButtonDownFly", true)
		ComponentSetValue2(controls, "mButtonFrameFly", frame+1)
	else
		ComponentSetValue2(controls, "mButtonDownFly", false)
	end
end
local interact = function(player_entity, data, frame)
    local controls = EntityGetFirstComponentIncludingDisabled( player_entity, "ControlsComponent" )
	if data == 1 then
		ComponentSetValue2(controls, "mButtonDownInteract", true)
		ComponentSetValue2(controls, "mButtonFrameInteract", frame+1)
	else
		ComponentSetValue2(controls, "mButtonDownInteract", false)
	end
end
local inventory = function(player_entity, data, frame)
    local controls = EntityGetFirstComponentIncludingDisabled( player_entity, "ControlsComponent" )
	if data == 1 then
		ComponentSetValue2(controls, "mButtonDownInventory", true)
		ComponentSetValue2(controls, "mButtonFrameInventory", frame+1)
	else
		ComponentSetValue2(controls, "mButtonDownInventory", false)
	end
end
local PLACEHOLDER = function(player_entity, data, frame)
end

actions = {
    ["move_x"] = move_x, -- receives coordinates (perfect but can't differentiate mice)
    ["move_y"] = move_y,
	["partial_x"] = partial_x, -- receives movements notifications (unprecise but can differentiate between mice)
    ["partial_y"] = partial_y,
    ["wheel"] = wheel,
    ["fly"] = fly,
    ["down"] = down,
    ["left"] = left,
    ["right"] = right,
    ["use_wand"] = use_wand,
    ["spray_flask"] = spray_flask,
    ["throw"] = throw,
    ["kick"] = kick,
    ["inventory"] = inventory,
    ["interact"] = interact
}

-- This is where the fun begins

local N = tonumber(ModSettingGet("multiplayer.player_number")) -- Number of players
local ALIVE = N -- Number of alive players
local MAX_N = N


local ptr_STREAMING_CHUNK_TARGET = ffi.cast("int*", 0x0115128c) -- Will break on other versions of Noita. Working version: Noita - Build Apr 30 2024 - 14:49:50 (this code appears twice)
ptr_STREAMING_CHUNK_TARGET[0] = 12*N

AI_COMPONENTS = {"AIAttackComponent", "AdvancedFishAIComponent", "AnimalAIComponent", "BossDragonComponent", "ControllerGoombaAIComponent", "CrawlerAnimalComponent", "FishAIComponent", "PhysicsAIComponent", "WormAIComponent"}
function disable_components(entity, comps)
	for _, comp_name in ipairs(comps) do
		comp_arr = EntityGetComponent(entity, comp_name)
		if comp_arr then
			for _, comp_id in ipairs(comp_arr) do
				EntitySetComponentIsEnabled(entity, comp_id, false)
				--GamePrint("disabled component ".. comp_name)
			end
		end
	end
end

local LAST_KNOWN_LOCATIONS = {} -- Updated within OnWorldPreUpdate
local POLY_DIST_TOLERANCE = 50 -- Max distance at which a polymorphed entity can be even considered as a potential player. If too high, players dying may become a polymorphed entity in this range

function get_player_number(entity)
	arr = EntityGetComponent(entity, "VariableStorageComponent")
	if arr then
		for _, var in ipairs(arr) do
			if ComponentGetValue2(var, "value_string") == "player_number" then
				return ComponentGetValue2(var, "value_int")
			end
		end
	end
	return nil
end

function store_player(player_entity)
	local i = get_player_number(player_entity)
	local stored_player = base64.encode(np.SerializeEntity(players[i]))
	GlobalsSetValue("stored player "..tostring(i),stored_player)
	return player_entity
end

np.CrossCallAdd("store_player", function(player_entity)
    return store_player(player_entity)
end)


function fetch_players()
	local players = {}
	local raw_players = EntityGetWithTag("player_unit")
	local polymorphed = EntityGetWithTag("polymorphed") -- Not polymorphed_player because it only works for player 1 for some reason

	for _, player_entity in ipairs(raw_players) do -- Normal and alive players
		player_number = get_player_number(player_entity)
		if player_number then
			players[player_number] = player_entity
		end
	end

	for i=1, N do
		if GlobalsGetValue("player "..tostring(i)) == "dead" then
			players[i] = "dead"
		end
	end

	-- Polymorphine part will be changed to Nathan's method
	for i=1, N do -- Polymorphed Players. The plan: if the player entity disappear, find nearest polymorphed entity that is not already noted as a player, and if it is close enough we guess it's probably him. If the player dies and at the same moment a close entity is polymorped he may become it until death.
		local continue = false -- WILL BREAK IF PLAYERS GET POLYMORPHED CLOSE TOGETHER - WILL ALSO BREAK ON WORMS
		if players[i] == nil and LAST_KNOWN_LOCATIONS[i] then
			local x0, y0 = unpack(LAST_KNOWN_LOCATIONS[i])
			local jmin, dmin
			for j, entity in ipairs(polymorphed) do -- Find the closest polymorphed entity from the LAST_KNOWN_LOCATIONS 
				player_number = get_player_number(entity)
				if player_number then -- Case: we already know which player it is, we can go onto the next player
					players[player_number] = entity
					continue = true
					break
				elseif jmin == nil then -- Case: minimum not initialized
					local x, y = EntityGetTransform(entity)
					jmin = j
					dmin = norme(x-x0, y-y0)
				else -- Case: update minimum if necessary
					local x, y = EntityGetTransform(entity)
					local d = norme(x-x0, y-y0)
					if d<dmin then
						jmin = j
						dmin = d
					end -- NOT ANYMORE TODO: exclude all polymorphed entity that weren't any players from being checked again (will prevent false positive if player dies near polymorphed entities)
				end -- TODO: Implement Nathan's method to get polymorphine working properly
			end
			if not continue then
				if dmin and dmin < POLY_DIST_TOLERANCE then -- Probably the right entity, recognise it as the player
					players[i] = polymorphed[jmin]
					local num = EntityAddComponent2(polymorphed[jmin], "VariableStorageComponent")
                	ComponentSetValue2(num, "value_string", "player_number")
                	ComponentSetValue2(num, "value_int", i)
					disable_components(polymorphed[jmin], AI_COMPONENTS)
					
					EntityAddComponent2(polymorphed[jmin], "LuaComponent", { -- Mimic attacking for polymorphed players (rest of controls works fine)
						script_source_file = "files/scripts/viewer_player_poly.lua", -- Thanks to dextercd for this (on top of all the advice!)
						enable_coroutines = true,
						execute_on_added = true,
						execute_every_n_frame = -1,
					})
				else -- Else declare player as dead
					players[i] = "dead"
					GlobalsSetValue("player "..tostring(i),"dead")
				end
			end
		end
	end

	return players
end

function respawn_all()
	local players = fetch_players()
	for i=1, N do
		if players[i] == "dead" then
			make_player(i)
			GamePrint("Respawned player "..tostring(i))
		end
	end
	GamePrint("All dead players respawned.")
end

np.CrossCallAdd("respawn_all", function()
    return respawn_all()
end)

function ApplyInput(input)
	players = fetch_players()
	--GamePrint(tostring(#input))
	--GamePrint(input)
	local player_number, action, data = string.match(input, "(%d+)%s+([^%s]+)%s+([^%s]+)")
	player_number = tonumber(player_number)
	if players[player_number] ~= "dead" then
		local frame = GameGetFrameNum()
		data = tonumber(data)
		local controls = EntityGetFirstComponentIncludingDisabled(players[player_number], "ControlsComponent" )
		if controls and actions[action] ~= nil then
			actions[action](players[player_number], data, frame)
		end
	end
end

current_id = 1
local function new_id()
	current_id = current_id + 1
	return current_id
end

local gui = GuiCreate()
function ControlsAndGui(players)
	for i=1, N do
		local controls = EntityGetFirstComponentIncludingDisabled( players[i], "ControlsComponent" )
		if controls then
			local mouse_x, mouse_y = ComponentGetValue2(controls, "mMousePosition")
			local player_x, player_y = EntityGetTransform(players[i])
			
			-- generalize aim alternation: TODO improve
			local x_offset = 0
			local y_offset = 0
			if SPLITSCREEN then -- Splitscreen cursor offset
				if N == 2 then
					if i == 1 then
						y_offset = 60
					else
						y_offset = -60
					end
				elseif N == 3 then
					if i == 1 then
						y_offset = 60
					elseif i == 2 then
						x_offset = 107
						y_offset = -60
					elseif i == 3 then
						x_offset = -107
						y_offset = -60
					end
				elseif N==4 then
					if i == 1 then
						x_offset = 107
						y_offset = 60
					elseif i == 2 then
						x_offset = -107
						y_offset = 60
					elseif i == 3 then
						x_offset = 107
						y_offset = -60
					elseif i == 4 then
						x_offset = -107
						y_offset = -60
					end
				end
			else -- Shared screen gui and cursor
				-- Cursor
				local cam_x, cam_y = GameGetCameraPos()
				x_offset = cam_x - player_x
				y_offset = cam_y - player_y
				-- Hotbar
				local hotbar_x = 5
				local hotbar_y = 10+(i-1)*31
				GuiImage(gui, new_id(), hotbar_x, hotbar_y, "mods/multiplayer/files/ui_gfx/inventory/hotbar.png",1,1,1)
				-- Highlighted square
				local active_item = get_active_item(players[i])
				if active_item then 
					local slot = get_inventory_position(active_item)
					local mini_offset = 0
					if not is_wand(active_item) then
						slot = slot + 4
						mini_offset = 2
					end
					GuiImage(gui, new_id(), hotbar_x+3+slot*20+mini_offset, hotbar_y+3, "data/ui_gfx/inventory/full_inventory_box_highlight.png",1,1,1)
				end
				-- Display items
				--[[
				items = get_inventory_items(players[i])
				for _, item in ipairs(items) do
					local slot = get_inventory_position(active_item)
					local mini_offset = 0
					local image_file
					if is_wand(active_item) then
						local sprite_component = EntityGetFirstComponentIncludingDisabled(wand, "SpriteComponent")
						local image_file = ComponentGetValue2(sprite_component, "image_file")
						if ends_with(image_file, ".xml") then
							image_file = get_xml_sprite(image_file)
						end
					else


						slot = slot + 4
						mini_offset = 2
					end
					GuiImage(gui, new_id(), hotbar_x+3+slot*20+mini_offset, hotbar_y+3, image_file,1,1,1)
				end]]--
			end
        	-- local mx, my = world2gui(mouse_x, mouse_y)
        	-- Cursor
			local local_mode = ModSettingGet("multiplayer.local_mode")
			if i ~= 1 or local_mode then
        		--GuiText(gui, mouse_x, mouse_y, "X")
				if i<7 then
					GuiImage(gui, new_id(), mouse_x-7, mouse_y-7, "mods/multiplayer/files/ui_gfx/cursors/mouse_cursor_"..tostring(i)..".png",1,1,1)
				else
        			GuiImage(gui, new_id(), mouse_x-7, mouse_y-7, "data/ui_gfx/mouse_cursor.png",1,1,1)
				end
			end
			-- Make flying possible
        	ComponentSetValue2(controls, "mFlyingTargetY", player_y-10)

			local px, py = world2gui(player_x, player_y, player_x + x_offset, player_y + y_offset)
			-- HP above head
			if ModSettingGet("multiplayer.show_hp") then
				local damage_component = EntityGetFirstComponent( players[i], "DamageModelComponent" )
				local health = ComponentGetValue2(damage_component, "hp")
				local max_health = ComponentGetValue2(damage_component, "max_hp")
				local hp_string = tostring(math.floor(health*25)).."/"..tostring(math.floor(max_health*25))
				GuiText(gui, px-(5*(#hp_string/2)), py-30, hp_string)
			end
        	-- Aim Vector
        	local aim_vector_x = mouse_x-px
        	local aim_vector_y = mouse_y-py
        	ComponentSetValue2(controls, "mAimingVector", aim_vector_x, aim_vector_y)
        	local n_aim_x, n_aim_y = normalize(aim_vector_x, aim_vector_y)
        	ComponentSetValue2(controls, "mAimingVectorNormalized", n_aim_x, n_aim_y)
		end
    end
end

function get_safe_coordinates(excluded_i)
	local players = fetch_players()
	local safe_x, safe_y
	local j = 1
	if players then
		while (not safe_x) and j <= N do
			if j ~= excluded_i and EntityGetIsAlive(players[j]) then -- Find a player to safely teleport PLAYERS[i] in bound AND outside of a wall
				safe_x, safe_y = EntityGetTransform(players[j])
			end
			j = j + 1
		end
		--GamePrint(tostring(safe_x))
		--GamePrint(tostring(safe_y))
		return safe_x, safe_y
	end
end


function make_player(i) -- TODO: add max health and perk conservation (should but doesn't work with Deserialize?)
	local safe_x, safe_y = get_safe_coordinates()
	local player_entity
	local stored = base64.decode(GlobalsGetValue("stored player "..tostring(i), ""))
	-- TODO: decode stored from base64
	if stored ~= "" then
		--GamePrint("found stored data for player "..tostring(i))
		player_entity = EntityCreateNew()
		if GlobalsGetValue("player ".. tostring(i)) == "dead" then
			np.DeserializeEntity(player_entity, stored, safe_x, safe_y)
			-- reduce max hp and heal (currently at last hp before death)
			local damage_component = EntityGetFirstComponent( player_entity, "DamageModelComponent" )
			local max_health = ComponentGetValue2(damage_component, "max_hp")
			local lower_hp = ModSettingGet("multiplayer.lower_hp")/100
			max_health = max_health*(1-lower_hp)
			max_health = math.max(max_health, 1) -- there's a *25 multiplier on game hp so 25 hp is 1. Minimum max hp set at 25
			ComponentSetValue2(damage_component, "hp", max_health)
			ComponentSetValue2(damage_component, "max_hp", max_health) -- Glass Cannon will cause health to not lower for a while, it is intended
		else
			np.DeserializeEntity(player_entity, stored)
		end
		-- Enable InventoryGuiComponent for one frame for the player
		if EntityGetIsAlive(player_entity) then -- TODO: fix is polymorphed (do that with another global var...)
			local inv_gui = EntityGetFirstComponent( player_entity, "InventoryGuiComponent" )
			if inv_gui then
				EntitySetComponentIsEnabled(players[i], inv_gui, true) -- It has to be true at least a frame for inventory slots to work, it's disabled in OnWorldPostUpdate
			end
		end
	else
		player_entity = EntityLoad( "data/entities/player.xml", safe_x, safe_y)
		-- Disable vanilla controls
		local controls = EntityGetFirstComponent( player_entity, "ControlsComponent" )
		ComponentSetValue2(controls, "enabled", false)
		-- Disable useless camera complications
		local camera = EntityGetFirstComponent( player_entity, "PlatformShooterPlayerComponent" )
		ComponentSetValue2(camera, "move_camera_with_aim", false)
		-- Mark the player with a component to find it even after restarting and polymorphing
		local num = EntityAddComponent2(player_entity, "VariableStorageComponent")
		ComponentSetValue2(num, "value_string", "player_number")
		ComponentSetValue2(num, "value_int", i)
		-- Add LuaComponents
		EntityAddComponent(player_entity, "LuaComponent", { -- For saving the player when he is about to die and droping items if necessary
		script_death="mods/multiplayer/files/scripts/death.lua"
		}) -- Yes dying as polymorphed won't drop items. I'll fix it someday (TODO)
	end
	GlobalsSetValue("player "..tostring(i),tostring(player_entity))
	LAST_KNOWN_LOCATIONS[i] = {safe_x, safe_y}
	-- Give 2 seconds of invulnerability
	local damage_component = EntityGetFirstComponent( player_entity, "DamageModelComponent" )
	ComponentSetValue2(damage_component, "invincibility_frames", 120)
	
	return player_entity
end

-- API Functions
function OnPlayerSpawned(player_entity) -- This runs when player entity has been created (so once at every start/restart)
	GamePrint("The multiplayer mod is enabled.")
	GamePrint("Check Mod Settings and README.txt files in the USER/REMOTE and USER/LOCAL folders.")
	GamePrint("Message @linksyx on the Noita discord for help, bug reports and suggestions.")	
	-- Camera
	GameSetCameraFree(true)
	-- Initialize some variables
	GlobalsSetValue("N", tostring(N))
	local max_n = GlobalsGetValue("MAX_N", "")
	if max_n ~= "" then
		MAX_N = math.max(tonumber(max_n), MAX_N)
	end
	GlobalsSetValue("MAX_N", MAX_N)
	if GlobalsGetValue("MULTIPLAYER_FIRST_LOAD_DONE", "0") == "1" then
		-- create a dummy entity on each player locations to load them
		local original_x, original_y 
		for i = 1, N do
			local loc = GlobalsGetValue("location player "..tostring(i), "")
			if loc ~= "" then
				local x, y = loc:match("(%d+)%s+(%d+)")
				x = tonumber(x)
				y = tonumber(y)
				local ent = EntityCreateNew()
				EntityAddComponent2(ent, "StreamingKeepAliveComponent")
				if x and y then
					EntityApplyTransform(ent, x, y)
				end
				EntityKill(ent)
			end
		end
		return
	else -- Runs once at world creation
		GlobalsSetValue("MULTIPLAYER_FIRST_LOAD_DONE", "1")
		-- Player 1 setup
		local num = EntityAddComponent2(player_entity, "VariableStorageComponent")
		ComponentSetValue2(num, "value_string", "player_number")
		ComponentSetValue2(num, "value_int", 1)
		-- Disable vanilla player controls
		local controls = EntityGetFirstComponent( player_entity, "ControlsComponent" )
		ComponentSetValue2(controls, "enabled", false)
		-- Disable camera following cursor
		local CameraComp = EntityGetFirstComponent( player_entity, "PlatformShooterPlayerComponent" )
		ComponentSetValue2(CameraComp, "move_camera_with_aim", false)
		-- Setup all desired players
		GamePrint("Initializing the players")
		for i=2, N do
			make_player(i)
		end
	end
	-- Enable InventoryGuiComponent for one frame for each player
	local players = fetch_players()
	for i=1, N do -- There will be issues if restart with polymorphed players. Fixed on another restart, TODO fix it (another global var should do...)
		if EntityGetIsAlive(players[i]) then
			local inv_gui = EntityGetFirstComponent( players[i], "InventoryGuiComponent" )
			if inv_gui then
				EntitySetComponentIsEnabled(players[i], inv_gui, true) -- It has to be true at least a frame for inventory slots to work, it's disabled in OnWorldPostUpdate
			end
		end
	end
end

local INV_FIX_FRAME = GameGetFrameNum()
function OnWorldPostUpdate()
	-- Disable InventoryGuiComponent for each player. It is done here because it has to be enabled for at least one frame for slots to work (mysteries of Noita)
	if GameGetFrameNum()-INV_FIX_FRAME>500 then -- 500 frames because it sometimes fails if too fast? not sure
		local players = fetch_players()
		if players then
			for i=1, N do
				if EntityGetIsAlive(players[i]) then
					local inv_gui = EntityGetFirstComponent( players[i], "InventoryGuiComponent" )
					if inv_gui then
						GamePrint("Inventory initialized for player ".. tostring(i))
						EntitySetComponentIsEnabled(players[i], inv_gui, false)
					end
				end
			end
		end
	end
end

if ModSettingGet("multiplayer.camera") == "splitscreen" then
	SPLITSCREEN = true
else
	SPLITSCREEN = false
end
TELEPORT_DISTANCE = ModSettingGet("multiplayer.teleport_distance") -- Teleport distance for Shared screen mode

function OnWorldPreUpdate() -- This is called every time the game is about to start updating the world
	local frame = GameGetFrameNum()
	local players = fetch_players()
	if players then
		-- Update ALIVE, LAST_KNOWN_LOCATIONS and stored players, update poly immunity according to settings, get average position, reset wheel position, ensure vanilla controls are disabled (TODO: fix anti-stun side effect)
		local x_moy, y_moy = 0, 0
		ALIVE = 0
		for i = 1, N do
			if EntityGetIsAlive(players[i]) then
			--if players[player_number] ~= "dead" then
				-- Disable polymorphing if choosen (done here instead of unpause because of players that are polymorphed at the moment of the setting change)
				if ModSettingGet("multiplayer.disable_poly") then
					if not EntityHasTag( players[i], "polymorphable_NOT" ) then
						EntityAddTag( players[i], "polymorphable_NOT" )
					end
				else
					if EntityHasTag( players[i], "polymorphable_NOT" ) then
						EntityRemoveTag( players[i], "polymorphable_NOT" )
					end
				end
				
				ALIVE = ALIVE + 1
				local x, y = EntityGetTransform(players[i])
				if x and y then
					LAST_KNOWN_LOCATIONS[i] = {x, y}
					x = math.floor(x)
					y = math.floor(y)
					GlobalsSetValue("location player "..tostring(i),tostring(x).." "..tostring(y)) -- used to respawn player on load; despite their StreamingKeepAliveComponent only the main player loads on game start
					x_moy, y_moy = x_moy+x, y_moy+y
				end

				wheel(players[i],0,frame)
				local controls = EntityGetFirstComponent( players[i], "ControlsComponent" )
				ComponentSetValue2(controls, "enabled", false)
			end
		end

		-- w, h, real_w, real_h = get_screen_data()
		--local main_player = np.GetPlayerEntity()
		--local CameraComp = EntityGetFirstComponent( main_player, "PlatformShooterPlayerComponent" )

		-- 2-players splitscreen (we don't generalize yet because not worth for 3 simple cases and more than 4 players is unreasonnable as long as we are stuck with only one screen and 60/N fps)
		if SPLITSCREEN and N == 2 and LAST_KNOWN_LOCATIONS[1+(frame%2)] then
			-- local x, y = EntityGetTransform(players[1+(frame%2)])
			local x, y =  unpack(LAST_KNOWN_LOCATIONS[1+(frame%2)])
			if frame%2 == 1 then 
				GameSetPostFxParameter("draw_screen", 2,1,0,0)
				GameSetCameraPos(x, y-60) -- 60 was found by trial and error
				--ComponentSetValue2(CameraComp,"mDesiredCameraPos", x, y+60)
			else
				GameSetPostFxParameter("draw_screen", 2,2,0,0)
				GameSetCameraPos(x, y+60)
				--ComponentSetValue2(CameraComp,"mDesiredCameraPos", x, y-60)
			end

		-- 3-players splitscreen
		elseif SPLITSCREEN and N == 3 and LAST_KNOWN_LOCATIONS[1+(frame%3)] then
			local x, y =  unpack(LAST_KNOWN_LOCATIONS[1+(frame%3)])
			if frame%3 == 0 then 
				GameSetPostFxParameter("draw_screen", 3,1,0,0)
				GameSetCameraPos(x, y+60)
			elseif frame%3 == 1 then
				GameSetPostFxParameter("draw_screen", 3,2,0,0)
				GameSetCameraPos(x+107, y-60) -- 107 is 60*(1920/1080)
			elseif frame%3 == 2 then
				GameSetPostFxParameter("draw_screen", 3,3,0,0)
				GameSetCameraPos(x-107, y-60)
			end

		-- 4-players splitscreen
		elseif SPLITSCREEN and N == 4 and LAST_KNOWN_LOCATIONS[1+(frame%4)] then
			local x, y =  unpack(LAST_KNOWN_LOCATIONS[1+(frame%4)])
			if frame%4 == 0 then 
				GameSetPostFxParameter("draw_screen", 4,1,0,0)
				GameSetCameraPos(x+107, y+60)
			elseif frame%4 == 1 then
				GameSetPostFxParameter("draw_screen", 4,2,0,0)
				GameSetCameraPos(x-107, y+60)
			elseif frame%4 == 2 then
				GameSetPostFxParameter("draw_screen", 4,3,0,0)
				GameSetCameraPos(x+107, y-60)
			elseif frame%4 == 3 then
				GameSetPostFxParameter("draw_screen", 4,4,0,0)
				GameSetCameraPos(x-107, y-60)
			end
		--TODO Adapt to zoom out mode!

		else -- Shared screen
			GameSetPostFxParameter("draw_screen", 1,0,0,0) -- TODO Add more conditions to shader
			if ALIVE>0 then
				x_moy = x_moy/ALIVE
				y_moy = y_moy/ALIVE
				GameSetCameraPos(x_moy, y_moy)
				for i=1, N do -- Safe teleport when far
					if EntityGetIsAlive(players[i]) then
						local x, y = EntityGetTransform(players[i])
						if players[i] and norme(x_moy-x, y_moy-y)>TELEPORT_DISTANCE and not SPLITSCREEN then
							GamePrint("Safe teleport!")
							local safe_x, safe_y = get_safe_coordinates(i)
							EntitySetTransform(players[i],safe_x, safe_y)
						end
					end
				end
			end
		end
	end

	-- Controls
	local success, packets = pcall(getPackets)
	if not success then
		GamePrint("Error while reading packets")
		print("Error while getting packets: ", packets)
	else
		for _, packet in ipairs(packets) do
			ApplyInput(packet.data)
			--GamePrint("Received packet from " .. packet.ip .. ": " .. packet.data)
		end
	end
	ControlsAndGui(players)
end

function OnPausedChanged(is_paused, is_inventory_pause)
	-- Apply mod settings changes
	if is_paused == false and is_inventory_pause == false then 

		-- Camera mode
		if ModSettingGet("multiplayer.camera") == "splitscreen" then
			SPLITSCREEN = true
		else
			SPLITSCREEN = false
		end

		-- Change in the number of players
		local n = tonumber(ModSettingGet("multiplayer.player_number"))
		if n == 0 then
			n = N
			ModSettingSet("multiplayer.player_number", N)
			GamePrint("0 players is not valid. The number of players has been set back to it's precedent value.")
		elseif SPLITSCREEN and n>4 then
			n = 2
			ModSettingSet("multiplayer.player_number", 2)
			GamePrint("For now, only 2, 3 and 4 players is available for splitscreen mode. The number of players wasn't updated. You can still change to shared screen when you want.")
		end
		if n>N then
			for i=N+1, MAX_N do
				if GlobalsGetValue("player "..tostring(i)) ~= "dead" then
					make_player(i)
					GamePrint("Spawned player "..tostring(i))
				end
			end
		end
		if n>MAX_N then
			for i=MAX_N+1, n do
				make_player(i)
				GamePrint("Spawned player "..tostring(i))
			end
			MAX_N = n
		elseif n<N then
			local players = fetch_players()
			for i=n+1, N do
				-- Store player
				local stored_player = base64.encode(np.SerializeEntity(players[i]))
				GlobalsSetValue("stored player "..tostring(i),stored_player)
				EntityKill(players[i])
				GamePrint("Player "..tostring(i).." has been saved and removed")
			end
		end
		N = n
		GlobalsSetValue("N", tostring(N))

		-- Change the maximum number of loaded chunks depending on player amount (12 is default). Too much will lag, but if it's too low and players space out there will be lag and corruption 
		-- Will break on other versions of Noita (pointer change). Working version: Noita - Build Apr 30 2024 - 14:49:50 (this code appears twice)
		local sch = 12 -- Default STREAMING_CHUNK_TARGET value
		if ModSettingGet("multiplayer.zoom_out") == "out1" then
			sch = 15
		elseif ModSettingGet("multiplayer.zoom_out") == "out2" then
			sch = 18
		end
		if SPLITSCREEN then
			local ptr_STREAMING_CHUNK_TARGET = ffi.cast("int*", 0x0115128c)
			ptr_STREAMING_CHUNK_TARGET[0] = sch*N
		end
		-- Respawn all button 
		if ModSettingGet("multiplayer.respawn_all") then
			respawn_all()
			ModSettingSet("multiplayer.respawn_all", false)
		end
	end
end


function OnPlayerDied(player_entity) -- Trigger the game over when the time comes
	local players = fetch_players()
	local done = false
	local i = 1
	while not done and i<=N do -- get an alive player
		if players[i] ~= "dead" and players[i] ~= player_entity then
			done = true
			np.SetPlayerEntity(players[i])
		end
		i = i+1
	end
	if not done then
		GameTriggerGameOver()
	end
end

--[[ TODO LIST
Make More HP per Heart personnal (and some other perks)
Make lottery random copy in personnal perk mode
Fix inventory (Priority but annoying!)
Fix polymorphine better
Fix camera when pressing alt: detect it myself and adapt
Try to get 2 screens working to go beyond 4 players splitscreen. Try to change fps in game.
Learn more on Networking to understand how things like Parsec and RustDesk can do without port forwarding and implement sending every player is full screen
Fix sound (hard?)
Implement other respawn mecanisms
Fix bugs
Allow better control over creating, storing and reviving specific players. (ex: 4 players splitscreen with players 2, 3, 5, 6 if others aren't there, etc)
]]--