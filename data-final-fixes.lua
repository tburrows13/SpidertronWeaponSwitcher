local collision_mask_util = require("__core__.lualib.collision-mask-util")
local insert = table.insert

-- Stop cannon-projectile colliding with spider-legs
-- Spider-legs default mask = {"player-layer", "rail-layer"}; With SE = {"player-layer", "rail-layer", "water-layer", "object-layer"}
-- Projectile's default hit_collision_mask = {"player-layer", "train-layer"}; With SE = same
-- Add an extra layer to every prototype with collision mask of player-layer except spider-leg

local collision_layer = "player-layer"  -- In both spider-legs and projectiles
local spider_leg_layer = collision_mask_util.get_first_unused_layer()
log("SWS spider_leg_layer assigned to " .. spider_leg_layer)

local prototypes = collision_mask_util.collect_prototypes_with_layer(collision_layer)

for _, prototype in pairs(prototypes) do
  local prototype_mask = collision_mask_util.get_mask(prototype)
  if prototype.type == "spider-leg" then
    -- Remove collision_layer from leg prototypes
    collision_mask_util.remove_layer(prototype_mask, collision_layer)
    collision_mask_util.remove_layer(prototype_mask, "object-layer")  -- Overrides Combat mechanics overhaul adding it
  end
  -- Add spider_leg_layer to all prototypes
  insert(prototype_mask, spider_leg_layer)
  prototype.collision_mask = prototype_mask
end


-- The above collision mask changes make train selection priority lower than the track's
-- May not be needed as of v1.2.9
for _, type in pairs({"artillery-wagon", "cargo-wagon", "fluid-wagon", "locomotive", "car"}) do
  for _, prototype in pairs(data.raw[type]) do
    if not prototype.selection_priority or prototype.selection_priority == 50 then
      prototype.selection_priority = 51
    end
  end
end

-- Now that vehicles have selection_priority = 51, bump up all spidertrons to 52
for _, type in pairs({"spider-vehicle"}) do
  for _, prototype in pairs(data.raw[type]) do
    if prototype.selection_priority and prototype.selection_priority == 51 then
      prototype.selection_priority = 52
    end
  end
end
