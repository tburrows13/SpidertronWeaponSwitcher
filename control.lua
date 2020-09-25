require 'util'

--DEFAULT_COLORS = {{100, 100, 100}, {200, 200, 0}, {213, 0, 213}}
MAP_ENTITY_INVENTORY = {["cargo-wagon"] = defines.inventory.cargo_wagon,
                        ["container"] = defines.inventory.chest,
                        ["car"] = defines.inventory.car_trunk,
                        ["character"] = defines.inventory.character_main,
                        ["logistic-container"] = defines.inventory.chest,
                        ["spider-vehicle"] = defines.inventory.car_trunk}

SWITCH_CHAINS = {
{
  "sws-spidertron-spidertron-machine-gun",
  "sws-spidertron-spidertron-shotgun",
  "sws-spidertron-spidertron-flamethrower",
  "spidertron",
  "sws-spidertron-tank-cannon"
},{
  "sws-spidertronmk2-sws-machine-gun-mk2",
  "sws-spidertronmk2-sws-shotgun-mk2",
  "sws-spidertronmk2-sws-flamethrower-mk2",
  "spidertronmk2",
  "sws-spidertronmk2-tank-cannon"
},{
  "sws-spidertronmk3-sws-machine-gun-mk3",
  "sws-spidertronmk3-sws-shotgun-mk3",
  "sws-spidertronmk3-sws-flamethrower-mk3",
  "spidertronmk3",
  "sws-spidertronmk3-tank-cannon"
}}

on_spidertron_switched = script.generate_event_name()  -- Called
remote.add_interface("SpidertronWeaponSwitcher", {get_events = function() return {on_spidertron_switched = on_spidertron_switched} end})


