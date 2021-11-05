local collision_mask_util = require("__core__.lualib.collision-mask-util")
local insert = table.insert

-- Stop cannon-projectile colliding with spider-legs
-- Add an extra layer to every prototype with collision mask of player-layer or rail-layer except spider-leg
-- Replace spider-leg's masks with just spider_leg_layer

local spider_leg_layers = collision_mask_util.get_default_mask("spider-leg")
local spider_leg_alt_layers = {}

if mods["space-exploration"] then
  insert(spider_leg_layers, "object-layer")
end

log(serpent.block(collision_mask_util.get_default_mask("spider-leg")))
log(serpent.block(collision_mask_util.get_mask(data.raw["spider-leg"]["spidertron-leg-1"])))

for _, layer in pairs(spider_leg_layers) do
  local spider_leg_layer = collision_mask_util.get_first_unused_layer()
  insert(spider_leg_alt_layers, spider_leg_layer)

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
  prototype.collision_mask = spider_leg_alt_layers
end


-- The above collision mask changes make train selection priority lower than the track's
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
