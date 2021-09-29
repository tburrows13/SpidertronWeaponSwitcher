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

data:extend{machinegun, machinegunmk2, machinegunmk3}


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

data:extend{shotgun, shotgunmk2, shotgunmk3}


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

data:extend{flamethrower, flamethrowermk2, flamethrowermk3}


local tank_cannon = data.raw["gun"]["tank-cannon"]
tank_cannon.stack_size = 1
tank_cannon.attack_parameters.range = 30  -- This is the actual default: https://forums.factorio.com/viewtopic.php?p=553494#p553494

local cannon = table.deepcopy(tank_cannon)  -- Default range = 30
cannon.name = "spidertron-cannon"
cannon.attack_parameters.projectile_creation_distance = -0.5
cannon.attack_parameters.projectile_center = {0, 0.3}

local cannonmk2 = table.deepcopy(cannon)
cannonmk2.name = "sws-cannon-mk2"
cannonmk2.attack_parameters.range = 40

local cannonmk3 = table.deepcopy(cannon)
cannonmk3.name = "sws-cannon-mk3"
cannonmk3.attack_parameters.range = 50

data:extend{cannon, cannonmk2, cannonmk3}

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
