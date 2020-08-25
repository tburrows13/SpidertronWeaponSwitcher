local spidertron = table.deepcopy(data.raw["spider-vehicle"]["spidertron"])
spidertron.fast_replaceable_group = "spidertron-switcher"


-- machine gun
local spidertron1 = table.deepcopy(spidertron)
spidertron1.name = "spidertron-alt-1"
spidertron1.guns = {"spidertron-machine-gun", "spidertron-machine-gun", "spidertron-machine-gun", "spidertron-machine-gun"}

-- (several?) shotgun
local spidertron2 = table.deepcopy(spidertron)
spidertron2.name = "spidertron-alt-2"
spidertron2.guns = {"spidertron-shotgun", "spidertron-shotgun", "spidertron-shotgun", "spidertron-shotgun"}

-- flamethrower
local spidertron3 = table.deepcopy(spidertron)
spidertron3.name = "spidertron-alt-3"
spidertron3.guns = {"spidertron-flamethrower", "spidertron-flamethrower", "spidertron-flamethrower", "spidertron-flamethrower"}

-- 4 rocket launchers
local spidertron4 = table.deepcopy(spidertron)
spidertron4.name = "spidertron-alt-4"

-- 4 cannons
local spidertron5 = table.deepcopy(spidertron)
spidertron5.name = "spidertron-alt-5"
spidertron5.guns = {"tank-cannon", "tank-cannon", "tank-cannon", "tank-cannon"}


data:extend{spidertron1, spidertron2, spidertron3, spidertron4, spidertron5}

local spidertron_item = table.deepcopy(data.raw["item-with-entity-data"]["spidertron"])
local spidertron_item1 = table.deepcopy(spidertron_item)
local spidertron_item2 = table.deepcopy(spidertron_item)
local spidertron_item3 = table.deepcopy(spidertron_item)
local spidertron_item4 = table.deepcopy(spidertron_item)
local spidertron_item5 = table.deepcopy(spidertron_item)
spidertron_item1.name = "spidertron-alt-1"
spidertron_item2.name = "spidertron-alt-2"
spidertron_item3.name = "spidertron-alt-3"
spidertron_item4.name = "spidertron-alt-4"
spidertron_item5.name = "spidertron-alt-5"
spidertron_item1.place_result = "spidertron-alt-1"
spidertron_item2.place_result = "spidertron-alt-2"
spidertron_item3.place_result = "spidertron-alt-3"
spidertron_item4.place_result = "spidertron-alt-4"
spidertron_item5.place_result = "spidertron-alt-5"

data:extend{spidertron_item1,
            spidertron_item2,
            spidertron_item3,
            spidertron_item4,
            spidertron_item5}


data.raw["recipe"]["spidertron"]["normal"].result = "spidertron-alt-4"
--data.raw["technology"]["spidertron"].effects = { {type = "unlock-recipe", recipe = "spidertron-alt-1"} }