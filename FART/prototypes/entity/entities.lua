local copyPrototype = require "__FART__/lib"
local fart = copyPrototype("locomotive", "locomotive", "fart")
fart.icon = "__FART__/graphics/icons/fart.png"
fart.icon_size = 32
fart.icon_mipmaps = 0
fart.max_speed = 0.8
--fart.burner.fuel_inventory_size = 4

fart.color = {r = 1, g = 0.80, b = 0, a = 0.8}
--fart.color = {r = 0.8, g = 0.40, b = 0, a = 0.8}
data:extend({fart})

--[[data:extend({
    {
        type = "flying-text",
        name = "flying-text2",
        flags = {"not-on-map"},
        time_to_live = 150,
        speed = 0.0
    }})
--]]