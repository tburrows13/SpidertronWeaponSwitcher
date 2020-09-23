local function create_variations(spidertron_name, weapon_list)
    local spidertron = data.raw["spider-vehicle"][spidertron_name]
    spidertron.fast_replaceable_group = "sws-group-" .. spidertron_name

    local spidertron_item = data.raw["item-with-entity-data"]["spidertron"]

    local names = {}
    for _, weapon in pairs(weapon_list) do
        if weapon ~= "" then
            local spidertron_variation = table.deepcopy(spidertron)
            local name = "sws-" .. spidertron_name .. "-" .. weapon
            spidertron_variation.name = name
            spidertron_variation.guns = {weapon, weapon, weapon, weapon}
            table.insert(names, name)

            local spidertron_variation_item = table.deepcopy(spidertron_item)
            spidertron_variation_item.name = name
            spidertron_variation_item.place_result = name

            data:extend{spidertron_variation, spidertron_variation_item}
        else
            table.insert(names, spidertron_name)
        end
    end
    return names
end

local spidertron_names = create_variations("spidertron", {"spidertron-machine-gun", "spidertron-shotgun", "spidertron-flamethrower", "", "tank-cannon"})
log(serpent.block(spidertron_names))

if mods["spidertron-extended"] then
    local mk2_names = create_variations("spidertronmk2", {"sws-machine-gun-mk2", "sws-shotgun-mk2", "sws-flamethrower-mk2", "", "tank-cannon"})
    log(serpent.block(mk2_names))
    local mk3_names = create_variations("spidertronmk3", {"sws-machine-gun-mk3", "sws-shotgun-mk3", "sws-flamethrower-mk3", "", "tank-cannon"})
    log(serpent.block(mk3_names))

end