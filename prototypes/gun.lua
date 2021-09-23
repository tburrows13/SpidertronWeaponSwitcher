local flamethrower = table.deepcopy(data.raw["gun"]["tank-flamethrower"])
flamethrower.name = "spidertron-flamethrower"
flamethrower.attack_parameters.range = 20
flamethrower.attack_parameters.cooldown = 1
flamethrower.attack_parameters.gun_barrel_length = 0
flamethrower.attack_parameters.gun_center_shift = {0, 0}
flamethrower.attack_parameters.damage_modifier = 4
data:extend{flamethrower}

local shotgun = table.deepcopy(data.raw["gun"]["combat-shotgun"])
shotgun.name = "spidertron-shotgun"
shotgun.flags = {"hidden"}
shotgun.attack_parameters.range = 20
shotgun.attack_parameters.damage_modifier = 2
shotgun.attack_parameters.gun_barrel_length = 0
shotgun.attack_parameters.gun_center_shift = {0, 0}
data:extend{shotgun}

local machinegun = table.deepcopy(data.raw["gun"]["tank-machine-gun"])  -- Default range = 20
machinegun.name = "spidertron-machine-gun"
machinegun.attack_parameters.range = 20
machinegun.attack_parameters.damage_modifier = 2
machinegun.attack_parameters.cooldown = 3
machinegun.attack_parameters.gun_barrel_length = 0
machinegun.attack_parameters.gun_center_shift = {0, 0}
data:extend{machinegun}

local cannon = table.deepcopy(data.raw["gun"]["tank-cannon"])  -- Default range = 25
cannon.name = "spidertron-cannon"
machinegun.attack_parameters.gun_barrel_length = 0
machinegun.attack_parameters.gun_center_shift = {0, 0}
data:extend{cannon}

local flamethrowermk2 = table.deepcopy(flamethrower)
flamethrowermk2.name = "sws-flamethrower-mk2"
flamethrowermk2.attack_parameters.range = 30

local shotgunmk2 = table.deepcopy(shotgun)
shotgunmk2.name = "sws-shotgun-mk2"
shotgunmk2.flags = {"hidden"}
shotgunmk2.attack_parameters.range = 30

local machinegunmk2 = table.deepcopy(machinegun)
machinegunmk2.name = "sws-machine-gun-mk2"
machinegunmk2.attack_parameters.range = 30

local cannonmk2 = table.deepcopy(cannon)
cannonmk2.name = "sws-cannon-mk2"
cannonmk2.attack_parameters.range = 35

local flamethrowermk3 = table.deepcopy(flamethrower)
flamethrowermk3.name = "sws-flamethrower-mk3"
flamethrowermk3.attack_parameters.range = 40

local shotgunmk3 = table.deepcopy(shotgun)
shotgunmk3.name = "sws-shotgun-mk3"
shotgunmk3.flags = {"hidden"}
shotgunmk3.attack_parameters.range = 40

local machinegunmk3 = table.deepcopy(machinegun)
machinegunmk3.name = "sws-machine-gun-mk3"
machinegunmk3.attack_parameters.range = 40

local cannonmk3 = table.deepcopy(cannon)
cannonmk3.name = "sws-cannon-mk3"
cannonmk3.attack_parameters.range = 50


data:extend{flamethrowermk2, shotgunmk2, machinegunmk2, cannonmk2, flamethrowermk3, shotgunmk3, machinegunmk3, cannonmk3}




