require '__FART__/stdlib/string'
require '__FART__/stdlib/table'
require "__FART__/FartSettings"
require "__FART__/FART"
require "__FART__/GUI"
local lib = require "__FART__/lib_control"
local saveVar = lib.saveVar
local debugDump = lib.debugDump
local mod_gui = require '__core__/lualib/mod-gui'

local Position = require '__FART__/stdlib/area/position'

local v = require '__FART__/semver'

local MOD_NAME = "FART"

local function resetMetatable(o, mt)
    setmetatable(o,{__index=mt})
    return o
end

local function setMetatables()
    for i, fart in pairs(storage.fart) do
        storage.fart[i] = resetMetatable(fart, FART)
    end
    for name, s in pairs(storage.players) do
        storage.players[name] = resetMetatable(s,Settings)
    end
end

local function getRailTypes()
    storage.rails = {}
    storage.rails_by_index = {}
    storage.rails_localised = {}
    local rails_by_item = {
        rail = {
            curved = "curved-rail-a",
            straight = "straight-rail",
            item = "rail"
        }
    }
    local curved, straight = prototypes.entity["legacy-curved-rail"], prototypes.entity["straight-rail"]
    if curved and straight then
        local vanilla = 0
        if curved.items_to_place_this then
            for _, item in pairs(curved.items_to_place_this) do
                if item.name == "rail" then
                    vanilla = 1
                end
            end
        end
        if straight.items_to_place_this then
            for _, item in pairs(straight.items_to_place_this) do
                if item.name == "rail" then
                    vanilla = vanilla + 1
                end
            end
        end
        if vanilla ~= 2 then
            rails_by_item = {}
        end
    end
    --local items = game.get_filtered_item_prototypes{{filter="place-result", elem_filters={{filter="rail"}}}}
    local railstring = ""
    local rails = prototypes.get_entity_filtered({{filter="rail"}})
    for name, proto in pairs(rails) do
        if proto.type == "straight-rail" and proto.items_to_place_this then
            for _, item in pairs(proto.items_to_place_this) do
                if not rails_by_item[item.name] then
                    rails_by_item[item.name] = {}
                end
                if not rails_by_item[item.name].straight then
                    rails_by_item[item.name].straight = name
                    rails_by_item[item.name].item = item.name
                end
            end
        end
        if proto.type == "curved-rail" then
            for _, item in pairs(proto.items_to_place_this) do
                --log(serpent.block(item))
                local item_proto = prototypes.item[item.name]
                --log(serpent.block(item_proto.place_result.name))
                if item_proto and prototypes.entity[item_proto.place_result.name].type == "straight-rail" then
                    if not rails_by_item[item.name] then
                        rails_by_item[item.name] = {}
                    end
                    if not rails_by_item[item.name].curved then
                        rails_by_item[item.name].curved = name
                    end
                end
            end
        end
    end
    local index = 1
    if rails_by_item.rail then
        rails_by_item.rail.index = index
        storage.rails_by_index[index] = rails_by_item.rail
        storage.rails_localised[index] = prototypes.item["rail"].localised_name
        index = index + 1
        railstring = railstring .. "rail"
    end

    for item, rails in pairs(rails_by_item) do
        if item ~= "rail" and rails.straight and rails.curved then
            rails.index = index
            storage.rails_by_index[index] = rails_by_item[item]
            storage.rails_localised[index] = prototypes.item[item].localised_name
            index = index + 1
            railstring = railstring .. item
        end
    end
    --log(serpent.block(rails_by_item))
    local rails_encoded = helpers.encode_string(helpers.table_to_json(rails_by_item))
    storage.rails = rails_by_item
    return railstring, rails_encoded
end

