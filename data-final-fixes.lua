local collision_mask_util = require("__core__.lualib.collision-mask-util")
local insert = table.insert

-- Stop cannon-projectile colliding with spider-legs
-- Add an extra layer to every prototype with collision mask of player-layer or rail-layer except spider-leg
-- Replace spider-leg's masks with just spider_leg_layer

local spider_leg_layers = {"water-tile"}  -- water-tile is temporary workaround for https://forums.factorio.com/viewtopic.php?f=7&t=100132

if mods["space-exploration"] then
  insert(spider_leg_layers, "object-layer")
end

for _, layer in pairs(collision_mask_util.get_default_mask("spider-leg")) do
  local spider_leg_layer = collision_mask_util.get_first_unused_layer()
  insert(spider_leg_layers, spider_leg_layer)

  local prototypes = collision_mask_util.collect_prototypes_with_layer(layer)

  -- Tiles aren't found by collect_prototypes_colliding_with_mask, and also are guaranteed to contain collision_mask
  for _, prototype in pairs(data.raw["tile"]) do
    local tile_mask = prototype.collision_mask
    if collision_mask_util.mask_contains_layer(tile_mask, layer) then
      insert(prototypes, prototype)
    end
  end

  for _, prototype in pairs(prototypes) do
    if prototype.type ~= "spider-leg" then
      local mask = collision_mask_util.get_mask(prototype)
      insert(mask, spider_leg_layer)
      prototype.collision_mask = mask
    end
  end
end

for _, prototype in pairs(data.raw["spider-leg"]) do
  prototype.collision_mask = spider_leg_layers
end
