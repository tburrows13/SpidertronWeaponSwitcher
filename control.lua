--DEFAULT_COLORS = {{100, 100, 100}, {200, 200, 0}, {213, 0, 213}}
MAP_ENTITY_INVENTORY = {["cargo-wagon"] = defines.inventory.cargo_wagon,
                        ["container"] = defines.inventory.chest,
                        ["car"] = defines.inventory.car_trunk,
                        ["character"] = defines.inventory.character_main,
                        ["logistic-container"] = defines.inventory.chest,
                        ["spider-vehicle"] = defines.inventory.car_trunk}

local function contains(array, element, remove)
  for i, value in pairs(array) do
    if value == element then
      if remove then table.remove(array, i) end
      return true
    end
  end
  return false
end

local function get_next_name(name)
  local alt_num = string.sub(name, -1)
  return "spidertron-alt-" .. (alt_num % 5) + 1
end


local function get_remotes(inventory, spidertron, found_remotes, not_connected)
  if spidertron then
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

local function replace_spidertron(previous_spidertron)
  --local previous_spidertron = global.spidertrons[player.index]
  local ammo_data = global.spidertron_saved_data[previous_spidertron.unit_number]
  if not ammo_data then
    -- Perhaps the spidertron was placed before the mod was initialised
    ammo_data = {}
  end
  global.spidertron_saved_data[previous_spidertron.unit_number] = {}

  -- Save previous_spidertron ammo
  local ammo = previous_spidertron.get_inventory(defines.inventory.car_ammo).get_contents()
  ammo_data[previous_spidertron.name] = ammo
  -- Save
  --log("Upgrading spidertron to level " .. name .. " for player " .. player.name)
  log("Replacing spidertron " .. previous_spidertron.name .. " with " .. get_next_name(previous_spidertron.name))
  local name = get_next_name(previous_spidertron.name)


  local last_user = previous_spidertron.last_user
  local spidertron = previous_spidertron.surface.create_entity{
    name = name,
    position = previous_spidertron.position,
    direction = previous_spidertron.direction,
    force = previous_spidertron.force,
    -- Don't set player here or else the previous spidertron item will be inserted into the player's inventory
    fast_replace = true,
    spill = false
  }
  if last_user ~= nil then
    spidertron.last_user = last_user
  end

  -- Copy across ammo
  local previous_ammo = ammo_data[spidertron.name]
  if previous_ammo then
    local ammo_inventory = spidertron.get_inventory(defines.inventory.car_ammo)
    for item_name, count in pairs(previous_ammo) do
      if ammo_inventory then ammo_inventory.insert({name=item_name, count=count})
      else
        spidertron.surface.spill_item_stack(spidertron.position, {name=item_name, count=count})
      end
    end
    ammo_data[spidertron.name] = nil  -- Now that we have retrieved the ammo_data, delete it from storage
  end

  -- Store the ammo_data under the new spidertron's ID
  global.spidertron_saved_data[spidertron.unit_number] = ammo_data

  previous_spidertron.destroy()
  return spidertron
end


local function store_spidertron_data(spidertron)
  -- Eject player if any
  local player = spidertron.get_driver()
  if player then
    spidertron.set_driver(nil)
    --player.teleport(spidertron.position)
  end

  local grid_contents = {}
  if spidertron.grid then
    for _, equipment in pairs(spidertron.grid.equipment) do
      table.insert(grid_contents, {name=equipment.name, position=equipment.position, energy=equipment.energy, shield=equipment.shield})
    end
  end
  --local ammo = spidertron.get_inventory(defines.inventory.car_ammo).get_contents()
  local trunk = spidertron.get_inventory(defines.inventory.car_trunk).get_contents()

  local color = spidertron.color

  local auto_target = spidertron.vehicle_automatic_targeting_parameters
  local autopilot_destination = spidertron.autopilot_destination

  -- Find all connected remotes
  local connected_remotes = {}
  --for _, entity in pairs(surface.find_entities_filtered{type=types}) do
  for _, found_player in pairs(game.players) do
    get_remotes(found_player.get_inventory(defines.inventory.character_main), spidertron, connected_remotes)  -- Adds all remotes connected to spidertron to connected_remotes
    get_remotes(found_player.get_inventory(defines.inventory.character_trash), spidertron, connected_remotes)
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


  --global.spidertron_saved_data[player.index] = {index = player.index, equipment = grid_contents, ammo = ammo, trunk = trunk, color = color}
  return {index = spidertron.unit_number, equipment = grid_contents, trunk = trunk, color = color, auto_target = auto_target, autopilot_destination = autopilot_destination, player = player, connected_remotes = connected_remotes}
end


