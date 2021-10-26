

local function create_variations(spidertron_name, weapon_list)
    local spidertron = data.raw["spider-vehicle"][spidertron_name]
    spidertron.fast_replaceable_group = "sws-group-" .. spidertron_name
    spidertron.localised_description = {"entity-description.sws-spidertron"}


    local create_alternate_items = settings.startup["sws-show-alternate-items"].value
    local technologies = {}
    if create_alternate_items then
        -- Find the technologies that will need to be updated
        for name, technology in pairs(data.raw["technology"]) do
            if technology.effects then
                for _, effect in pairs(technology.effects) do
                    if effect.type == "unlock-recipe" and effect.recipe == spidertron_name then
                        table.insert(technologies, technology)
                    end
                end
            end
        end
    end

    local names = {}
    for _, weapon in pairs(weapon_list) do
        if weapon ~= "" then
            local spidertron_variation = table.deepcopy(spidertron)
            local name = "sws-" .. spidertron_name .. "-" .. weapon
            spidertron_variation.name = name

            local gun_array = {}
            for _ = 1, #spidertron.guns do
                table.insert(gun_array, weapon)
            end
            spidertron_variation.guns = gun_array

            if create_alternate_items then
                -- Create alternate spidertron item and recipe
                local item = table.deepcopy(data.raw["item-with-entity-data"][spidertron_name])
                item.name = name
                item.place_result = name

                local recipe = table.deepcopy(data.raw["recipe"][spidertron_name])
                recipe.name = name
                recipe.result = name

                data:extend{item, recipe}

                -- Add recipe to the relevant technologies
                for _, technology in pairs(technologies) do
                    table.insert(technology.effects, {type = "unlock-recipe", recipe = name})
                end

                if spidertron_variation.minable and spidertron_variation.minable.result == spidertron_name then
                    spidertron_variation.minable.result = name
                end
            end

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

if mods["SpidertronPatrols"] and data.raw["spider-vehicle"]["sp-spiderling"] then
    local spiderling_names = create_variations("sp-spiderling", {"sws-machine-gun-spiderling", "sws-shotgun-spiderling", "sws-flamethrower-spiderling", "", "sws-cannon-spiderling"})
    log(serpent.block(spiderling_names))
end