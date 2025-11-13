local tech = data.raw.technology["automated-rail-transportation"]
if mods["IndustrialRevolution"] then
    tech_name = "automated-rail-transportation"
end

table.insert(tech.effects,
    {
        type="unlock-recipe",
        recipe = "fart"
    })
if settings.startup["fart_enable_module"].value then
    table.insert(tech.effects,
    {
        type="unlock-recipe",
        recipe = "fart-roboport"
    })
end
