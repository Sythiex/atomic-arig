data:extend({
    {
        -- Concrete from sandstone brick
        type = "recipe",
        name = "aa-sandstone-brick-concrete",
        category = "compressing",
        order = "b[concrete]-a[plain]-sandstone",
        icon = "__atomic-arig-lite__/graphics/icons/aa-sandstone-brick-concrete.png",
        enabled = false,
        energy_required = 10,
        surface_conditions = {
            {
                property = "planetaris-dust-concentration",
                min = 50,
                max = 100
            }
        },
        ingredients = {
            {
                type = "item",
                name = "iron-ore",
                amount = 1
            }, {
                type = "item",
                name = "planetaris-sandstone-brick",
                amount = 5
            }, {
                type = "fluid",
                name = "water",
                amount = 100
            }
        },
        results = {
            {
                type = "item",
                name = "concrete",
                amount = 10
            }
        }
    }, {
        -- Glass in foundry
        type = "recipe",
        name = "aa-glass-panel-foundry",
        category = "metallurgy",
        subgroup = "arig-processes",
        order = "a[sand-processing]-a[sifting]-d",
        icon = "__atomic-arig-lite__/graphics/icons/aa-glass-panel-foundry.png",
        enabled = false,
        energy_required = 3,
        ingredients = {
            {
                type = "fluid",
                name = "planetaris-pure-sand",
                amount = 100
            }
        },
        results = {
            {
                type = "item",
                name = "planetaris-glass-panel",
                amount = 5
            }
        },
        allow_productivity = true
    }
})
