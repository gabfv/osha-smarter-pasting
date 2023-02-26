

function osp_paste(event)
	local source = event.source
	local destination = event.destination
	local player = game.players[event.player_index]
	local settings = osp_get_user_mod_settings(player)

	if (destination.type == 'logistic-container') and (source.type == 'assembling-machine') then
		-- we don't want filter/stack filter inserters to do anything other than what they normally would
		if (destination.request_slot_count > 0) then
			local machine     = source
			local recipe      = machine.get_recipe()
			local ingredients = recipe.ingredients
			local i = 1
			for _, ingredient in pairs(ingredients) do
				local amount = ingredient.amount
				local count

				if (settings.paste_ingredient_size == 1) then
					count = 1
				elseif (settings.paste_ingredient_size == 2) then
					count = math.ceil(amount/2)
				elseif (settings.paste_ingredient_size == 3) then
					count = amount
				elseif (settings.paste_ingredient_size == 4) then
					count = 2 * amount
				elseif (settings.paste_ingredient_size == 5) then
					count = 5 * amount
				else
					count = amount
				end

				local request = {
					name  = ingredient.name,
					count = count
				}

				destination.set_request_slot(request, i)
				i = i + 1
			end
		end
	end

	if (source.type == 'assembling-machine') and (destination.type == 'inserter') then
		-- see what sort of container we're putting this into
		local inserter = destination
		local machine = source

		local recipe = machine.get_recipe()
		local products = recipe.products
		local first_product = products[1]

		if (inserter.prototype.filter_count > 0) then osp_paste_to_filter_inserter(event); return end

		local position = inserter.drop_position
		local nearby = inserter.surface.find_entities_filtered({
	    	position = position,
	    	type = {'container', 'logistic-container'},
	    	limit = 1
	    });

	    if (#nearby > 0) then
	    	local container = nearby[1] -- should only ever have 1

	    	local stack_size = game.item_prototypes[first_product.name].stack_size
	    	local limit

	    	if (settings.paste_inserter_limit == 1) then
	    		limit = 1
	    	elseif (settings.paste_inserter_limit == 2) then
	    		limit = 5
	    	elseif (settings.paste_inserter_limit == 3) then
	    		limit = 10
	    	elseif (settings.paste_inserter_limit == 4) then
	    		limit = math.ceil(stack_size / 2)
	    	elseif (settings.paste_inserter_limit == 5) then
	    		limit = stack_size
	    	else
	    		limit = stack_size * 2
	    	end

	    	-- build conditional to use for target containers
		    local inserter_condition = {}
			inserter_condition.condition = {}
			inserter_condition.condition.first_signal = {}
			inserter_condition.condition.first_signal.type = 'item'
			inserter_condition.condition.first_signal.name = first_product.name
			inserter_condition.condition.constant = limit;

	   		if (container.type == 'logistic-container') then
	   			-- logistc container, connect to network, update condition
	   			local control = inserter.get_or_create_control_behavior()
	   			control.connect_to_logistic_network = true
	   			control.logistic_condition = inserter_condition
	   		end

	   		if (container.type == 'container') then
	   			-- non-logistic container, connect to container via wire, then set condition
	   			-- first disconnect existing wires
	   			inserter.disconnect_neighbour(defines.wire_type.green)
	   			inserter.disconnect_neighbour(defines.wire_type.red)

	   			-- connect green wire
	   			local connection = {}
	   			connection.wire = defines.wire_type.green
	   			connection.target_entity = container
	   			inserter.connect_neighbour(connection)

	   			-- add conditional to inserter
	   			local control = inserter.get_or_create_control_behavior()
	   			control.circuit_condition = inserter_condition
	   		end
	    end
	end
end

function osp_paste_to_filter_inserter(event)
	local machine  = event.source
	local inserter = event.destination

	-- for some dumb reason, when copy/pasting from an assembly machine to an inserter and the inserter is pointed away, it is finding the 
	-- inserter's ingredients, not products

	local position = inserter.drop_position
	local nearby = inserter.surface.find_entities_filtered({
    	position = position,
    	type = {'container', 'logistic-container'},
    	limit = 1
    });

    if (#nearby > 0) then
    	-- put the PRODUCTS as the filters for the inserter

    	local recipe = machine.get_recipe()
		local products = recipe.products
		local num_slots = inserter.prototype.filter_count 

		local x = 0
		for _, product in pairs(products) do
			if (x < num_slots) then
				if (product.type == 'item') then
					local item_name = product.name
					inserter.set_filter(x+1, item_name)
					x = x + 1
				end
			end
		end

		while (x < num_slots) do
			inserter.set_filter(x+1, nil)
			x = x + 1
		end
    end
end

function osp_load_default_settings(player)
	local settings = {}
	if (settings.paste_ingredient_size == nil) then settings.paste_ingredient_size = 1 end
	if (settings.paste_inserter_limit == nil) then settings.paste_inserter_limit = 1 end
	osp_save_user_mod_settings(player, settings)
end

function osp_establish_gui(player, mod_gui)
	if (player.gui.left['osp-main-container']) then
        player.gui.left['osp-main-container'].destroy()
    end

    if (player.gui.screen['osp-main-container']) then
        player.gui.screen['osp-main-container'].destroy()
    end

	local screen_element = player.gui.screen
    local main_frame = screen_element.add{type="frame", name="osp-main-container", caption={"osp.main-title"}}
    main_frame.style.size = {400, 120}
    main_frame.auto_center = true

	local button_flow = mod_gui.get_button_flow(player)

    if not button_flow['osp-menu-button'] then
        local menu_button = button_flow.add {
            type = "button",
            name = "osp-menu-button",
            style = mod_gui.button_style,
            caption = {"osp.menu-button-text"},
            tooltip = {"osp.menu-button-tt"}
        }

        menu_button.visible = true
    end

    local main_table = main_frame.add({
        type="table",
        name="osp-main-container-table",
        column_count=2
    })

    local settings = osp_get_user_mod_settings(player)

    main_table.add({
    	type="label",
    	caption={'osp.requester-chest-stack-size'}
    })
    main_table.add({
    	type="drop-down",
    	name="osp-requester-size",
    	items={
    		{'osp.requester-stack-size-option-1'},
    		{'osp.requester-stack-size-option-2'},
    		{'osp.requester-stack-size-option-3'},
    		{'osp.requester-stack-size-option-4'},
    		{'osp.requester-stack-size-option-5'},
    		{'osp.requester-stack-size-option-6'}
    	},
    	selected_index=settings.paste_ingredient_size,
    	allow_none_state=false
    })
    main_table.add({
    	type="label",
    	caption={'osp.chest-limit-size'}
    })
    main_table.add({
    	type="drop-down",
    	name="osp-container-size",
    	items={
    		{'osp.chest-limit-1'},
    		{'osp.chest-limit-2'},
    		{'osp.chest-limit-3'},
    		{'osp.chest-limit-4'},
    		{'osp.chest-limit-5'},
    		{'osp.chest-limit-6'}
    	},
    	selected_index=settings.paste_inserter_limit,
    	allow_none_state=false
    })

end

-- get a player's settings for this mod
function osp_get_user_mod_settings(player)
    if not global.osp_user_mod_settings then
        global.osp_user_mod_settings = {}
        global.osp_user_mod_settings.players = {}
    end

    if not global.osp_user_mod_settings.players[player.index] then
        global.osp_user_mod_settings.players[player.index] = osp_load_default_settings(player)
    end

    return global.osp_user_mod_settings.players[player.index]
end

function osp_save_user_mod_settings(player, settings)
	if not global.osp_user_mod_settings then
        global.osp_user_mod_settings = {}
        global.osp_user_mod_settings.players = {}
    end
    global.osp_user_mod_settings.players[player.index] = settings
end

function find_jackson() 
	for id, player in pairs(game.players) do
		if (player.name == 'OSHA-Jackson') then
			return player
		end
	end
	return nil
end

function msg(message) 
    local jackson = find_jackson()
    if (jackson ~= nil) then
    	jackson.print(message)
    else
    	game.players[1].print(message)
    end
end