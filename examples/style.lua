local jui = require("jui.love").init()
local draw = require("jui.draw")

jui.Button.defaultProperties = {onActivate = function(button) print(button.label) end}
local menu = jui.Button {
    label = "Button",
    alignx = jui.alignx.center,
    aligny = jui.aligny.center,
    width = 300,
    height = 100,
    -- All matching rules will be applied, top to bottom
    style = {
        {
            selector = {},
            color = {1.0, 1.0, 0.2, 1.0},
            textColor = {0, 0, 0, 1},
        },
        {
            selector = {hovered = true},
            color = {1.0, 1.0, 0.7, 1.0},
            textColor = {0, 0, 0, 1},
            borderRadiusTopLeft = 25,
            borderRadiusBottomRight = 25,
        },
        {
            selector = {pressed = true},
            color = {1.0, 1.0, 1.0, 1.0},
            textColor = {1, 0, 0, 1},
            texture = love.graphics.newImage("assets/tileable_grass_01.png"),
        },
        {
            selector = {pressed = true, hovered = false},
            color = {0.1, 0.1, 0.1, 1.0},
            textColor = {1, 1, 1, 1},
        }
    }
}

function love.mousemoved(x, y, dx, dy)
    menu:send(jui.love.convertEvent("mousemoved", x, y, dx, dy))
end

function love.mousepressed(x, y, button)
    menu:send(jui.love.convertEvent("mousepressed", x, y, button))
end

function love.mousereleased(x, y, button)
    menu:send(jui.love.convertEvent("mousereleased", x, y, button))
end

function love.resize(width, height)
    menu:send(jui.love.convertEvent("windowresized", width, height))
end

function love.draw()
    jui.newFrame()
    menu:draw()
end