local function get_next_name(current_name)
  for _, chain in pairs(SWITCH_CHAINS) do
    for i, name in pairs(chain) do
      if name == current_name then
        return chain[(i % #chain) + 1]
      end
    end
  end
end


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

  local newsize = #inventory
  for i = 1, #old_inventory do
    if i <= newsize then
      inventory[i].transfer_stack(old_inventory[i])
      --[[ Doesn't work - requires https://forums.factorio.com/viewtopic.php?f=28&t=89674
      if old_inventory.supports_filters() and inventory.supports_filters() then
        local filter = old_inventory.get_filter(i)
        if filter then
          inventory.set_filter(i, filter)
        end
      end
      ]]
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


local function replace_spidertron(previous_spidertron, name)
  --local previous_spidertron = global.spidertrons[player.index]
  local previous_unit_number = previous_spidertron.unit_number
  local ammo_data = global.spidertron_saved_data[previous_unit_number]
  if not ammo_data then
    -- Perhaps the spidertron was placed before the mod was initialised
    ammo_data = {}
  end
  global.spidertron_saved_data[previous_spidertron.unit_number] = {}

  -- Save previous_spidertron ammo
  local ammo = copy_inventory(previous_spidertron.get_inventory(defines.inventory.car_ammo)).inventory
  ammo_data[previous_spidertron.name] = ammo

  -- Store which players had the old GUI open
  local players_with_gui_open = {}
  for _, player in pairs(game.connected_players) do
    if player.opened == previous_spidertron then
      table.insert(players_with_gui_open, player)
    end
  end

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

  -- Reopen the new GUI for players that had the old one open
  for _, player in pairs(players_with_gui_open) do
    player.opened = spidertron
  end

  -- Copy across ammo
  local previous_ammo = ammo_data[spidertron.name]
  if previous_ammo then
    copy_inventory(previous_ammo, spidertron.get_inventory(defines.inventory.car_ammo))
    previous_ammo.destroy()
    ammo_data[spidertron.name] = nil  -- Now that we have retrieved the ammo_data, delete it from storage
  end

  -- Store the ammo_data under the new spidertron's ID
  global.spidertron_saved_data[spidertron.unit_number] = ammo_data
  global.spidertron_saved_data[previous_unit_number] = nil

  -- Raise event so that other mods can handle the change
  script.raise_event(on_spidertron_switched, {previous_spidertron_unit_number = previous_unit_number, new_spidertron = spidertron})

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

  local trunk = copy_inventory(spidertron.get_inventory(defines.inventory.car_trunk))

  local color = spidertron.color

  local auto_target = spidertron.vehicle_automatic_targeting_parameters
  local autopilot_destination = spidertron.autopilot_destination

  -- Find all connected remotes
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
        end
      end
    end
  end

  -- Copy across trunk
  local trunk_inventory = spidertron.get_inventory(defines.inventory.car_trunk)
  copy_inventory(saved_data.trunk.inventory, trunk_inventory, saved_data.trunk.filters)
  saved_data.trunk.inventory.destroy()

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
    local spidertron
    if player.selected and player.selected.type == "spider-vehicle" then
      spidertron = player.selected
    elseif player.vehicle and player.vehicle.type == "spider-vehicle" then
      spidertron = player.vehicle
    else
      return
    end

    local next_name = get_next_name(spidertron.name)
    if next_name then
      log("Switching from " .. spidertron.name .. " to " .. next_name)
      local saved_data = store_spidertron_data(spidertron)

      local new_spidertron = replace_spidertron(spidertron, next_name)

      place_stored_spidertron_data(new_spidertron, saved_data)
    else
      log("No next name found for spidertron " .. spidertron.name)
    end
  end
)

script.on_event(defines.events.on_built_entity,
  function(event)
    log("Spidertron Alt built")
    local spidertron = event.created_entity
    if get_next_name(spidertron.name) then
      -- Checks that it is a spidertron that we care about
      global.spidertron_saved_data[spidertron.unit_number] = {}
    end
  end,
  {{filter = "type", type = "spider-vehicle"}}
)

script.on_event(defines.events.on_player_mined_entity,
  function(event)
    local player = game.get_player(event.player_index)
    local spidertron = event.entity
    local buffer = event.buffer

    if get_next_name(spidertron.name) then
      -- Checks that it is a spidertron that we care about
      log("Player " .. player.name .. " mined spidertron")

      for spidertron_name, ammo_inventory in pairs(global.spidertron_saved_data[spidertron.unit_number]) do
        for i = 1, #ammo_inventory do
          buffer.insert(ammo_inventory[i])
        end
      end
    end
  end,
  {{filter = "type", type = "spider-vehicle"}}
)

script.on_init(
  function()
    global.spidertron_saved_data = {}
  end
)

local function config_changed_setup(changed_data)
  -- Only run when this mod was present in the previous save as well. Otherwise, on_init will run.
  local mod_changes = changed_data.mod_changes
  local old_version
  if mod_changes and mod_changes["SpidertronWeaponSwitcher"] and mod_changes["SpidertronWeaponSwitcher"]["old_version"] then
    old_version = mod_changes["SpidertronWeaponSwitcher"]["old_version"]
  else
    return
  end

  log("Coming from old version: " .. old_version)
  old_version = util.split(old_version, ".")
  for i=1,#old_version do
    old_version[i] = tonumber(old_version[i])
  end

  if old_version[1] == 1 then
    if old_version[2] <= 1 and old_version[3] < 2 then
      log("Running pre 1.1.2 migration")
      -- Convert inventory.get_contents() to script inventory and migrate prototype names
      local new_name = {["spidertron-alt-1"] = "sws-spidertron-spidertron-machine-gun",
                        ["spidertron-alt-2"] = "sws-spidertron-spidertron-shotgun",
                        ["spidertron-alt-3"] = "sws-spidertron-spidertron-flamethrower",
                        ["spidertron-alt-4"] = "spidertron",
                        ["spidertron-alt-5"] = "sws-spidertron-tank-cannon"
                      }
      for unit_number, ammo_data in pairs(global.spidertron_saved_data) do
        local new_ammo_data = {}
        for spidertron_name, previous_ammo in pairs(ammo_data) do
          local ammo_inventory = game.create_inventory(500)
          for name, count in pairs(previous_ammo) do
            ammo_inventory.insert({name=name, count=count})
          end
          new_ammo_data[new_name[spidertron_name]] = ammo_inventory
        end
        global.spidertron_saved_data[unit_number] = new_ammo_data
      end

    end
  end
end
script.on_configuration_changed(config_changed_setup)