local function place_stored_spidertron_data(spidertron, saved_data)
  -- Copy across equipment grid
  --log("Placing saved ammo_data back into spidertron: \n" .. serpent.block(saved_data))
  local previous_grid_contents = saved_data.equipment
  if previous_grid_contents then
    local items_to_insert = {}
    for _, equipment in pairs(previous_grid_contents) do
      if spidertron.grid then
        local placed_equipment = spidertron.grid.put( {name=equipment.name, position=equipment.position} )
        if equipment.energy then placed_equipment.energy = equipment.energy end
        if equipment.shield and equipment.shield > 0 then placed_equipment.shield = equipment.shield end
      else 
        spidertron.surface.spill_item_stack(spidertron.position, {name=equipment.name})
      end
    end
  end

  -- Copy across trunk
  local previous_trunk = saved_data.trunk
  local trunk_inventory = spidertron.get_inventory(defines.inventory.car_trunk)
  for name, count in pairs(previous_trunk) do
    if trunk_inventory then trunk_inventory.insert({name=name, count=count})
    else
      spidertron.surface.spill_item_stack(spidertron.position, {name=name, count=count})
    end
  end

  -- Make player's remote point to new spidertron
  --[[ocal remote = get_remote(player, true)
  if remote then
    remote.connected_entity = spidertron
  end
  ]]


  -- Only set the color if it wasn't already a default color
  local color = saved_data.color
  --if not contains(DEFAULT_COLORS, color) then
  spidertron.color = color
  --end

  local auto_target = saved_data.auto_target
  if auto_target then
    spidertron.vehicle_automatic_targeting_parameters = auto_target
  end

  local autopilot_destination = saved_data.autopilot_destination
  if autopilot_destination then
    spidertron.autopilot_destination = autopilot_destination
  end

  local player = saved_data.player
  if player then
    spidertron.set_driver(player)
  end

  -- Reconnect remotes
  for _, remote in pairs(saved_data.connected_remotes) do
    if not remote.valid then
      -- Remote must have been in the spidertron
      remote = get_remotes(trunk_inventory, spidertron, {}, true)
      log("Found not connected remote in spidertron inventory")
    end
    if remote then
      remote.connected_entity = spidertron
    end
  end
end

script.on_event("switch-spidertron-weapons",
  function(event)
    local player = game.get_player(event.player_index)
    log("Switching spidertron weapon")
    local spidertron
    if player.selected and player.selected.type == "spider-vehicle" and string.sub(player.selected.name, 1, 15) == "spidertron-alt-" then
      spidertron = player.selected
    elseif player.vehicle and player.vehicle.type == "spider-vehicle" and string.sub(player.vehicle.name, 1, 15) == "spidertron-alt-" then
      spidertron = player.vehicle
    else return
    end

    local saved_data = store_spidertron_data(spidertron)

    local new_spidertron = replace_spidertron(spidertron)

    place_stored_spidertron_data(new_spidertron, saved_data)
  end
)

script.on_event(defines.events.on_built_entity,
  function(event)
    log("Spidertron Alt built")
    local spidertron = event.created_entity
    global.spidertron_saved_data[spidertron.unit_number] = {}
  end,
  {{filter = "name", name = "spidertron-alt-1"},
   {filter = "name", name = "spidertron-alt-2"},
   {filter = "name", name = "spidertron-alt-3"},
   {filter = "name", name = "spidertron-alt-4"},
   {filter = "name", name = "spidertron-alt-5"},
   {filter = "name", name = "spidertron-alt-6"},
   {filter = "name", name = "spidertron-alt-7"},
   {filter = "name", name = "spidertron-alt-8"},
   {filter = "name", name = "spidertron-alt-9"}}
)

script.on_event(defines.events.on_player_mined_entity,
  function(event)
    local player = game.get_player(event.player_index)
    local spidertron = event.entity
    local buffer = event.buffer
    log("Player " .. player.name .. " mined spidertron")

    for spidertron_name, ammo_stacks in pairs(global.spidertron_saved_data[spidertron.unit_number]) do
      for item_name, item_count in pairs(ammo_stacks) do
        buffer.insert({name = item_name, count = item_count})
      end
    end
  end,
  {{filter = "name", name = "spidertron-alt-1"},
   {filter = "name", name = "spidertron-alt-2"},
   {filter = "name", name = "spidertron-alt-3"},
   {filter = "name", name = "spidertron-alt-4"},
   {filter = "name", name = "spidertron-alt-5"},
   {filter = "name", name = "spidertron-alt-6"},
   {filter = "name", name = "spidertron-alt-7"},
   {filter = "name", name = "spidertron-alt-8"},
   {filter = "name", name = "spidertron-alt-9"}}
)

script.on_init(
  function()
    global.spidertron_saved_data = {}
  end
)