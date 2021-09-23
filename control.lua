require 'util'
require 'utils'
spidertron_lib = require 'spidertron_lib'

--DEFAULT_COLORS = {{100, 100, 100}, {200, 200, 0}, {213, 0, 213}}

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

  -- Save previous_spidertron ammo
  local ammo = spidertron_lib.copy_inventory(previous_spidertron.get_inventory(defines.inventory.spider_ammo)).inventory
  ammo_data[previous_spidertron.name] = ammo

  local spidertron = previous_spidertron.surface.create_entity{
    name = name,
    position = previous_spidertron.position,
    -- Don't set player here or else the previous spidertron item will be inserted into the player's inventory
    fast_replace = true,
    spill = false
  }

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
      spidertron_lib.deserialise_spidertron(new_spidertron, saved_data, true)

      -- Find and reconnect all following spidertrons.
      -- Filter out ones that have since had their commands changed or cancelled
      local follow_list = global.spidertron_follow_list[spidertron.unit_number]
      if follow_list then
        for i, follower in pairs(follow_list) do
          if follower and follower.valid then
            local follow_target = follower.follow_target
            if follow_target and follow_target.valid and follow_target.unit_number == spidertron.unit_number then
              -- If the follower still exists and it is still following the old spidertron, make it follow the new one
              follower.follow_target = new_spidertron
            else
              follow_list[i] = nil
            end
          end
        end
      end
      global.spidertron_follow_list[new_spidertron.unit_number] = follow_list
      global.spidertron_follow_list[spidertron.unit_number] = nil

      -- Raise event so that other mods can handle the change
      script.raise_event(on_spidertron_switched, {old_spidertron = spidertron, new_spidertron = new_spidertron})

      -- If changed spidertron was following another spidertron then we need to ensure that it has been added to the correct reverse lookup table
      add_to_follow_list(new_spidertron)

      spidertron.destroy()

    else
      log("No next name found for spidertron " .. spidertron.name)
    end
  end
)

script.on_event(defines.events.on_player_mined_entity,
  function(event)
    local player = game.get_player(event.player_index)
    local spidertron = event.entity
    local buffer = event.buffer

    if get_next_name(spidertron.name) then
      -- Checks that it is a spidertron that we care about
      log("Player " .. player.name .. " mined spidertron")

      ammo_data = global.spidertron_saved_data[spidertron.unit_number]
      if ammo_data then
        for _, ammo_inventory in pairs(ammo_data) do
          for i = 1, #ammo_inventory do
            buffer.insert(ammo_inventory[i])
          end
        end
      end
    end
  end,
  {{filter = "type", type = "spider-vehicle"}}
)

function add_to_follow_list(spidertron)
  local target = spidertron.follow_target
  if target and target.type == "spider-vehicle" then
    local follow_list = global.spidertron_follow_list[target.unit_number] or {}
    if not contains(follow_list, spidertron) then
      table.insert(follow_list, spidertron)
    end
    global.spidertron_follow_list[target.unit_number] = follow_list
  end

end

script.on_event(defines.events.on_player_used_spider_remote,
  function(event)
    if event.success then
      add_to_follow_list(event.vehicle)
    end
  end
)

script.on_init(
  function()
    global.spidertron_saved_data = {}
    global.spidertron_follow_list = {}
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

    if old_version[2] < 2 then
      log("Running pre 1.2.0 migration")
      global.spidertron_follow_list = {}
    end
  end
end
script.on_configuration_changed(config_changed_setup)

