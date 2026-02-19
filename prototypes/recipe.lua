-- Concrete recipe as a sandstone brick sink
data:extend({
    {
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
    }
})
