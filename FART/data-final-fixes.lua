local updatedGrids = {}

local function addFarlCategory(equipmentGridName)
    local equipmentGrid = data.raw["equipment-grid"][equipmentGridName]
    if equipmentGrid and equipmentGrid.equipment_categories and not updatedGrids[equipmentGrid.name] then
        local found = false
        for _, category in pairs(equipmentGrid.equipment_categories) do
            if category == "fart-equipment" then
                found = true
                break
            end
        end
        if not found then
            table.insert(equipmentGrid.equipment_categories, "fart-equipment")
            updatedGrids[equipmentGrid.name] = true
        end
    end
end

--add grid to fart if one is present and FART doesn't already have one
if data.raw["locomotive"]["locomotive"].equipment_grid and not data.raw["locomotive"]["fart"].equipment_grid then
    data.raw["locomotive"]["fart"].equipment_grid = data.raw["locomotive"]["locomotive"].equipment_grid
end
if settings.startup["fart_enable_module"].value then
    for locoName, loco in pairs(data.raw.locomotive) do
        if locoName ~= "fart" then
            if not loco.equipment_grid then
                loco.equipment_grid = "fart-equipment-grid"
            else
                addFarlCategory(loco.equipment_grid)
            end
        end
        --log("Loco: " .. locoName .. " " .. serpent.line(loco.equipment_grid, {comment=false}))
    end
end
--[[

for wagonName, wagon in pairs(data.raw["cargo-wagon"]) do

  if not wagon.equipment_grid then

    wagon.equipment_grid = "fart-equipment-grid-wagon"

  else

    addFarlCategory(wagon.equipment_grid)

  end

end

]]--