local function on_tick(event)
    local status, err = pcall(function()

        if storage.overlayStack and storage.overlayStack[event.tick] then
            for _, overlay in pairs(storage.overlayStack[event.tick]) do
                if overlay.valid then
                    overlay.destroy()
                end
            end
            storage.overlayStack[event.tick] = nil
        end

        if storage.activeFarts then
            for _, fart in pairs(storage.activeFarts) do
                if fart.driver and fart.driver.valid then
                    local status, err = pcall(function()
                        if fart:update(event) then
                            GUI.updateGui(fart)
                        end
                    end)
                    if not status then
                        if fart and fart.active then
                            fart:deactivate("Unexpected error: "..err)
                        end
                        debugDump("Unexpected error: "..err,true)
                    end
                end
            end
	    end
    end)
    if not status then
        debugDump("Unexpected error:",true)
        debugDump(err,true)
    end
end

local function init_storage()
    global = global or {}
    storage.players =  storage.players or {}
    storage.savedBlueprints = storage.savedBlueprints or {}
    storage.fart = storage.fart or {}
    storage.activeFarts = storage.activeFarts or {}
    storage.railInfoLast = storage.railInfoLast or {}
    storage.electricInstalled = remote.interfaces.dim_trains and remote.interfaces.dim_trains.railCreated
    storage.overlayStack = storage.overlayStack or {}
    storage.statistics = storage.statistics or {}
    storage.version = storage.version or "0.5.35"
    storage.railString = storage.railString or "rail"
    storage.rails_by_index = storage.rails_by_index or {}
    storage.rails_localised = storage.rails_localised or {}
    storage.rails =  storage.rails or {
        rail = {curved = "curved-rail", straight = "straight-rail", index = 1, item="rail"}
    }
    if storage.debug_log == nil then
        storage.debug_log = false
    end
    setMetatables()
end

local function init_player(player)
    Settings.loadByPlayer(player)
    storage.savedBlueprints[player.index] = storage.savedBlueprints[player.index] or {}
end

local function init_players()
    for _, player in pairs(game.players) do
        init_player(player)
    end
end

local function init_force(force)
    if not storage.statistics then
        init_storage()
    end
    storage.statistics[force.name] = storage.statistics[force.name] or {created={}, removed={}}
end

local function init_forces()
    for _, f in pairs(game.forces) do
        init_force(f)
    end
end

--when Player is in a FART and used FatController to switch to another train
local function on_player_switched(event)
    local status, err = pcall(function()
        if FART.isFARTLocomotive(event.carriage) then
            local fart = FART.findByLocomotive(event.carriage)
            if fart then
                fart:deactivate()
            end
        end
    end)
    if not status then
        debugDump("Unexpected error:",true)
        debugDump(err,true)
    end
end

local function register_events()
    if remote.interfaces.fat and remote.interfaces.fat.get_player_switched_event then
        script.on_event(remote.call("fat", "get_player_switched_event"), on_player_switched)
    end
end

local function on_init()
    register_events()
    init_storage()
    init_forces()
    init_players()
    setMetatables()
    storage.railString, storage.encoded_rails = getRailTypes()
end

local function on_load()
    register_events()
    setMetatables()
end

local function reset_rail_types()
    for _, player in pairs(game.players) do
        player.print("Rail types where changed, resetting to vanilla rail.")
        local psettings = storage.players[player.index]
        if psettings then
            psettings.railType = 1
            psettings.rail = storage.rails_by_index[1]
        end
    end
end

