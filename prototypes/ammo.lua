--[[
  Changes cannon and shotgun shells so that they work with variable range guns.
  See https://forums.factorio.com/viewtopic.php?p=553077#p553077 for explanations.
]]

local ranges = {["cannon-shell"] = 50,
                ["shotgun-shell"] = 40,
}

local function deal_with_action_delivery(action_delivery, range)
  if action_delivery.type == "projectile" then
    if range > (action_delivery.max_range or 1000) then
      action_delivery.max_range = range
    end
    local projectile_name = action_delivery.projectile
    local projectile = data.raw["projectile"][projectile_name]
    projectile.direction_only = false
  end
end


local function deal_with_action(action, range)
  if action.type == "direct" then
    local action_delivery = action.action_delivery
    if action_delivery.type then
      deal_with_action_delivery(action_delivery, range)
    elseif action_delivery[1] then
      for _, individual_action_delivery in pairs(action_delivery) do
        deal_with_action_delivery(individual_action_delivery, range)
      end
    end
  end

end

local function deal_with_ammo_type(ammo_type)
  local range = ranges[ammo_type.category]
  if range then
    if ammo_type.target_type == "direction" then
      ammo_type.target_type = "position"
      ammo_type.clamp_position = true
    end

    local action = ammo_type.action
    if action.type then
      deal_with_action(action, range)
    elseif action[1] then
      for _, individual_action in pairs(action) do
        deal_with_action(individual_action, range)
      end
    end
  end

end

for _, prototype in pairs(data.raw["ammo"]) do
  local ammo_type = prototype.ammo_type
  if ammo_type.category then
    deal_with_ammo_type(ammo_type)
  elseif ammo_type[1] then
    -- ammo_type is an array
    for _, individual_ammo_type in pairs(ammo_type) do
      deal_with_ammo_type(individual_ammo_type)
    end
  end
end