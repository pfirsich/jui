local requirePrefix = (...):match("(.+%.)[^%.]+$") or ""
local jui = require(requirePrefix .. "init")
local util = require(requirePrefix .. "util")

jui.love = {}

jui.backend.name = "love"

jui.backend.defaultConfig = {
    autoEvents = true,
}

function jui.backend.init()
    jui.love.mesh = love.graphics.newMesh(jui.config.numVertices, "triangles", "stream")
    jui.love.defaultFont = jui.config.defaultFont or love.graphics.getFont()
    jui.windowSize.x, jui.windowSize.y = love.graphics.getDimensions()
end

local mouseButtonMap = {
    "left",
    "right",
    "middle",
}

local function makeKeyMap(keys)
    local map = {}
    for _, key in ipairs(keys) do
        map[key] = key -- yeah!
    end
    return map
end

-- TODO: the whole thing
local keyMap = makeKeyMap { "left", "right", "up", "down", "return", "escape", "delete", "backspace", "space" }

jui.love.gamepadConfig = {
    buttons = {
        ["a"] = "activate",
        ["b"] = "back",
    },
    moveXAxis = "leftx",
    moveYAxis = "lefty",
    deadzone = 0.2,
}

function jui.love.convertEvent(name, ...)
    if name == "mousemoved" then
        local x, y, dx, dy = ...
        return {name = "mousemove", x = x, y = y, dx = dx, dy = dy}
    elseif name == "mousewheel" then
        local x, y = ...
        return {name = "mousewheel", x = x, y = y}
    elseif name == "mousepressed" then
        local x, y, button = ...
        return {name = "mousedown", button = mouseButtonMap[button]}
    elseif name == "mousereleased" then
        local x, y, button = ...
        return {name = "mouseup", button = mouseButtonMap[button]}
    elseif name == "keypressed" then
        local key = ...
        return {name = "keydown", key = keyMap[key]}
    elseif name == "keyreleased" then
        local key = ...
        return {name = "keyup", key = keyMap[key]}
    elseif name == "gamepadpressed" then
        local joystick, button = ...
        local b = jui.love.gamepadConfig.buttons[button]
        if b then
            return {name = "controllerdown", joystick = joystick, button = b}
        end
    elseif name == "gamepadreleased" then
        local joystick, button = ...
        local b = jui.love.gamepadConfig.buttons[button]
        if b then
            return {name = "controllerup", joystick = joystick, button = b}
        end
    elseif name == "gamepadaxis" then
        local joystick, axis, value = ...
        if math.abs(value) < jui.love.gamepadConfig.deadzone then
            value = 0
        end
        if axis == jui.love.gamepadConfig.moveXAxis then
            return {name = "controllermove", axis = "x", value = value}
        elseif axis == jui.love.gamepadConfig.moveYAxis then
            return {name = "controllermove", axis = "y", value = value}
        end
    elseif name == "focus" then
        local focus = ...
        return {name = "focus", focus = focus}
    elseif name == "windowresized" then
        local width, height = ...
        return {name = "windowresized", width = width, height = height}
    end
end

