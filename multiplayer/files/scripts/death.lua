
function death(damage_type_bit_field, damage_message, entity_thats_responsible, drop_items)
    local entity = GetUpdatedEntityID()
    local x, y = EntityGetTransform(entity)
    -- Tombstone
    EntityLoad("data/entities/props/furniture_tombstone_01.xml", x, y-30)
    -- Drop items
    local true_drop_items = ModSettingGet("multiplayer.drop_items")
    if true_drop_items then
        GameDropAllItems(entity)
    end
    -- Save player data to respawn later TODO
    CrossCall("store_player", entity)
end