local function on_configuration_changed(data)
    if data.mod_changes[MOD_NAME] then
        local newVersion = data.mod_changes[MOD_NAME].new_version
        newVersion = v(newVersion)
        local oldVersion = data.mod_changes[MOD_NAME].old_version
        if oldVersion then
            oldVersion = v(oldVersion)
            log("FART version changed from ".. tostring(oldVersion) .." to ".. tostring(newVersion))
            if oldVersion > newVersion then
                debugDump("Downgrading FART, reset settings",true)
                global = {}
                on_init()
            else
                if oldVersion < v'3.0.0' then
                    debugDump("FART: Reset settings",true)
                    global = {}
                end
                on_init()
                if oldVersion < v'3.0.1' then
                    for _, psettings in pairs(storage.players) do
                        if psettings.player then
                            psettings.player = nil
                        end
                    end
                end
                if oldVersion < v'3.0.2' then
                    storage.godmode = nil
                    for _, psettings in pairs(storage.players) do
                        psettings.remove_cliffs = true
                    end
                end
                if oldVersion < v'3.1.4' then
                    local invalids = 0
                    for i, fart in pairs(storage.fart) do
                        if (not fart.train or (fart.train and not fart.train.valid)) or (not fart.locomotive or (fart.locomotive and not fart.locomotive.valid)) then
                            if fart.driver and fart.driver.valid then
                                GUI.destroyGui(fart.driver)
                            end
                            fart:deactivate()
                            invalids = invalids + 1
                            storage.activeFarts[i] = nil
                            storage.fart[i] = nil
                        end
                    end
                    if invalids > 0 then
                        log("Deactivated " .. invalids .. "FART trains")
                    end
                end
                if oldVersion < v'3.1.6' then
                    local fart
                    for _, player in pairs(game.players) do
                        if player.gui.left.fart and player.gui.left.fart.valid then
                            FART.onPlayerLeave(player)
                            player.gui.left.fart.destroy()
                            fart = FART.onPlayerEnter(player)
                            GUI.createGui(player)
                            if fart then
                                GUI.updateGui(fart)
                            end
                        end
                    end
                end
                if oldVersion < v'3.1.11' then
                    for _, psettings in pairs(storage.players) do
                        psettings.flipPoles = false
                    end
                end
                storage.trigger_events = nil

                if oldVersion < v'4.0.3' then
                    for i, player in pairs(game.players) do
                        local psettings = storage.players[i]
                        psettings.bp = {diagonal=defaultsDiagonal, straight=defaultsStraight}
                        psettings.activeBP = psettings.bp
                        storage.savedBlueprints[i] = {}
                        player.print("FART: Cleared blueprints")
                    end
                    local fart, frame_flow
                    for _, player in pairs(game.players) do
                        frame_flow = mod_gui.get_frame_flow(player)
                        if frame_flow.fart and frame_flow.fart.valid then
                            FART.onPlayerLeave(player)
                            frame_flow.fart.destroy()
                            fart = FART.onPlayerEnter(player)
                            if fart then
                                fart:deactivate()
                                GUI.createGui(player)
                                GUI.updateGui(fart)
                            end
                        end
                    end
                end
                if oldVersion < v'4.0.4' then
                    local railstring, encoded_rails = getRailTypes()
                    reset_rail_types()
                    storage.railString = railstring
                    storage.encoded_rails = encoded_rails
                end
            end
        else
            debugDump("FART version: ".. tostring(newVersion), true)
        end
        on_init()
        storage.version = tostring(newVersion)
    end

    if data.mod_startup_settings_changed then
        local tech_name = "automated-rail-transportation"
        for index, force in pairs(game.forces) do
            if force.technologies[tech_name].researched then
                force.recipes["fart"].enabled = true
                if settings.startup.fart_enable_module.value then
                    force.recipes["fart-roboport"].enabled = true
                end
            end
        end
    end
    --  if remote.interfaces["satellite-uplink"] and remote.interfaces["satellite-uplink"].add_allowed_item then
    --    log("registered")
    --    remote.call("satellite-uplink", "add_allowed_item", "rail")
    --    remote.call("satellite-uplink", "add_item", "rail", 1)
    --  end

    local railstring, encoded_rails = getRailTypes()
    --rails where added/removed, reset to index 1
    --log(string.format("%s == %s", railstring, storage.railString))
    if railstring ~= storage.railString or encoded_rails ~= storage.encoded_rails then
        reset_rail_types()
    end
    storage.railString = railstring
    storage.encoded_rails = encoded_rails
    setMetatables()
    for _,s in pairs(storage.players) do
        s:checkMods()
    end
