local jui = require("jui.love").init()

-- A box without a parent has a virtual box the size of the whole window as its parent
jui.Button.defaultProperties = {onActivate = function(button) print(button.label) end}
local menu = jui.Box {
    alignx = jui.alignx.center,
    aligny = jui.aligny.center,
    width = jui.vw(50),
    height = jui.vw(50),
    layout = jui.layout.grid { rows = {2, 1, 1, 1}, columns = 4, rowGap = 10, columnGap = 10 },
    children = {
        jui.Button {label = "New Game", gridCell = {row = {1, 2}, column = {1, 2}}},
        jui.Button {label = "Continue", gridCell = {row = 3, column = 4}},
        jui.Button {label = "Exit", gridCell = {row = 4, column = 3}},
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
