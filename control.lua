--control.lua
require("mod-gui")

-- GUI
local function gui_init(player)
    local gui_names = {
        {"top", "findmycar_button"},
        {"center", "findmycar_flow"},
    }
    for k, v in pairs(gui_names) do
        if player.gui[v[1]][v[2]] then player.gui[v[1]][v[2]].destroy() end
    end

    local flow = mod_gui.get_button_flow(player)
    if not flow.findmycar_button then
        local button = flow.add{
            type="sprite-button",
            name="findmycar_button",
            style=mod_gui.button_style,
            sprite="findmycar-sprite",
            tooltip={"findmycar-button-tooltip"}
        }
        button.style.visible=true
    end

    global["findmycar"] = global["findmycar"] or {}
    global["findmycar_selected"] = global["findmycar_selected"] or {}
end

local function create_main_frame(player, flow, index)
    global["findmycar_selected"][player.name] = index
    local entity = global["findmycar"][player.name][index]
    local frame = flow.add{
        type="frame",
        caption={"findmycar-main-frame-title", entity.name, entity.last_user.name},
        name="findmycar_main_frame",
        direction="vertical"
    }
    local scroll_pane = frame.add{
        type="scroll-pane",
        name="findmycar_main_scroll_pane",
    }
    scroll_pane.style.maximal_height = settings.global["scroll-pane-max-height"].value
    local camera = scroll_pane.add{
        type="camera",
        name="findmycar_main_camera",
        position=entity.position,
        surface_index = entity.surface.index,
        zoom=MAIN_CAMERA_ZOOM
    }
    camera.style.minimal_width = settings.global["main-camera-min-width"].value
    camera.style.minimal_height = settings.global["main-camera-min-height"].value
    local options_flow = scroll_pane.add{
        type="flow",
        name="findmycar_main_flow",
        direction="horizontal"
    }
    options_flow.add{
        type="button",
        name="findmycar_main_zoom_camera_in",
        caption="+"
    }
    options_flow.add{
        type="button",
        name="findmycar_main_zoom_camera_out",
        caption="-"
    }
    options_flow.add{
        type="button",
        name="findmycar_main_refresh_camera",
        caption={"findmycar-refresh-camera"}
    }
    options_flow.add{
        type="button",
        name="findmycar_main_teleport_player",
        caption={"findmycar-teleport-player", entity.name},
    }
    options_flow.add{
        type="button",
        name="findmycar_main_mine_entity",
        caption={"findmycar-mine-entity", entity.name},
    }
end
    

local function gui_toggle_frame(player)
    local flow = player.gui.center.findmycar_flow
    global["findmycar"][player.name] = {}
    global["findmycar_selected"][player.name] = nil
    if flow then
        flow.destroy()
    else
        local flow = player.gui.center.add{
            type="flow",
            name="findmycar_flow",
            direction="horizontal"
        }
        local list_frame = flow.add{
            type="frame",
            caption={"findmycar-list-frame-title"},
            name="findmycar_list_frame",
            direction="vertical"
        }
        local scroll_pane = list_frame.add{
            type="scroll-pane",
            name="findmycar_list_scroll_pane",
        }
        scroll_pane.style.maximal_height = settings.global["scroll-pane-max-height"].value
        local list_table = scroll_pane.add{
            type="table",
            name="findmycar_list_table",
            colspan=settings.global["list-table-colspan"].value
        }

        local count = 0
        for key1, surface in pairs(game.surfaces) do
            local entity_limit = settings.global["entity-limit"].value
            local entities = surface.find_entities_filtered{
                type="car",
                limit=(entity_limit > 0) and entity_limit or nil
            }
            for key2, entity in pairs(entities) do
                count = count + 1
                global["findmycar"][player.name][count] = entity
                local element_frame = list_table.add{
                    type="frame",
                    name="findmycar_list_element_frame_"..count,
                    direction="vertical",
                    style="captionless_frame_style"
                }
                local camera = element_frame.add{
                    type="camera",
                    name="findmycar_list_element_camera_"..count,
                    position=entity.position,
                    surface_index=surface.index,
                    zoom=LIST_CAMERA_ZOOM
                }
                camera.style.minimal_width = settings.global["list-camera-min-width"].value
                camera.style.minimal_height = settings.global["list-camera-min-height"].value
                element_frame.add{
                    type="label",
                    name="findmycar_list_element_label_"..count,
                    caption=entity.localised_name,
                }
            end
        end
        if count > 0 then
            global["findmycar_selected"][player.name] = 1
            create_main_frame(player, flow, 1)
        end
    end
