ATOMIC_ARIG_RECYCLING = nil
if mods["quality"] then
    ATOMIC_ARIG_RECYCLING = require("__quality__/prototypes/recycling")
end

local function add_item_to_recipe(recipe_name, item_name, quantity)
    table.insert(data.raw["recipe"][recipe_name].ingredients, {
        type = "item",
        name = item_name,
        amount = quantity
    })
end

local function remove_item_from_recipe(recipe_name, item_name)
    local recipe = data.raw.recipe[recipe_name]
    local removed = false

    for i = #recipe.ingredients, 1, -1 do
        local ingredient = recipe.ingredients[i]
        local name = ingredient.name or ingredient[1]
        local ingredient_type = ingredient.type or "item"

        if ingredient_type == "item" and name == item_name then
            table.remove(recipe.ingredients, i)
            removed = true
        end
    end

    return removed
end

local function remove_item_from_recipe_results(recipe_name, item_name)
    local recipe = data.raw.recipe[recipe_name]
    local results = recipe.results

    for i = #results, 1, -1 do
        local result = results[i]
        if result.name == item_name then
            table.remove(results, i)
        end
    end
end

local function change_recipe(name, ingredients, energy_required)
    local r = data.raw.recipe[name]
    r.ingredients = ingredients
    if energy_required then
        r.energy_required = energy_required
    end
end

local function change_recipe_surface_conditions(recipe_name, surface_conditions)
    local recipe = data.raw.recipe[recipe_name]

    if surface_conditions == nil then
        recipe.surface_conditions = nil
    else
        recipe.surface_conditions = table.deepcopy(surface_conditions)
    end
end

local function unlock_recipe_with_tech(tech_name, recipe_name)
    local tech = data.raw.technology[tech_name]
    local recipe = data.raw.recipe[recipe_name]
    tech.effects = tech.effects or {}

    for _, effect in ipairs(tech.effects) do
        if effect.type == "unlock-recipe" and effect.recipe == recipe_name then
            return false
        end
    end

    table.insert(tech.effects, {
        type = "unlock-recipe",
        recipe = recipe_name
    })

    return true
end

local function add_tech_prereq(tech_name, prereq_name)
    local tech = data.raw.technology[tech_name]
    local prereq = data.raw.technology[prereq_name]

    if not prereq then
        log("atomic-arig-lite: '" .. prereq_name .. "' missing! Skipping add prerequisite for '" .. tech_name .. "'")
        return false
    end

    tech.prerequisites = tech.prerequisites or {}

    for _, name in ipairs(tech.prerequisites) do
        if name == prereq_name then
            return true
        end
    end

    table.insert(tech.prerequisites, prereq_name)
    return true
end

local function remove_tech_prereq(tech_name, prereq_name)
    local tech = data.raw.technology[tech_name]
    local out = {}
    local removed = false

    for _, name in ipairs(tech.prerequisites) do
        if name ~= prereq_name then
            table.insert(out, name)
        else
            removed = true
        end
    end

    tech.prerequisites = out
    return removed
end

local function add_pack_to_tech(tech_name, item_name, quantity)
    table.insert(data.raw["technology"][tech_name].unit.ingredients, { item_name, quantity or 1 })
end

local function remove_pack_from_tech(tech_name, item_name)
    local tech = data.raw.technology[tech_name]
    local ingredients = tech.unit.ingredients
    local removed = false

    for i = #ingredients, 1, -1 do
        local ingredient = ingredients[i]
        if ingredient[1] == item_name then
            table.remove(ingredients, i)
            removed = true
        end
    end

    return removed
end

--- tech_name: Technology prototype name (string)
--- count: Total number of research cycles (integer) (optional)
--- ingredients: Science packs required per cycle (table) (optional)
--- time: Seconds per cycle (number) (optional)
local function set_tech_unit(tech_name, count, ingredients, time)
    local tech = data.raw.technology[tech_name]
    tech.unit = tech.unit or {}
    tech.unit.count_formula = nil

    if count ~= nil then
        tech.unit.count = count
    end
    if ingredients ~= nil then
        tech.unit.ingredients = ingredients
    end
    if time ~= nil then
        tech.unit.time = time
    end