end

local function on_player_created(event)
    init_player(game.get_player(event.player_index))
end

local function on_force_created(event)
    init_force(event.force)
end

local function on_gui_click(event)
    local status, err = pcall(function()
        local index = event.player_index
        local player = game.get_player(index)
        if mod_gui.get_frame_flow(player).fart ~= nil then
            local fart = FART.findByPlayer(player)
            if fart then
                GUI.onGuiClick(event, fart, player)
                GUI.updateGui(fart)
            else
                player.print("Gui without train, wrooong!")
                GUI.destroyGui(player)
            end
        end
    end)
    if not status then
        debugDump("Unexpected error:",true)
        debugDump(err,true)
    end
end

local function on_gui_checked_state_changed(event)
    local status, err = pcall(function()
        local index = event.player_index
        local player = game.get_player(index)
        if mod_gui.get_frame_flow(player).fart ~= nil then
            local fart = FART.findByPlayer(player)
            if fart then
                GUI.on_gui_checked_state_changed(event, fart, player)
                GUI.updateGui(fart)
            else
                player.print("Gui without train, wrooong!")
                GUI.destroyGui(player)
            end
        end
    end)
    if not status then
        debugDump("Unexpected error:",true)
        debugDump(err,true)
    end
end

local function on_preplayer_mined_item(event)
    local ent = event.entity
    if ent.type == "locomotive" or ent.type == "cargo-wagon" then
        for i, fart in pairs(storage.fart) do
            if not fart.train or (fart.train.valid and fart.train == ent.train) or not fart.train.valid then
                if event.player_index then
                    local player = game.get_player(event.player_index)
                    if fart.driver and fart.driver == player then
                        FART.onPlayerLeave(player)
                        GUI.destroyGui(player)
                    end
                end
                storage.fart[i]:deactivate()
                storage.fart[i] = nil
                storage.activeFarts[i] = nil
            end
        end
    end
end

local function on_marked_for_deconstruction(event)
    on_preplayer_mined_item(event)
end

local function on_entity_died(event)
    on_preplayer_mined_item(event)
end

local function on_player_driving_changed_state(event)
    local player = game.get_player(event.player_index)
    if FART.isFARTLocomotive(player.vehicle) then
        if mod_gui.get_frame_flow(player).fart == nil then
            local fart = FART.onPlayerEnter(player)
            GUI.createGui(player)
            if fart then
                GUI.updateGui(fart)
            end
        end
    end
    if player.vehicle == nil and mod_gui.get_frame_flow(player).fart ~= nil then
        FART.onPlayerLeave(player)
        debugDump("onPlayerLeave (driving state changed)")
        GUI.destroyGui(player)
    end
end

local function on_pre_player_removed(event)
    local status, err = pcall(function()
        local pi = event.player_index
        local player = game.get_player(pi)
        storage.players[pi] = nil
        storage.savedBlueprints[pi] = nil
        FART.onPlayerLeave(player)
        for i, f in pairs(storage.fart) do
            if f.startedBy == player then
                f:deactivate()
            end
        end
    end)
    if not status then
        debugDump("Unexpected error:",true)
        debugDump(err, true)
    end
end

local function script_raised_destroy(event)
    if event.entity and event.entity.valid and event.entity.type == "locomotive" then
        local status, err = pcall(function()
            local id = FART.getIdFromTrain(event.entity.train)
            local fart = storage.fart[id]
            if not fart then
                return
            end
            fart:deactivate()
            if fart.driver and fart.driver.valid then
                GUI.destroyGui(fart.driver)
            end
            storage.activeFarts[id] = nil
            storage.fart[id] = nil
        end)
        if not status then
            debugDump("Unexpected error:",true)
            debugDump(err, true)
        end
    end
end