end

local function refresh_camera(player)
    -- Refresh main camera
    local index = global["findmycar_selected"][player.name]
    local entity = global["findmycar"][player.name][index]
    local camera = player.gui.center.findmycar_flow.findmycar_main_frame.findmycar_main_scroll_pane.findmycar_main_camera
    camera.position = entity.position
    -- Refresh list camera
    for index, entity in pairs(global["findmycar"][player.name]) do
        local camera = player.gui.center.findmycar_flow.findmycar_list_frame.findmycar_list_scroll_pane.findmycar_list_table["findmycar_list_element_frame_"..index]["findmycar_list_element_camera_"..index]
        camera.position = entity.position
    end
end

script.on_init(
    function()
        for _, player in pairs(game.players) do
            gui_init(player)
        end
    end
)

script.on_configuration_changed(
    function(data)
        if not data or not data.mod_changes then return end
        if data.mod_changes["FindMyCar"] then
            for _, player in pairs(game.players) do
                gui_init(player)
            end
        end
    end
)

script.on_event(
    {defines.events.on_player_joined_game, defines.events.on_player_created},
    function(event)
        gui_init(game.players[event.player_index])
    end
)

script.on_event(
    "findmycar-toggle-gui",
    function(event)
        gui_toggle_frame(game.players[event.player_index])
    end
)

script.on_event(
    "findmycar-toggle-button",
    function(event)
        local player = game.players[event.player_index]
        local button = mod_gui.get_button_flow(player).findmycar_button
        if button then
            button.style.visible = not button.style.visible
        end
    end
)

script.on_event(
    defines.events.on_gui_click,
    function(event)
        local player = game.players[event.player_index]
        if event.element.name == "findmycar_button" then
            gui_toggle_frame(player)
        elseif event.element.name == "findmycar_main_zoom_camera_in" then
            local camera = player.gui.center.findmycar_flow.findmycar_main_frame.findmycar_main_scroll_pane.findmycar_main_camera
            camera.zoom = camera.zoom * MAIN_CAMERA_ZOOM_DIFF
        elseif event.element.name == "findmycar_main_zoom_camera_out" then
            local camera = player.gui.center.findmycar_flow.findmycar_main_frame.findmycar_main_scroll_pane.findmycar_main_camera
            camera.zoom = camera.zoom / MAIN_CAMERA_ZOOM_DIFF
        elseif event.element.name == "findmycar_main_refresh_camera" then
            refresh_camera(player)
        elseif event.element.name == "findmycar_main_teleport_player" then
            local index = global["findmycar_selected"][player.name]
            local entity = global["findmycar"][player.name][index]
            player.teleport(entity.position, entity.surface)
        elseif event.element.name == "findmycar_main_mine_entity" then
            local index = global["findmycar_selected"][player.name]
            local entity = global["findmycar"][player.name][index]
            player.mine_entity(entity)
            gui_toggle_frame(player)
            gui_toggle_frame(player)
        else
            gui_element, index = string.match(event.element.name, "findmycar%_list%_element%_(%a+)%_(%d+)")
            if (gui_element == "frame" or gui_element == "camera" or gui_element == "label") and index then
                if index ~= global["findmycar_selected"][player.name] then
                    local flow = player.gui.center.findmycar_flow
                    flow.findmycar_main_frame.destroy()
                    create_main_frame(player, flow, tonumber(index))
                end
            end
        end
    end
)