end

local function remove_lab_input(lab_name, input)
    if not data.raw["lab"][lab_name] then
        return
    end

    local lab = data.raw["lab"][lab_name]
    if not lab.inputs then
        return
    end

    for i = #lab.inputs, 1, -1 do
        if lab.inputs[i] == input then
            table.remove(lab.inputs, i)
        end
    end
end

-- Add uranium ore to Arig
local arig_map_gen = data.raw["planet"]["arig"].map_gen_settings

local arig_autoplace_controls_to_add = {
    ["uranium-ore"] = -- Add uranium ore
    {
        richness = 1,
        frequency = 6,
        size = 1
    }
}

arig_map_gen.autoplace_controls = arig_map_gen.autoplace_controls or {}
for control_name, control_value in pairs(arig_autoplace_controls_to_add) do
    local existing_control = arig_map_gen.autoplace_controls[control_name]
    if existing_control == nil then
        arig_map_gen.autoplace_controls[control_name] = table.deepcopy(control_value)
    end
end

local arig_autoplace_settings_to_add = {
    ["tile"] = {
        settings = {}
    },
    ["decorative"] = {
        settings = {}
    },
    ["entity"] = {
        settings = {
            ["uranium-ore"] = {}
        }
    }
}

arig_map_gen.autoplace_settings = arig_map_gen.autoplace_settings or {}
for category_name, category_settings in pairs(arig_autoplace_settings_to_add) do
    arig_map_gen.autoplace_settings[category_name] = arig_map_gen.autoplace_settings[category_name] or {}
    arig_map_gen.autoplace_settings[category_name].settings = arig_map_gen.autoplace_settings[category_name].settings or {}

    for setting_name, setting_value in pairs(category_settings.settings) do
        if arig_map_gen.autoplace_settings[category_name].settings[setting_name] == nil then
            arig_map_gen.autoplace_settings[category_name].settings[setting_name] = table.deepcopy(setting_value)
        end
    end
end

-- Remove uranium ore from Nauvis
for i, autoplace in pairs(data.raw["planet"]["nauvis"].map_gen_settings.autoplace_controls) do
    if i == "uranium-ore" then
        data.raw["planet"]["nauvis"].map_gen_settings.autoplace_controls[i] = nil;
    end
end
for i, autoplace in pairs(data.raw["planet"]["nauvis"].map_gen_settings.autoplace_settings["entity"].settings) do
    if i == "uranium-ore" then
        data.raw["planet"]["nauvis"].map_gen_settings.autoplace_settings["entity"].settings[i] = nil;
    end
end

-- Replace nuclear science pack with compression science pack
for i, technology in pairs(data.raw["technology"]) do
    if technology.prerequisites then
        local function hasPrereq(name)
            for _, p in ipairs(technology.prerequisites) do
                if p == name then
                    return true
                end
            end
            return false
        end

        for j = #technology.prerequisites, 1, -1 do
            local prerequisite = technology.prerequisites[j]
            if prerequisite == "nuclear-science-pack" then
                table.remove(technology.prerequisites, j);
                if not hasPrereq("planetaris-compression-science") then
                    table.insert(technology.prerequisites, "planetaris-compression-science");
                end
            end
        end
    end
    if technology.unit then
        local foundCompressionPack = false;
        local removedNuclearPack = false;
        for j = #technology.unit.ingredients, 1, -1 do
            local ingredient = technology.unit.ingredients[j]
            if ingredient[1] == "nuclear-science-pack" then
                table.remove(technology.unit.ingredients, j);
                removedNuclearPack = true;
            elseif ingredient[1] == "planetaris-compression-science-pack" then
                foundCompressionPack = true;
            end
        end
        if foundCompressionPack == false and removedNuclearPack == true then
            table.insert(technology.unit.ingredients, { "planetaris-compression-science-pack", 1 });
        end
    end
end

-- Remove nuclear science pack from labs
remove_lab_input("lab", "nuclear-science-pack")
remove_lab_input("biolab", "nuclear-science-pack")

-- Remove nuclear science pack tech
data.raw["technology"]["nuclear-science-pack"] = nil

