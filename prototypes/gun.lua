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
shotgun.attack_parameters.range = 20
shotgun.attack_parameters.damage_modifier = 2
shotgun.attack_parameters.gun_barrel_length = 0
shotgun.attack_parameters.gun_center_shift = {0, 0}
data:extend{shotgun}

local machinegun = table.deepcopy(data.raw["gun"]["tank-machine-gun"])
machinegun.name = "spidertron-machine-gun"
machinegun.attack_parameters.range = 20
machinegun.attack_parameters.damage_modifier = 2
machinegun.attack_parameters.cooldown = 3
machinegun.attack_parameters.gun_barrel_length = 0
machinegun.attack_parameters.gun_center_shift = {0, 0}
data:extend{machinegun}







