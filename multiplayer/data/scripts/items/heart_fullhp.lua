dofile( "data/scripts/game_helpers.lua" )

function item_pickup( entity_item, entity_who_picked, name )
	
	local max_hp = 0
	local healing = 0
	
	local x, y = EntityGetTransform( entity_item )
	
	local is_shared = ModSettingGet("multiplayer.shared_regen")
	local damagemodels
	if is_shared and EntityHasTag(entity_who_picked, "player_unit") then
		local human_players = EntityGetWithTag("player_unit")
		damagemodels = EntityGetComponent( human_players[1], "DamageModelComponent" ) -- Should exist as we've come this far
		for i=2, #human_players do
			local other_damagemodels = EntityGetComponent( human_players[i], "DamageModelComponent" )
			for j, model in ipairs(other_damagemodels) do
				table.insert(damagemodels, model)
			end
		end
	else
		damagemodels = EntityGetComponent( entity_who_picked, "DamageModelComponent" )
	end

	if ModSettingGet("multiplayer.regen_respawn") then
		CrossCall("respawn_all")
	end

	if( damagemodels ~= nil ) then
		for i,damagemodel in ipairs(damagemodels) do
			max_hp = tonumber( ComponentGetValue( damagemodel, "max_hp" ) )
			local hp = tonumber( ComponentGetValue( damagemodel, "hp" ) )
			
			healing = max_hp - hp
			
			ComponentSetValue( damagemodel, "hp", max_hp)
		end
	end

	EntityLoad("data/entities/particles/image_emitters/heart_fullhp_effect.xml", x, y-12)
	EntityLoad("data/entities/particles/heart_out.xml", x, y-8)
	GamePrintImportant( "$log_heart_fullhp", GameTextGet( "$logdesc_heart_fullhp", tostring(math.floor(max_hp*25)), tostring(math.floor(healing*25)) ) )

	-- remove the item from the game
	EntityKill( entity_item )
end
