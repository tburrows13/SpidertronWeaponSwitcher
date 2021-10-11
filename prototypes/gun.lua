local machinegun = table.deepcopy(data.raw["gun"]["tank-machine-gun"])  -- Default range = 20
machinegun.name = "spidertron-machine-gun"
machinegun.attack_parameters.range = 20
machinegun.attack_parameters.damage_modifier = 2
machinegun.attack_parameters.cooldown = 3
machinegun.attack_parameters.projectile_creation_distance = -0.5
machinegun.attack_parameters.projectile_center = {0, 0.3}

local machinegunmk2 = table.deepcopy(machinegun)
machinegunmk2.name = "sws-machine-gun-mk2"
machinegunmk2.attack_parameters.range = 30

local machinegunmk3 = table.deepcopy(machinegun)
machinegunmk3.name = "sws-machine-gun-mk3"
machinegunmk3.attack_parameters.range = 40

local machinegun_spiderling = table.deepcopy(machinegun)
machinegun_spiderling.name = "sws-machine-gun-spiderling"
machinegun_spiderling.attack_parameters.projectile_creation_distance = 0
machinegun_spiderling.attack_parameters.projectile_center = {0, 0}
machinegun_spiderling.attack_parameters.range = 12
machinegun_spiderling.attack_parameters.cooldown = 6

data:extend{machinegun, machinegunmk2, machinegunmk3, machinegun_spiderling}


local shotgun = table.deepcopy(data.raw["gun"]["combat-shotgun"])
shotgun.name = "spidertron-shotgun"
shotgun.flags = {"hidden"}
shotgun.stack_size = 1
shotgun.attack_parameters.range = 20
shotgun.attack_parameters.damage_modifier = 2
shotgun.attack_parameters.projectile_creation_distance = -0.5
shotgun.attack_parameters.projectile_center = {0, 0.3}

local shotgunmk2 = table.deepcopy(shotgun)
shotgunmk2.name = "sws-shotgun-mk2"
shotgunmk2.flags = {"hidden"}
shotgunmk2.attack_parameters.range = 30

local shotgunmk3 = table.deepcopy(shotgun)
shotgunmk3.name = "sws-shotgun-mk3"
shotgunmk3.flags = {"hidden"}
shotgunmk3.attack_parameters.range = 40

local shotgun_spiderling = table.deepcopy(shotgun)
shotgun_spiderling.name = "sws-shotgun-spiderling"
shotgun_spiderling.attack_parameters.projectile_creation_distance = 0
shotgun_spiderling.attack_parameters.projectile_center = {0, 0}
shotgun_spiderling.attack_parameters.range = 12
shotgun_spiderling.attack_parameters.cooldown = 60

data:extend{shotgun, shotgunmk2, shotgunmk3, shotgun_spiderling}


local flamethrower = table.deepcopy(data.raw["gun"]["tank-flamethrower"])
flamethrower.name = "spidertron-flamethrower"
flamethrower.attack_parameters.range = 20
flamethrower.attack_parameters.cooldown = 1
flamethrower.attack_parameters.gun_barrel_length = 0
flamethrower.attack_parameters.gun_center_shift = {0, 0}
flamethrower.attack_parameters.damage_modifier = 4

local flamethrowermk2 = table.deepcopy(flamethrower)
flamethrowermk2.name = "sws-flamethrower-mk2"
flamethrowermk2.attack_parameters.range = 30

local flamethrowermk3 = table.deepcopy(flamethrower)
flamethrowermk3.name = "sws-flamethrower-mk3"
flamethrowermk3.attack_parameters.range = 40

local flamethrower_spiderling = table.deepcopy(flamethrower)
flamethrower_spiderling.name = "sws-flamethrower-spiderling"
flamethrower_spiderling.attack_parameters.range = 12
flamethrower_spiderling.attack_parameters.cooldown = 2

data:extend{flamethrower, flamethrowermk2, flamethrowermk3, flamethrower_spiderling}


local cannon = table.deepcopy(data.raw["gun"]["tank-cannon"])  -- Default range = 30
cannon.name = "spidertron-cannon"
cannon.attack_parameters.projectile_creation_distance = -0.5
cannon.attack_parameters.projectile_center = {0, 0.3}

local cannonmk2 = table.deepcopy(cannon)
cannonmk2.name = "sws-cannon-mk2"
cannonmk2.attack_parameters.range = 40

local cannonmk3 = table.deepcopy(cannon)
cannonmk3.name = "sws-cannon-mk3"
cannonmk3.attack_parameters.range = 50

local cannon_spiderling = table.deepcopy(cannon)
cannon_spiderling.name = "sws-cannon-spiderling"
cannon_spiderling.attack_parameters.projectile_creation_distance = 0
cannon_spiderling.attack_parameters.projectile_center = {0, 0}
cannon_spiderling.attack_parameters.range = 20
cannon_spiderling.attack_parameters.cooldown = 180

data:extend{cannon, cannonmk2, cannonmk3, cannon_spiderling}

-- Rename spidertron-extended's MK2&3 rocket launcher's to be consistent with SWS's gun names
local mk2_name = "spidertronmk2-rocket-launcher-"
local mk3_name = "spidertronmk3-rocket-launcher-"
for i = 1, 4 do
  local guns = data.raw["gun"]
  local mk2 = guns[mk2_name .. i]
  if mk2 then
    mk2.localised_name = {"item-name.spidertron-rocket-launcher-mk2"}
  end
  local mk3 = guns[mk3_name .. i]
  if mk3 then
    mk3.localised_name = {"item-name.spidertron-rocket-launcher-mk3"}
  end
end