-- Move uranium-related techs to Arig
add_tech_prereq("uranium-mining", "planet-discovery-arig")
add_tech_prereq("planetaris-compression-science", "uranium-processing")

-- Nuclear power requires Heavy glass
add_tech_prereq("nuclear-power", "planetaris-heavy-glass")

-- Fix Kovarex enrichment process (keep production science pack change)
add_tech_prereq("kovarex-enrichment-process", "space-science-pack")
set_tech_unit("kovarex-enrichment-process", 1000, {
    { "automation-science-pack", 1 }, { "logistic-science-pack", 1 }, { "chemical-science-pack", 1 }, { "production-science-pack", 1 }, { "space-science-pack", 1 }, { "planetaris-compression-science-pack", 1 }
}, 30)

-- Fix Atomic bomb
add_pack_to_tech("atomic-bomb", "space-science-pack")
add_tech_prereq("atomic-bomb", "space-science-pack")

-- Add production and space science to Atom forge
add_tech_prereq("atan-atom-forge", "production-science-pack")
add_pack_to_tech("atan-atom-forge", "production-science-pack")
add_pack_to_tech("atan-atom-forge", "space-science-pack")

-- Remove Vulcanus requirement from Arig
remove_tech_prereq("planet-discovery-arig", "planet-discovery-vulcanus")
remove_tech_prereq("planet-discovery-arig", "metallurgic-science-pack")
add_tech_prereq("planet-discovery-arig", "asteroid-collector")
remove_pack_from_tech("planet-discovery-arig", "metallurgic-science-pack")
remove_pack_from_tech("planetaris-arig-roboport", "metallurgic-science-pack")
remove_pack_from_tech("planetaris-big-chest", "metallurgic-science-pack")
remove_pack_from_tech("planetaris-heavy-glass-productivity", "metallurgic-science-pack")
remove_pack_from_tech("planetaris-advanced-solar-panel", "metallurgic-science-pack")
remove_pack_from_tech("planetaris-supported-solar-panel", "metallurgic-science-pack")
remove_pack_from_tech("planetaris-water-harvesting", "metallurgic-science-pack")
remove_pack_from_tech("planetaris-raw-quartz-productivity", "metallurgic-science-pack")
unlock_recipe_with_tech("planetaris-sand-sifting", "steam-condensation")

-- change research time 30 → 60 (same as other starter planet discoveries)
set_tech_unit("planet-discovery-arig", 1000, { { "automation-science-pack", 1 }, { "logistic-science-pack", 1 }, { "chemical-science-pack", 1 }, { "space-science-pack", 1 } }, 60)

-- Add Vulcanus back as dependency for Hyarion
if mods["planetaris-hyarion"] then
    add_tech_prereq("planet-discovery-hyarion", "metallurgic-science-pack")
end

-- Fix Compression not dependent on glass
add_tech_prereq("planetaris-compression", "planetaris-glass")

-- Add concrete sandstone to compression tech
unlock_recipe_with_tech("planetaris-compression", "aa-sandstone-brick-concrete")

-- Add glass recipe to foundry
unlock_recipe_with_tech("planetaris-glass", "aa-glass-panel-foundry")

-- Require Fulgora science for supported solar panels and electric poles as these items can trivialize the buildable area restrictions on Fulgora
if settings.startup["aa-supported-solar-panel-requires-fulgora"].value == true then
    add_pack_to_tech("planetaris-supported-solar-panel", "electromagnetic-science-pack")
    add_tech_prereq("planetaris-supported-solar-panel", "electromagnetic-science-pack")
end

-- Remove Arig requirement (and uranium-235) from biolabs
if settings.startup["aa-biolab-remove-uranium"].value == true then
    remove_pack_from_tech("biolab", "planetaris-compression-science-pack")
    remove_tech_prereq("biolab", "planetaris-compression-science")
    remove_item_from_recipe("biolab", "uranium-235")
end

-- Remove tungsten plate from heavy glass
change_recipe("planetaris-heavy-glass", {
    {
        type = "item",
        name = "planetaris-glass-panel",
        amount = 2
    }, {
    type = "item",
    name = "steel-plate",
    amount = 4
}, {
    type = "item",
    name = "copper-plate",
    amount = 4
}
})