-- local function script_raised_built(event)
--     if event.entity and event.entity.valid and event.entity.type == "locomotive" then
--         if event.mod_name and event.mod_name == "MultipleUnitTrainControl" then
--             log(serpent.line(event))
--             -- local entity = event.entity
--             -- if entity.get_driver() then
--             --     FART.onPlayerEnter(entity.get_driver(), entity)
--             -- end
--         end
--     end
-- end
--function on_player_placed_equipment(event)
--  local player = game.get_player(event.player_index)
--  if event.equipment.name == "fart-roboport" and isFARTLocomotive(player.vehicle) then
--    if mod_gui.get_frame_flow(player).fart == nil then
--      FART.onPlayerEnter(player)
--      GUI.createGui(player)
--    end
--  end
--end
--
--function on_player_removed_equipment(event)
--  local player = game.get_player(event.player_index)
--  if event.equipment.name == "fart-roboport" and mod_gui.get_frame_flow(player).fart and player.vehicle then
--    if not isFARTLocomotive(player.vehicle) then
--      FART.onPlayerLeave(player, event.tick + 5)
--      log("onPlayerLeave (equipment changed)")
--      local tick = event.tick + 5
--      if not storage.destroyNextTick[tick] then
--        storage.destroyNextTick[tick] = {}
--      end
--      table.insert(storage.destroyNextTick[tick], event.player_index)
--    end
--  end
--end

script.on_init(on_init)
script.on_load(on_load)
script.on_configuration_changed(on_configuration_changed)
script.on_event(defines.events.on_player_created, on_player_created)
script.on_event(defines.events.on_force_created, on_force_created)

script.on_event(defines.events.on_tick, on_tick)
script.on_event(defines.events.on_gui_click, on_gui_click)
script.on_event(defines.events.on_gui_checked_state_changed, on_gui_checked_state_changed)

local stock_filter = {{filter = "rolling-stock"}}

script.on_event(defines.events.on_pre_player_mined_item, on_preplayer_mined_item, stock_filter)
script.on_event(defines.events.on_entity_died, on_entity_died, stock_filter)
script.on_event(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction, stock_filter)
script.on_event(defines.events.script_raised_destroy, script_raised_destroy)

--script.on_event(defines.events.script_raised_built, script_raised_built)

script.on_event(defines.events.on_player_driving_changed_state, on_player_driving_changed_state)

script.on_event(defines.events.on_pre_player_removed, on_pre_player_removed)

--script.on_event(defines.events.on_player_placed_equipment, on_player_placed_equipment)
--script.on_event(defines.events.on_player_removed_equipment, on_player_removed_equipment)

script.on_event(defines.events.on_player_placed_equipment, function(event)
    if event.equipment.name == "fart-roboport" then
        event.equipment.energy = 5000000000
    end
end)

script.on_event("toggle-train-control", function(event)
    if not script.active_mods["Honk"] and not script.active_mods["Honck"] then
        local player = game.get_player(event.player_index)
        local vehicle = player.vehicle
        if vehicle and vehicle.type == "locomotive" then
            vehicle.train.manual_mode = not vehicle.train.manual_mode
            if player.mod_settings.fart_display_messages.value then
                local mode = vehicle.train.manual_mode and {"gui-train.manual-mode"} or {"gui-train.automatic-mode"}
                player.print({"msg-train-toggled", mode})
            end
        end
    end
end)

script.on_event("fart-toggle-cruise-control", function(event)
    local player = game.get_player(event.player_index)
    local vehicle = player.vehicle
    if vehicle and FART.isFARTLocomotive(vehicle) then
        local fart = FART.findByPlayer(player)
        if fart then fart:toggleCruiseControl() end
    end
end)

script.on_event("fart-toggle-active", function(event)
    local player = game.get_player(event.player_index)
    local vehicle = player.vehicle
    if vehicle and FART.isFARTLocomotive(vehicle) then
        local fart = FART.findByPlayer(player)
        if fart then
            if fart.active then
                fart:deactivate()
            else
                fart:activate()
            end
        end
    end
end)

