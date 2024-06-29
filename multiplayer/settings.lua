dofile("data/scripts/lib/mod_settings.lua")

-- Use ModSettingGet() in the game to query settings.
local mod_id = "multiplayer"
mod_settings_version = 1
mod_settings = 
{
  {
    category_id = "general_settings",
    ui_name = "Mutliplayer",
    ui_description = "Settings - Reminder to check the README and to use the Python script for controls if you can't move...",
    settings = 
    {
	  {
		not_setting = true,
		ui_description = "Change this value at any time to respawn all dead players (acts as a button)",
		ui_fn = function(mod_id, gui, in_main_menu, im_id, setting)
			if GuiButton(gui, im_id, 0, 0, "Respawn all dead players button") then
				ModSettingSet("multiplayer.respawn_all", true)
			end
		end
	  },
	  {
        id = "used_port",
        ui_name = "Used Port",
        ui_description = "Port used to receive inputs from other player.\nYou have to forward to to UDP (router menu) if you are not playing on LAN or locally.\nYou should only use ports 1024 to 49151.\nRestart to the game to apply.",
        value_default = "25565",
		text_max_length = 5,
		allowed_characters = "0123456789",
        scope = MOD_SETTING_SCOPE_RUNTIME_RESTART,
      },
	  {
        id = "player_number",
        ui_name = "Number of players",
        ui_description = "The number of players.\nFor now, splitscreen only works with 2 players.",
        value_default = "2",
		text_max_length = 2,
		allowed_characters = "0123456789",
        scope = MOD_SETTING_SCOPE_RUNTIME,
      },
	  {
		id = "camera",
		ui_name = "Camera type",
		ui_description = "Choose between splitscreen and shared screen.\nSwitching to shared screen will teleport all players to one of them.\nCOMING SOON: N players support for splitscreen (currently 2).",
		value_default = "splitscreen",
		values = { {"splitscreen","Splitscreen"}, {"shared","Shared Screen"}},
		scope = MOD_SETTING_SCOPE_RUNTIME,
	  },
	  {
		id = "zoom",
		ui_name = "Zoom",
		ui_description = "Change the zoom for shared screen. Takes effect on restart.\nIf you are not on default and switch to splitscreen you should restart.\nMay break things permanently even after change back.",
		value_default = "default",
		values = { {"default","Default"}, {"out1","Zoomed out [EXPERIMENTAL]"}, {"out2","Zoomed out max [EXPERIMENTAL]"}},
		scope = MOD_SETTING_SCOPE_RUNTIME_RESTART,
	  },
	  {
        id = "teleport_distance",
        ui_name = "Teleport Distance (Shared Screen)",
        ui_description = "Maximum distance from center before teleport for shared screen mode.\nAround 220 pixels is recommended",
        value_default = 220,
        value_min = 60,
        value_max = 1000,
        scope = MOD_SETTING_SCOPE_RUNTIME,
      },
      {
        id = "perk_mode",
        ui_name = "Perk distribution mode",
        ui_description = "Shared Perks: All alive untransformed players receive picked perks.\nPersonnal Perks: Perks are personnal but all perks from the altar can be picked up",
        value_default = "personnal",
		values = { {"personnal","Personnal Perks"}, {"shared","Shared Perks"}},
        scope = MOD_SETTING_SCOPE_RUNTIME_RESTART,
      },
	  {
		id = "shared_increase",
		ui_name = "Share Maximum Health Increase",
		ui_description = "Choose if players share the increase.",
		value_default = false,
		scope = MOD_SETTING_SCOPE_RUNTIME,
	  },
	  {
		  id = "regen_respawn",
		  ui_name = "Full Health Respawn",
		  ui_description = "All players respawn on pickup.",
		  value_default = true,
		  scope = MOD_SETTING_SCOPE_RUNTIME,
	  },
	  {
		id = "lower_hp",
		ui_name = "Lower max health on death",
		ui_description = "Reduce players max health after respawning by the choosen %.\nYou cannot go lower than 25 max HP",
		value_default = 25,
        value_min = 0,
        value_max = 75,
		scope = MOD_SETTING_SCOPE_RUNTIME,
	  },
	  {
		id = "drop_items",
		ui_name = "Drop items on death",
		ui_description = "Drop items on death if not polymorphed when dying",
		value_default = false,
		scope = MOD_SETTING_SCOPE_RUNTIME,
	  },
	  {
		  id = "shared_regen",
		  ui_name = "Share Full Health Regeneration",
		  ui_description = "All players are fully regenerated on pickup.",
		  value_default = true,
		  scope = MOD_SETTING_SCOPE_RUNTIME,
	  },
	  {
		id = "shared_refresh",
		ui_name = "Share Spell Refresh",
		ui_description = "All players have their spells refreshed on pickup.",
		value_default = true,
		scope = MOD_SETTING_SCOPE_RUNTIME,
	  },
	  {
		id = "disable_poly",
		ui_name = "Disable polymorphing players",
		ui_description = "Polymorphine support is still experimental and can sometimes break everything.\nDisabling it will limit the chance of the mod breaking but make the game a lot easier.",
		value_default = false,
		scope = MOD_SETTING_SCOPE_RUNTIME,
	  },
	  {
		id = "show_hp",
		ui_name = "Show health above players",
		ui_description = "Since the UI is mostly glitched above 2 players, this could be useful.",
		value_default = true,
		scope = MOD_SETTING_SCOPE_RUNTIME,
	  },
	  {
		id = "local_mode",
		ui_name = "Local mode",
		ui_description = "Show player 1 cursor too.\nWill be more useful when inventory is fixed too.",
		value_default = true,
		scope = MOD_SETTING_SCOPE_RUNTIME,
	  }
    }
  }
}

-- This function is called to ensure the correct setting values are visible to the game via ModSettingGet(). your mod's settings don't work if you don't have a function like this defined in settings.lua.
-- This function is called:
--		- when entering the mod settings menu (init_scope will be MOD_SETTINGS_SCOPE_ONLY_SET_DEFAULT)
-- 		- before mod initialization when starting a new game (init_scope will be MOD_SETTING_SCOPE_NEW_GAME)
--		- when entering the game after a restart (init_scope will be MOD_SETTING_SCOPE_RESTART)
--		- at the end of an update when mod settings have been changed via ModSettingsSetNextValue() and the game is unpaused (init_scope will be MOD_SETTINGS_SCOPE_RUNTIME)
function ModSettingsUpdate( init_scope )
	local old_version = mod_settings_get_version( mod_id ) -- This can be used to migrate some settings between mod versions.
	mod_settings_update( mod_id, mod_settings, init_scope )
end

-- This function should return the number of visible setting UI elements.
-- Your mod's settings wont be visible in the mod settings menu if this function isn't defined correctly.
-- If your mod changes the displayed settings dynamically, you might need to implement custom logic.
-- The value will be used to determine whether or not to display various UI elements that link to mod settings.
-- At the moment it is fine to simply return 0 or 1 in a custom implementation, but we don't guarantee that will be the case in the future.
-- This function is called every frame when in the settings menu.
function ModSettingsGuiCount()
	-- if (not DebugGetIsDevBuild()) then --if these lines are enabled, the menu only works in noita_dev.exe.
	-- 	return 0
	-- end

	return mod_settings_gui_count( mod_id, mod_settings )
end

function ModSettingsGui( gui, in_main_menu )
  mod_settings_gui( mod_id, mod_settings, gui, in_main_menu )
end