dofile( "data/scripts/game_helpers.lua" )
dofile_once("data/scripts/lib/utilities.lua")
dofile( "data/scripts/perks/perk.lua" )

function item_pickup( entity_item, entity_who_picked, item_name )
	local is_player = EntityHasTag(entity_who_picked, "player_unit")
	local perk_mode = ModSettingGet("multiplayer.perk_mode") 
	local kill_other_perks = true
	local components = EntityGetComponent( entity_item, "VariableStorageComponent" )
	
	if ( components ~= nil ) then
		for key,comp_id in pairs(components) do 
			local var_name = ComponentGetValue( comp_id, "name" )
			if( var_name == "perk_dont_remove_others") then
				if( ComponentGetValueBool( comp_id, "value_bool" ) ) then
					kill_other_perks = false
				end
			end
		end
	end
	if is_player and perk_mode == "personnal" then
		kill_other_perks = false
	elseif is_player and perk_mode == "shared" then
		local human_players = EntityGetWithTag("player_unit")
		for _, human in ipairs(human_players) do
			perk_pickup( entity_item, human, item_name, true, kill_other_perks )
		end
		return
	end
	perk_pickup( entity_item, entity_who_picked, item_name, true, kill_other_perks )
end