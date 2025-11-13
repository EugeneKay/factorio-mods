if not settings.startup["fart_enable_module"].value then
    return
end
local copyPrototype = require "__FART__/lib"
data:extend
    {
        {
            type = "equipment-category",
            name = "fart-equipment"
        },
        {
            type = "equipment-grid",
            name = "fart-equipment-grid",
            width = 2,
            height = 2,
            equipment_categories = {"fart-equipment"},
        },--[[
    {
      type = "equipment-grid",
      name = "fart-equipment-grid-wagon",
      width = 8,
      height = 8,
      equipment_categories = {"fart-equipment", "armor"},
    },]]--
}

local fartRoboport =  copyPrototype("roboport-equipment", "personal-roboport-equipment", "fart-roboport", true)
fartRoboport.energy_consumption = nil
--fartRoboport.robot_limit = 50
fartRoboport.robot_limit = 0
fartRoboport.charging_station_count = 0
--fartRoboport.construction_radius = 30
fartRoboport.construction_radius = 0
fartRoboport.categories = {"fart-equipment"}

local fartRoboportRecipe = copyPrototype("recipe", "personal-roboport-equipment", "fart-roboport", true)

if not mods["IndustrialRevolution"] then
    fartRoboportRecipe.ingredients = {
        {type = "item", name = "iron-gear-wheel", amount = 5},
        {type = "item", name = "electronic-circuit", amount = 5},
        {type = "item", name = "steel-plate", amount = 5},
    }
else
    fartRoboportRecipe.ingredients = {
        {type = "item", name = "iron-gear-wheel", amount = 5},
        {type = "item", name = "electronic-circuit", amount = 5},
        {type = "item", name = "iron-plate-heavy", amount = 5},
    }
end


local fartRoboportItem = copyPrototype("item", "personal-roboport-equipment", "fart-roboport", true)
fartRoboportItem.subgroup = "train-transport"
fartRoboportItem.order = "a[train-system]-j[fart]"
fartRoboportItem.icon = "__FART__/graphics/icons/fart-roboport.png"
fartRoboportItem.icon_size = 32
fartRoboportItem.icon_mipmaps = 0

data:extend{fartRoboport, fartRoboportItem, fartRoboportRecipe}
