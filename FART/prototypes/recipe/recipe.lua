if not mods["IndustrialRevolution"] then
    data:extend(
        {
            {
                type = "recipe",
                name = "fart",
                enabled = false,
                ingredients =
                {
                    {type = "item", name = "locomotive", amount = 1},
                    {type = "item", name = "long-handed-inserter", amount = 2},
                    {type = "item", name = "steel-plate", amount = 5},
                },
                results = {{type = "item", name = "fart", amount = 1}}
            }
        })
else
    data:extend(
        {
            {
                type = "recipe",
                name = "fart",
                enabled = false,
                ingredients =
                {
                    {type = "item", name = "locomotive", amount = 1},
                    {type = "item", name = "long-handed-inserter", amount = 2},
                    {type = "item", name = "iron-plate-heavy", amount = 5},
                },
                {{type = "item", name = "fart", amount = 1}}
            }
        })
end
