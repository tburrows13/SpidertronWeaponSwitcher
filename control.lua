require 'util'
spidertron_lib = require 'spidertron_lib'

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


local function replace_spidertron(previous_spidertron, name)
  local previous_unit_number = previous_spidertron.unit_number
  local ammo_data = global.spidertron_saved_data[previous_unit_number]
  if not ammo_data then
    -- Perhaps the spidertron was placed before the mod was initialised
    ammo_data = {}
  end
  global.spidertron_saved_data[previous_spidertron.unit_number] = {}  -- TODO remove?

  -- Save previous_spidertron ammo
  local ammo = spidertron_lib.copy_inventory(previous_spidertron.get_inventory(defines.inventory.spider_ammo)).inventory
  ammo_data[previous_spidertron.name] = ammo

  -- Store which players had the old GUI open
  local players_with_gui_open = {}
  for _, player in pairs(game.connected_players) do
    if player.opened == previous_spidertron then
      table.insert(players_with_gui_open, player)
    end
  end

  local spidertron = previous_spidertron.surface.create_entity{
    name = name,
    position = previous_spidertron.position,
    -- Don't set player here or else the previous spidertron item will be inserted into the player's inventory
    fast_replace = true,
    spill = false
  }

  -- Reopen the new GUI for players that had the old one open
  for _, player in pairs(players_with_gui_open) do
    player.opened = spidertron
  end

  -- Copy across ammo
  local previous_ammo = ammo_data[spidertron.name]
  if previous_ammo then
    spidertron_lib.copy_inventory(previous_ammo, spidertron.get_inventory(defines.inventory.spider_ammo))
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
      local saved_data = spidertron_lib.serialise_spidertron(spidertron)

      local new_spidertron = replace_spidertron(spidertron, next_name)

      -- Stop the deserialiser overwriting the ammo contents with what the spidertron previously had
      saved_data.ammo = nil
      spidertron_lib.deserialise_spidertron(new_spidertron, saved_data)
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