function jui.backend.update()
    if jui.config.autoEvents then
        local winW, winH = love.graphics.getDimensions()
        if jui.windowSize.x ~= winW or jui.windowSize.y ~= winH then
            jui.love.resize(winW, winH)
        end

        local mx, my = love.mouse.getPosition()
        jui.inputState.mouse.x = jui.inputState.mouse.x or mx
        jui.inputState.mouse.y = jui.inputState.mouse.y or my
        if jui.inputState.mouse.x ~= mx or jui.inputState.mouse.y ~= my then
            jui.love.mousemoved(jui.inputState.mouse.x, jui.inputState.mouse.y,
                mx - jui.inputState.mouse.x, my - jui.inputState.mouse.y)
            jui.inputState.mouse.x = mx
            jui.inputState.mouse.y = my
        end

        local function mouseButtonEvent(name, loveButtonId)
            if jui.inputState.mouse[name] == nil then
                jui.inputState.mouse[name] = false
            end
            local state = love.mouse.isDown(loveButtonId)
            if jui.inputState.mouse[name] ~= state then
                if state then
                    jui.love.mousepressed(jui.inputState.mouse.x, jui.inputState.mouse.y, loveButtonId)
                else
                    jui.love.mousereleased(jui.inputState.mouse.x, jui.inputState.mouse.y, loveButtonId)
                end
                jui.inputState.mouse[name] = state
            end
        end
        mouseButtonEvent("left", 1)
        mouseButtonEvent("middle", 3)
        mouseButtonEvent("right", 2)

        -- no way to get mouse wheel!

        for loveKey, juiKey in pairs(keyMap) do
            if jui.inputState.keyboard[juiKey] == nil then
                jui.inputState.keyboard[juiKey] = false
            end
            local state = love.keyboard.isDown(loveKey)
            if jui.inputState.keyboard[juiKey] ~= state then
                if state then
                    jui.love.keypressed(loveKey)
                else
                    jui.love.keyreleased(loveKey)
                end
                jui.inputState.keyboard[juiKey] = state
            end
        end

        for _, joystick in ipairs(love.joystick.getJoysticks()) do
            if joystick:isGamepad() then
                jui.inputState.controllers[joystick] = jui.inputState.controllers[joystick] or {}
                for loveButton, juiButton in pairs(jui.love.gamepadConfig) do
                    local state = joystick:isGamepadDown(loveButton)
                    if jui.inputState.controllers[joystick].buttons[juiButton] ~= state then
                        if state then
                            jui.love.gamepadpressed(joystick, loveButton)
                        else
                            jui.love.gamepadreleased(joystick, loveButton)
                        end
                        jui.inputState.controllers[joystick].buttons[juiButton] = state
                    end
                end
                local xAxis = joystick:getGamepadAxis(jui.love.gamepadConfig.moveXAxis)
                if jui.inputState.controllers[joystick].axis.x ~= xAxis then
                    jui.gamepadaxis(joystick, jui.love.gamepadConfig.moveXAxis, xAxis)
                    jui.inputState.controllers[joystick].axis.x = xAxis
                end
                local yAxis = joystick:getGamepadAxis(jui.love.gamepadConfig.moveYAxis)
                if jui.inputState.controllers[joystick].axis.y ~= yAxis then
                    jui.gamepadaxis(joystick, jui.love.gamepadConfig.moveYAxis, yAxis)
                    jui.inputState.controllers[joystick].axis.y = yAxis
                end
            end
        end
    end
end

function jui.backend.setClipboardText(text)
    love.system.setClipboardText(text)
end

function jui.backend.getClipboardText(text)
    return love.system.getClipboardText(text)
end

function jui.backend.getWindowDimensions()
    return love.graphics.getDimensions()
end

function jui.backend.newFrame()
end

function jui.backend.getTextDimensions(font, text)
    font = font or jui.love.defaultFont
    return font:getWidth(text), font:getHeight()
end

function jui.backend.draw(commands)
    love.graphics.setColor(1, 1, 1, 1)
    local scissorX, scissorY, scissorW, scissorH = love.graphics.getScissor()
    for _, command in ipairs(commands) do
        if command.scissor then
            love.graphics.setScissor(command.scissor.x, command.scissor.y, command.scissor.w, command.scissor.h)
        else
            love.graphics.setScissor()
        end
        if command.type == "geometry" then
            jui.love.mesh:setTexture(command.texture)
            jui.love.mesh:setVertices(command.vertices)
            jui.love.mesh:setVertexMap(command.indices)
            love.graphics.draw(jui.love.mesh)
        elseif command.type == "text" then
            love.graphics.setColor(command.color)
            love.graphics.print(command.text, command.font or jui.love.defaultFont, command.x, command.y)
        end
    end
    love.graphics.setScissor(scissorX, scissorY, scissorW, scissorH)
end

return jui
