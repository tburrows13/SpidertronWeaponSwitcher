local function create_variations(spidertron_name, weapon_list)
    local spidertron = data.raw["spider-vehicle"][spidertron_name]
    spidertron.fast_replaceable_group = "sws-group-" .. spidertron_name

    local names = {}
    for _, weapon in pairs(weapon_list) do
        if weapon ~= "" then
            local spidertron_variation = table.deepcopy(spidertron)
            local name = "sws-" .. spidertron_name .. "-" .. weapon
            spidertron_variation.name = name
            spidertron_variation.guns = {weapon, weapon, weapon, weapon}
            table.insert(names, name)

            data:extend{spidertron_variation}
        else
            table.insert(names, spidertron_name)
        end
    end

    -- Stops item name becoming "Rocket Launcher Spidertron"
    data.raw["item-with-entity-data"][spidertron_name].localised_name = {"item-name." .. spidertron_name}

    return names
end

local spidertron_names = create_variations("spidertron", {"spidertron-machine-gun", "spidertron-shotgun", "spidertron-flamethrower", "", "spidertron-cannon"})
log(serpent.block(spidertron_names))

if mods["spidertron-extended"] then
    local mk2_names = create_variations("spidertronmk2", {"sws-machine-gun-mk2", "sws-shotgun-mk2", "sws-flamethrower-mk2", "", "sws-cannon-mk2"})
    log(serpent.block(mk2_names))
    local mk3_names = create_variations("spidertronmk3", {"sws-machine-gun-mk3", "sws-shotgun-mk3", "sws-flamethrower-mk3", "", "sws-cannon-mk3"})
    log(serpent.block(mk3_names))

end