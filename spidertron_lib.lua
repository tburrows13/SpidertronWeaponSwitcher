
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


function spidertron_lib.serialise_spidertron(spidertron)
  local serialised_data = {unit_number = spidertron.unit_number}

  -- Eject player if any
  local player = spidertron.get_driver()
  if player then
    spidertron.set_driver(nil)
    --player.teleport(spidertron.position)
    serialised_data.player_occupied = player
  end

  serialised_data.force = spidertron.force
  serialised_data.direction = spidertron.direction
  serialised_data.last_user = spidertron.last_user
  serialised_data.color = spidertron.color
  -- serialised_data["name"] = spidertron.name

  serialised_data.vehicle_automatic_targeting_parameters = spidertron.vehicle_automatic_targeting_parameters
  serialised_data.autopilot_destination = spidertron.autopilot_destination
  serialised_data.follow_target = spidertron.follow_target
  serialised_data.follow_offset = spidertron.follow_offset

  serialised_data.health = spidertron.get_health_ratio()

  serialised_data.trunk = copy_inventory(spidertron.get_inventory(defines.inventory.spider_trunk))
  serialised_data.ammo = copy_inventory(spidertron.get_inventory(defines.inventory.spider_ammo))

  local grid_contents = {}
  if spidertron.grid then
    for _, equipment in pairs(spidertron.grid.equipment) do
      local equipment_data = {name=equipment.name, position=equipment.position, energy=equipment.energy, shield=equipment.shield, burner=equipment.burner}
      if equipment.burner then  -- e.g. BurnerGenerator mod
        equipment_data.burner_inventory = copy_inventory(equipment.burner.inventory).inventory
        equipment_data.burner_burnt_result_inventory = copy_inventory(equipment.burner.burnt_result_inventory).inventory
        equipment_data.burner_burner_heat = equipment.burner.heat
        equipment_data.burner_currently_burning = equipment.burner.currently_burning
        equipment_data.burner_remaining_burning_fuel = equipment.burner.remaining_burning_fuel
      end
      table.insert(grid_contents, equipment_data)
    end
  end
  serialised_data.equipment = grid_contents


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

  return serialised_data
end


function spidertron_lib.deserialise_spidertron(spidertron, serialised_data)
  -- Copy all data in serialised_data into spidertron
  -- Set `serialised_data` fields to `nil` to prevent that attribute of `spidertron` being overwritten


  -- Copy across generic attributes
  for _, attribute in pairs{"force",
                            "direction",
                            "last_user",
                            "color",
                            "vehicle_automatic_targeting_parameters",
                            "autopilot_destination",
                            "follow_target",
                            "follow_offset"} do
    local value = serialised_data[attribute]
    if value then
      spidertron[attribute] = value
    end
  end

  -- Copy across driving state
  local player = serialised_data.player_occupied
  if player then
    spidertron.set_driver(player)
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
    local new_ammo = spidertron.get_inventory(defines.inventory.spider_trunk)
    copy_inventory(previous_ammo.inventory, new_ammo, previous_ammo.filters)
    previous_ammo.inventory.destroy()
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
          if equipment.burner then
            copy_inventory(equipment.burner_inventory, placed_equipment.burner.inventory)
            copy_inventory(equipment.burner_burnt_result_inventory, placed_equipment.burner.burnt_result_inventory)
            if equipment.heat then placed_equipment.burner.heat = equipment.burner_heat end
            placed_equipment.burner.currently_burning = equipment.burner_currently_burning
            placed_equipment.burner.remaining_burning_fuel = equipment.burner_remaining_burning_fuel
          end
        else  -- No space in the grid because we have moved to a smaller grid
          player.surface.spill_item_stack(spidertron.position, {name=equipment.name})
        end
      else   -- No space in the grid because we have 'upgraded' to no grid
        player.surface.spill_item_stack(spidertron.position, {name=equipment.name})
      end
    end
  end

  -- Reconnect remotes
  local connected_remotes = serialised_data.connected_remotes
  if connected_remotes then
    for _, remote in pairs(connected_remotes) do
      if remote and remote.valid_for_read then
        remote.connected_entity = spidertron
      end
    end
  end
end

return spidertron_lib