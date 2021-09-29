local collision_mask_util = require("__core__.lualib.collision-mask-util")
local insert = table.insert

-- Stop cannon-projectile colliding with spider-legs
-- Add spider-leg-layer to every prototype with collision mask of player-layer or rail-layer except spider-leg
-- Replace spider-leg's masks with just spider_leg_layer

local spider_leg_layer = collision_mask_util.get_first_unused_layer()
local spider_leg_mask = collision_mask_util.get_default_mask("spider-leg")

local prototypes = collision_mask_util.collect_prototypes_colliding_with_mask(spider_leg_mask)

-- Tiles aren't found by collect_prototypes_colliding_with_mask, and also are guaranteed to contain collision_mask
for _, prototype in pairs(data.raw["tile"]) do
  local tile_mask = prototype.collision_mask
  if collision_mask_util.masks_collide(tile_mask, spider_leg_mask) then
    insert(prototypes, prototype)
  end
end

for _, prototype in pairs(prototypes) do
  if prototype.type ~= "spider-leg" then
    local mask = collision_mask_util.get_mask(prototype)
    insert(mask, spider_leg_layer)
    prototype.collision_mask = mask
  else
    prototype.collision_mask = {spider_leg_layer, "water-tile"}  -- water-tile is temporary workaround for https://forums.factorio.com/viewtopic.php?f=7&t=100132
  end
end
