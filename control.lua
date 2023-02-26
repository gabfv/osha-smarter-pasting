require "scripts.functions"
local mod_gui = require "mod-gui"

script.on_event(defines.events.on_entity_settings_pasted, osp_paste)

script.on_event(defines.events.on_player_created, function(e)
    osp_load_default_settings(game.players[e.player_index])
    osp_establish_gui(game.players[e.player_index], mod_gui)
end)

script.on_init(function() 
	for _, player in pairs(game.players) do
		osp_load_default_settings(player)
		osp_establish_gui(player, mod_gui)
	end
end)

--[[
script.on_event(defines.events.on_gui_opened, function(e)
    osp_load_default_settings(game.players[e.player_index])
    osp_establish_gui(game.players[e.player_index], mod_gui)
end)

script.on_load(function() 
	for _, player in pairs(game.players) do
		osp_load_default_settings(player)
		osp_establish_gui(player, mod_gui)
	end
end)
]]

script.on_configuration_changed(function() 
	for _, player in pairs(game.players) do
		osp_load_default_settings(player)
		osp_establish_gui(player, mod_gui)
	end
end)

script.on_event(defines.events.on_gui_click, function(event)
    local player = game.players[event.player_index]
    if event.element.name == 'osp-menu-button' then
        -- toggle menu
        if player.gui.screen['osp-main-container'].visible then
            player.gui.screen['osp-main-container'].visible = false
        else
            player.gui.screen['osp-main-container'].visible = true
        end
    end
end)

script.on_event(defines.events.on_gui_selection_state_changed, function(event)
    local name = event.element.name
    local player = game.players[event.player_index]

    if (name == 'osp-requester-size') then
    	local settings = osp_get_user_mod_settings(player)
    	settings.paste_ingredient_size = event.element.selected_index
    	osp_save_user_mod_settings(player, settings)
    elseif (name == 'osp-container-size') then
    	local settings = osp_get_user_mod_settings(player)
    	settings.paste_inserter_limit = event.element.selected_index
    	osp_save_user_mod_settings(player, settings)
    end
end)