-- Add uranium-238 to planetaris science
add_item_to_recipe("planetaris-compression-science-pack", "uranium-238", 1)

-- Add uranium ore to sand sifting, and extra sulfur to compensate for additional costs elsewhere
remove_item_from_recipe_results("planetaris-sand-sifting", "sulfur")
table.insert(data.raw["recipe"]["planetaris-sand-sifting"].results, {
    type = "item",
    name = "uranium-ore",
    amount = 1,
    probability = 0.04,
    show_details_in_recipe_tooltip = false
})
table.insert(data.raw["recipe"]["planetaris-sand-sifting"].results, {
    type = "item",
    name = "sulfur",
    amount = 1,
    probability = 0.04,
    show_details_in_recipe_tooltip = false
})
table.insert(data.raw["recipe"]["planetaris-advanced-sand-sifting"].results, {
    type = "item",
    name = "uranium-ore",
    amount = 1,
    probability = 0.2,
    show_details_in_recipe_tooltip = false
})

-- Add heavy glass to atom forge
add_tech_prereq("atan-atom-forge", "planetaris-heavy-glass")
add_item_to_recipe("atan-atom-forge", "planetaris-heavy-glass", 20)

-- remove Nauvis-only surface restriction
change_recipe_surface_conditions("atan-atom-forge", nil)

-- Make atom forge require Vulcanus, add tungsten carbide to recipe
if settings.startup["aa-atom-forge-requires-vulcanus"].value == true then
    add_tech_prereq("atan-atom-forge", "metallurgic-science-pack")
    add_pack_to_tech("atan-atom-forge", "metallurgic-science-pack")
    add_item_to_recipe("atan-atom-forge", "tungsten-carbide", 40)
end

-- Add heavy glass to nuclear reactor
change_recipe("nuclear-reactor", {
    {
        type = "item",
        name = "copper-plate",
        amount = 100
    }, {
    type = "item",
    name = "steel-plate",
    amount = 100
}, {
    type = "item",
    name = "advanced-circuit",
    amount = 500
}, {
    type = "item",
    name = "concrete",
    amount = 500
}, {
    type = "item",
    name = "planetaris-heavy-glass",
    amount = 100
}
})

-- Add glass to portable fission reactor
add_item_to_recipe("fission-reactor-equipment", "planetaris-glass-panel", 20)

-- Fix recycling recipes
if ATOMIC_ARIG_RECYCLING ~= nil then
    ATOMIC_ARIG_RECYCLING.generate_recycling_recipe(data.raw["recipe"]["planetaris-heavy-glass"])
    ATOMIC_ARIG_RECYCLING.generate_recycling_recipe(data.raw["recipe"]["atan-atom-forge"])
    ATOMIC_ARIG_RECYCLING.generate_recycling_recipe(data.raw["recipe"]["nuclear-reactor"])
    ATOMIC_ARIG_RECYCLING.generate_recycling_recipe(data.raw["recipe"]["fission-reactor-equipment"])
end

-- Paracelsin: Add new concrete recipes to productivity research
if mods["Paracelsin"] then
    table.insert(data.raw["technology"]["concrete-productivity"].effects, {
        type = "change-recipe-productivity",
        recipe = "aa-sandstone-brick-concrete",
        change = 0.1
    })
end

-- Maraxsis: Glass productivity also affects Arig glasses
if mods["maraxsis"] then
    table.insert(data.raw["technology"]["maraxsis-glass-productivity"].effects, {
        type = "change-recipe-productivity",
        recipe = "planetaris-glass-panel",
        change = 0.1
    })
    table.insert(data.raw["technology"]["maraxsis-glass-productivity"].effects, {
        type = "change-recipe-productivity",
        recipe = "planetaris-heavy-glass",
        change = 0.1
    })
    if settings.startup["aacompat-maraxsis-glass-productivity-requires-arig"].value == true then
        add_pack_to_tech("maraxsis-glass-productivity", "planetaris-compression-science-pack")
        add_tech_prereq("maraxsis-glass-productivity", "planetaris-compression-science")
    end
end