local command_to_button = {
    fart_read_bp = "blueprint",
    fart_clear_bp = "bpClear",
    fart_vertical_bp = "blueprint_concrete_vertical",
    fart_diagonal_bp = "blueprint_concrete_diagonal"
}
local function fart_command(data)
    local player = game.get_player(data.player_index)
    if not player.vehicle or not (FART.isFARTLocomotive(player.vehicle)) then
        player.print("You need to be in a FART to use this command")
        return
    end
    data.element = {name = command_to_button[data.name], player_index = data.player_index}
    log(serpent.block(data))
    on_gui_click(data)
end

commands.add_command("fart_read_bp", "Read the blueprint/book on the cursor", fart_command)
commands.add_command("fart_clear_bp", "Clear stored layout", fart_command)
commands.add_command("fart_vertical_bp", "Create vertical blueprint", fart_command)
commands.add_command("fart_diagonal_bp", "Create diagonal blueprint", fart_command)
commands.add_command("fart_flipPoles", "Flip the side of the electric pole", function(data)
    local player = game.get_player(data.player_index)
    local psettings = Settings.loadByPlayer(player)
    psettings.flipPoles = not psettings.flipPoles
    player.print("flipPoles: " .. tostring(psettings.flipPoles))
end)

remote.add_interface("fart",
    {
        railInfo = function(rail)
            rail = rail or game.player.selected
            debugDump(rail.name.."@ ".. Position.tostring(rail.position).." dir:"..rail.direction.." realPos: "..Position.tostring(lib.diagonal_to_real_pos(rail)),true)
            if type(storage.railInfoLast) == "table" and storage.railInfoLast.valid then
                local pos = storage.railInfoLast.position
                local diff=Position.subtract(rail.position,pos)
                local rdiff = Position.subtract(lib.diagonal_to_real_pos(rail),lib.diagonal_to_real_pos(storage.railInfoLast))
                debugDump("Offset from last: x="..diff.x..",y="..diff.y,true)
                debugDump("real Offset: x="..rdiff.x..",y="..rdiff.y,true)
                debugDump("Distance (util): "..util.distance(pos, rail.position),true)
                --debugDump("lag for diag: "..(diff.x-diff.y),true)
                --debugDump("lag for straight: "..(diff.y+diff.x),true)
                storage.railInfoLast = false
            else
                storage.railInfoLast = rail
            end
        end,
        --/c remote.call("fart", "debugInfo")
        debugInfo = function()
            saveVar(global, "console")
            --saveVar(storage.debug, "RailDebug")
        end,
        reset = function()
            global = {}
            if game.forces.player.technologies["rail-signals"].researched then
                game.forces.player.recipes["fart"].enabled = true
                game.forces.player.recipes["fart-roboport"].enabled = true
            end
            local fart
            for _, player in pairs(game.players) do
                if player.gui.left.fart and player.gui.left.fart.valid then
                    fart = FART.findByPlayer(player)
                    if fart then
                        fart:deactivate()
                        if mod_gui.get_frame_flow(player).fart == nil then
                            fart = FART.onPlayerEnter(player)
                            GUI.createGui(player)
                            if fart then
                                GUI.updateGui(fart)
                            end
                        end
                    end
                    player.gui.left.fart.destroy()
                end
            end
            for _,p in pairs(game.players) do
                if p.gui.left.fart then p.gui.left.fart.destroy() end
                if mod_gui.get_frame_flow(p).fart then mod_gui.get_frame_flow(p).fart.destroy() end
                if p.gui.top.fart then p.gui.top.fart.destroy() end
            end
            on_init()
        end,

        setCurvedWeight = function(weight, player)
            local s = Settings.loadByPlayer(player)
            s.curvedWeight = weight
        end,

        setSpeed = function(speed)
            for _, s in pairs(storage.players) do
                s.cruiseSpeed = speed
            end
        end,

        tileAt = function(x,y)
            debugDump(game.surfaces[game.player.surface].get_tile(x, y).name,true)
        end,

        quickstart = function(player)
            local items = {"fart", "straight-rail", "medium-electric-pole", "big-electric-pole",
                "small-lamp", "solid-fuel", "rail-signal", "blueprint", "cargo-wagon"}
            local count = {5,100,50,50,50,50,50,10,5}
            player = player or game.player
            for i=1,#items do
                player.insert{name=items[i], count=count[i]}
            end
        end,
        quickstart2 = function(player)
            local items = {"power-armor-mk2", "personal-roboport-equipment", "fusion-reactor-equipment",
                "blueprint", "deconstruction-planner", "construction-robot", "exoskeleton-equipment"}
            local count = {1,5,3,1,1,50,2}
            player = player or game.player
            for i=1,#items do
                player.insert{name=items[i], count=count[i]}
            end
        end,

        quickstartElectric = function()
            local items = {"fart", "curved-power-rail", "straight-power-rail", "medium-electric-pole", "big-electric-pole",
                "small-lamp", "solid-fuel", "rail-signal", "blueprint", "electric-locomotive", "solar-panel", "basic-accumulator"}
            local count = {5,50,50,50,50,50,50,50,10,2,50,50}
            for i=1,#items do
                game.player.insert{name=items[i], count=count[i]}
            end
        end,

        debuglog = function()
            storage.debug_log = not storage.debug_log
            local state = storage.debug_log and "on" or "off"
            debugDump("Debug: "..state,true)
        end,

        revive = function(player)
            for _, entity in pairs(player.surface.find_entities_filtered{area = Position.expand_to_area(player.position,50), type = "entity-ghost"}) do
                entity.revive()
            end
        end,

        tile_properties = function(player)
            local x = player.position.x
            local y = player.position.y
            local tile = player.surface.get_tile(x,y)
            local tprops = player.surface.get_tileproperties(x,y)
            player.print(tile.name)
            local properties = {
                tierFromStart = tprops.tier_from_start,
                roughness = tprops.roughness,
                elevation = tprops.elevation,
                availableWater = tprops.available_water,
                temperature = tprops.temperature
            }
            for k,p in pairs(properties) do
                player.print(k.." "..p)
            end
        end,

        fake_signals = function(bool)
            storage.fake_signals = bool
        end,

        init_players = function()
            for _, psettings in pairs(storage.players) do
                if psettings.mirrorConcrete == nil then
                    psettings.mirrorConcrete = true
                end
            end
        end,

        tiles = function()
            for tileName, prototype in pairs(game.tile_prototypes) do
                if prototype.items_to_place_this then
                    log("Tile: " .. tileName .." item: " .. next(prototype.items_to_place_this))
                end
            end
        end,

        add_entity_to_trigger = function()
            log("remote.call('fart', 'add_entity_to_trigger') is no longer supported. Listen to defines.events.script_raised_built and/or defines.events.script_raised_destroy instead.")
        end,

        remove_entity_from_trigger = function()
            log("remote.call('fart', 'remove_entity_from_trigger') is no longer supported. Listen to defines.events.script_raised_built and/or defines.events.script_raised_destroy instead.")
        end,

        get_trigger_list = function()
            log("remote.call('fart', 'get_trigger_list') is no longer supported. Listen to defines.events.script_raised_built and/or defines.events.script_raised_destroy instead")
        end,

        -- foo = function()
        --     local positions = {}
        --     local some_data = {whatever=10}
        --     log("concat start")
        --     for i = 0, 100 do
        --         for j = 0, 100 do
        --             positions[i..":"..j] = some_data.whatever + i
        --         end
        --     end
        --     log("concat stop")
        --     log(positions["0:0"])

        --     positions = {}
        --     log("hash start")
        --     for i = 0, 100 do
        --         for j = 0, 100 do
        --             positions[position_hash(i,j)] = some_data.whatever + i
        --         end
        --     end
        --     log("hash stop")
        --     log(positions["0:0"])
        -- end
    })