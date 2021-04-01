MAP_ENTITY_INVENTORY = {["cargo-wagon"] = defines.inventory.cargo_wagon,
                        ["container"] = defines.inventory.chest,
                        ["car"] = defines.inventory.car_trunk,
                        ["character"] = defines.inventory.character_main,
                        ["logistic-container"] = defines.inventory.chest,
                        ["spider-vehicle"] = defines.inventory.spider_trunk}


local spidertron_lib = {}

local function get_remotes(inventory, spidertron, found_remotes, not_connected)
  if spidertron and inventory then
    for i = 1, #inventory do
      local item = inventory[i]
      if item.valid_for_read then  -- Check if it isn't an empty inventory slot
        if item.connected_entity == spidertron then
          table.insert(found_remotes, item)
        end
        if not_connected and item.prototype.type == "spidertron-remote" and not item.connected_entity then
          return item
        end
      end
    end
  end
end

local function copy_inventory(old_inventory, inventory, filter_table)
  if not inventory then
    inventory = game.create_inventory(#old_inventory)
  end

  -- Assumes that old_inventory and inventory are not both filterable
  local store_filters = false
  local load_filters = false
  if not filter_table and old_inventory.is_filtered() and not inventory.supports_filters() then
    store_filters = true
    filter_table = {}
  elseif filter_table and inventory.supports_filters() then
    load_filters = true
  end

  -- Find out where to spill excess stacks
  local entity_owner = inventory.entity_owner
  local surface, position
  if entity_owner then
    surface = entity_owner.surface
    position = entity_owner.position
  end

  local newsize = #inventory
  for i = 1, #old_inventory do
    if i <= newsize then
      local transferred = inventory[i].set_stack(old_inventory[i])
      if (not transferred) and surface and position then
        -- If  only part of the stack was transferred then the remainder will be spilled
        surface.spill_item_stack(position, old_inventory[i], true, nil, false)
      end

      -- Can't set filters in script inventories, so must store them separately
      -- See https://forums.factorio.com/viewtopic.php?f=28&t=89674
      if store_filters then
        filter_table[i] = old_inventory.get_filter(i)
      end
      if load_filters then
        inventory.set_filter(i, filter_table[i])
      end
    end
  end
  return {inventory = inventory, filters = filter_table}
end
spidertron_lib.copy_inventory = copy_inventory

local function serialise_burner(burner)
  local serialised_data = {}
  serialised_data.inventory = copy_inventory(burner.inventory).inventory
  serialised_data.burnt_result_inventory = copy_inventory(burner.burnt_result_inventory).inventory
  serialised_data.heat = burner.heat
  serialised_data.currently_burning = burner.currently_burning
  serialised_data.remaining_burning_fuel = burner.remaining_burning_fuel
  serialised_data.serialised_burner = true  -- Allows distinguishing between 'serialised_data' and a LuaBurner (from older version)
  return serialised_data
end

local function deserialise_burner(burner, serialised_data)
  copy_inventory(serialised_data.inventory, burner.inventory)
  copy_inventory(serialised_data.burnt_result_inventory, burner.burnt_result_inventory)
  burner.heat = serialised_data.heat
  burner.currently_burning = serialised_data.currently_burning
  burner.remaining_burning_fuel = serialised_data.remaining_burning_fuel
end


function spidertron_lib.serialise_spidertron(spidertron)
  local serialised_data = {unit_number = spidertron.unit_number}
  serialised_data.name = spidertron.name

  serialised_data.driver_is_gunner = spidertron.driver_is_gunner

  local driver = spidertron.get_driver()
  if driver then
    serialised_data.driver = driver
    serialised_data.walking_state = driver.walking_state
  end

  local passenger = spidertron.get_passenger()
  if passenger then
    serialised_data.passenger = passenger
  end

  serialised_data.force = spidertron.force
  serialised_data.torso_orientation = spidertron.torso_orientation
  serialised_data.last_user = spidertron.last_user
  serialised_data.color = spidertron.color
  serialised_data.entity_label = spidertron.entity_label

  serialised_data.vehicle_logistic_requests_enabled = spidertron.vehicle_logistic_requests_enabled
  serialised_data.enable_logistics_while_moving = spidertron.enable_logistics_while_moving
  serialised_data.vehicle_automatic_targeting_parameters = spidertron.vehicle_automatic_targeting_parameters

  serialised_data.autopilot_destinations = spidertron.autopilot_destinations
  serialised_data.follow_target = spidertron.follow_target
  serialised_data.follow_offset = spidertron.follow_offset
  serialised_data.selected_gun_index = spidertron.selected_gun_index

  serialised_data.health = spidertron.get_health_ratio()


  -- Inventories
  serialised_data.trunk = copy_inventory(spidertron.get_inventory(defines.inventory.spider_trunk))
  serialised_data.ammo = copy_inventory(spidertron.get_inventory(defines.inventory.spider_ammo))
  serialised_data.trash = copy_inventory(spidertron.get_inventory(defines.inventory.spider_trash))

  if spidertron.burner then
    serialised_data.burner = serialise_burner(spidertron.burner)
  end

  -- Equipment grid
  local grid_contents = {}
  if spidertron.grid then
    for _, equipment in pairs(spidertron.grid.equipment) do
      local equipment_data = {name=equipment.name, position=equipment.position, energy=equipment.energy, shield=equipment.shield}
      if equipment.burner then  -- e.g. BurnerGenerator mod
        equipment_data.burner = serialise_burner(equipment.burner)
      end
      table.insert(grid_contents, equipment_data)
    end
  end
  serialised_data.equipment = grid_contents

  -- Logistic request slots
  local logistic_slots = {}
  for i = 1, spidertron.request_slot_count do
    logistic_slots[i] = spidertron.get_vehicle_logistic_slot(i)
  end
  serialised_data.logistic_slots = logistic_slots

  -- Find all connected remotes in player inventories or in radius 30 around all players
  local connected_remotes = {}
  --for _, entity in pairs(surface.find_entities_filtered{type=types}) do
  for _, found_player in pairs(game.players) do
    get_remotes(found_player.get_inventory(defines.inventory.character_main), spidertron, connected_remotes)  -- Adds all remotes connected to spidertron to connected_remotes
    get_remotes(found_player.get_inventory(defines.inventory.character_trash), spidertron, connected_remotes)
    get_remotes(found_player.get_inventory(defines.inventory.god_main), spidertron, connected_remotes)
    get_remotes(found_player.get_inventory(defines.inventory.editor_main), spidertron, connected_remotes)
    get_remotes({found_player.cursor_stack}, spidertron, connected_remotes)

    -- Also check in a radius around the player
    if found_player.character then
      local character = found_player.character
      -- Check train cars, chests, cars, player inventories, and logistics chests.
      local types = {"cargo-wagon", "container", "car", "logistic-container", "spider-vehicle"}
      for _, entity in pairs(character.surface.find_entities_filtered{position=character.position, radius=30, type=types}) do
        if entity.get_item_count("spidertron-remote") > 0 then
          log("Found remotes in entity " .. entity.name .. ". Checking inventory " .. MAP_ENTITY_INVENTORY[entity.type])
          get_remotes(entity.get_inventory(MAP_ENTITY_INVENTORY[entity.type]), spidertron, connected_remotes)  -- Adds all remotes connected to spidertron to connected_remotes
        end
      end
    end
  end
  serialised_data.connected_remotes = connected_remotes

  -- Store which players had this spidertron's GUI open
  local players_with_gui_open = {}
  for _, player in pairs(game.connected_players) do
    if player.opened == spidertron then
      table.insert(players_with_gui_open, player)
    end
  end
  serialised_data.players_with_gui_open = players_with_gui_open

  return serialised_data
end


function spidertron_lib.deserialise_spidertron(spidertron, serialised_data, transfer_player_state)
  -- Copy all data in serialised_data into spidertron
  -- Set `serialised_data` fields to `nil` to prevent that attribute of `spidertron` being overwritten

  -- transfer_player_state keeps driver/passenger in spidertron, player.opened and player.walking_state intact
  -- and should be used when the mod is serialising and deserialising the spidertron on the same tick

  -- Copy across generic attributes
  for _, attribute in pairs{"force",
                            "torso_orientation",
                            "last_user",
                            "color",
                            "entity_label",
                            "vehicle_logistic_requests_enabled",
                            "enable_logistics_while_moving",
                            "vehicle_automatic_targeting_parameters",
                            "follow_target",
                            "follow_offset",
                            "selected_gun_index"} do
    local value = serialised_data[attribute]
    if value ~= nil then
      spidertron[attribute] = value
    end
  end

  -- Add each autopilot destination separately
  local autopilot_destinations = serialised_data.autopilot_destinations
  if autopilot_destinations then
    for _, position in pairs(autopilot_destinations) do
      spidertron.add_autopilot_destination(position)
    end
  end

  local driver_is_gunner = serialised_data.driver_is_gunner
  if driver_is_gunner ~= nil then
    spidertron.driver_is_gunner = driver_is_gunner
  end

  -- Copy across health
  local health_ratio = serialised_data.health
  if health_ratio then
    spidertron.health = health_ratio * spidertron.prototype.max_health
  end

  -- Copy across trunk
  local previous_trunk = serialised_data.trunk
  if previous_trunk then
    local new_trunk = spidertron.get_inventory(defines.inventory.spider_trunk)
    copy_inventory(previous_trunk.inventory, new_trunk, previous_trunk.filters)
    previous_trunk.inventory.destroy()
  end

  -- Copy across ammo
  local previous_ammo = serialised_data.ammo
  if previous_ammo then
    local new_ammo = spidertron.get_inventory(defines.inventory.spider_ammo)
    copy_inventory(previous_ammo.inventory, new_ammo, previous_ammo.filters)
    previous_ammo.inventory.destroy()
  end

  -- Copy across trash
  local previous_trash = serialised_data.trash
  if previous_trash then
    local new_trash = spidertron.get_inventory(defines.inventory.spider_trash)
    copy_inventory(previous_trash.inventory, new_trash, previous_trash.filters)
    previous_trash.inventory.destroy()
  end

  -- Copy across fuel, remaining_burning_fuel, etc (for modded spidertrons that use fuel)
  local burner = serialised_data.burner
  if burner then
    deserialise_burner(spidertron.burner, burner)
  end

  -- Copy across logistic request slots
  local logistic_slots = serialised_data.logistic_slots
  if logistic_slots then
    for i, slot in pairs(logistic_slots) do
      spidertron.set_vehicle_logistic_slot(i, slot)
    end
  end

  -- Copy across equipment grid
  local previous_grid_contents = serialised_data.equipment
  local spidertron_grid = spidertron.grid
  if previous_grid_contents then
    for _, equipment in pairs(previous_grid_contents) do
      if spidertron_grid then
        local placed_equipment = spidertron_grid.put( {name=equipment.name, position=equipment.position} )
        if placed_equipment then
          if equipment.energy then placed_equipment.energy = equipment.energy end
          if equipment.shield and equipment.shield > 0 then placed_equipment.shield = equipment.shield end
          if equipment.burner and equipment.burner.serialised_burner then
            -- Extra check for .serialised_burner to differentiate with legacy version below
            deserialise_burner(placed_equipment.burner, equipment.burner)
          elseif equipment.burner then
            -- Legacy alternative
            copy_inventory(equipment.burner_inventory, placed_equipment.burner.inventory)
            copy_inventory(equipment.burner_burnt_result_inventory, placed_equipment.burner.burnt_result_inventory)
            if equipment.heat then placed_equipment.burner.heat = equipment.burner_heat end
            placed_equipment.burner.currently_burning = equipment.burner_currently_burning
            placed_equipment.burner.remaining_burning_fuel = equipment.burner_remaining_burning_fuel
          end
        else  -- No space in the grid because we have moved to a smaller grid
          spidertron.surface.spill_item_stack(spidertron.position, {name=equipment.name})
        end
      else   -- No space in the grid because the grid has gone entirely
        spidertron.surface.spill_item_stack(spidertron.position, {name=equipment.name})
      end
    end
  end

  -- Reconnect remotes
  local connected_remotes = serialised_data.connected_remotes
  if connected_remotes then
    for _, remote in pairs(connected_remotes) do
      if remote and remote.valid_for_read and remote.prototype.type == "spidertron-remote" then
        remote.connected_entity = spidertron
      end
    end
  end

  if transfer_player_state then
    -- Copy across driving state
    local driver = serialised_data.driver or serialised_data.player_occupied  -- Legacy
    -- driver is a character, not player
    if driver and driver.valid then
      spidertron.set_driver(driver)
    end
    -- `spidertron` could be invalid here because `.set_driver` raises an event that other mods can react to
    if not spidertron.valid then
      return  -- Will probably still crash calling function...
    end

    local passenger = serialised_data.passenger
    if passenger and passenger.valid then
      spidertron.set_passenger(passenger)
    end
    -- Same check again here
    if not spidertron.valid then
      return
    end

    local walking_state = serialised_data.walking_state
    if driver and driver.valid and walking_state then
      driver.player.walking_state = walking_state
    end

    local players_with_gui_open = serialised_data.players_with_gui_open
    if players_with_gui_open then
      -- Reopen the new GUI for players that had the old one open
      for _, player in pairs(players_with_gui_open) do
        if player.valid then
          player.opened = spidertron
        end
      end
    end
  end

end

return spidertron_lib