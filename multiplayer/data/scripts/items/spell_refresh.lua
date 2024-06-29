dofile( "data/scripts/game_helpers.lua" )

function item_pickup( entity_item, entity_who_picked, name )
	local x, y = EntityGetTransform( entity_item )
	EntityLoad("data/entities/particles/image_emitters/spell_refresh_effect.xml", x, y-12)
	GamePrintImportant( "$itemtitle_spell_refresh", "$itemdesc_spell_refresh" )
	
	
	if ModSettingGet("multiplayer.shared_refresh") == true then
		for _, human_player in ipairs(EntityGetWithTag("player_unit")) do
			GameRegenItemActionsInPlayer( human_player )
		end
	else
		GameRegenItemActionsInPlayer( entity_who_picked )
	end

	-- remove the item from the game
	EntityKill( entity_item )
end
