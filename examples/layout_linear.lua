local jui = require("jui.love").init()

-- A box without a parent has a virtual box the size of the whole window as its parent
local menu = jui.Box {
    id = "root",
    width = jui.pct(100),
    height = jui.pct(100),
    children = {
        jui.Box {
            id = "staggered",
            alignx = jui.alignx.center,
            aligny = jui.aligny.top,
            height = 120,
            margin = 20,
            layout = jui.layout.linear { direction = jui.direction.right },
            children = {
                jui.Button { label = "New Game", width = 200, height = 50, margin = 10, aligny = jui.aligny.top },
                jui.Button { label = "Continue", width = 200, height = 50, margin = 10, aligny = jui.aligny.center },
                jui.Button { label = "Exit", width = 200, height = 50, margin = 10, aligny = jui.aligny.bottom },
            }
        },
        jui.Box {
            id = "filled",
            alignx = jui.alignx.center,
            aligny = jui.aligny.bottom,
            width = jui.pct(70),
            margin = { bottom = 260 },
            layout = jui.layout.linear { direction = jui.direction.left, spacing = jui.spacing.even },
            children = {
                jui.Button { label = "New Game", width = jui.size.fill(2), height = 50, margin = 10 },
                jui.Button { label = "Continue", width = jui.size.fill, height = 50, margin = 10 },
                jui.Button { label = "Exit", width = jui.size.fill, height = 50, margin = 10 },
            }
        },
        jui.Box {
            id = "even",
            alignx = jui.alignx.center,
            aligny = jui.aligny.bottom,
            width = jui.pct(70),
            margin = { bottom = 180 },
            layout = jui.layout.linear { direction = jui.direction.left, spacing = jui.spacing.even },
            children = {
                jui.Button { label = "New Game", width = 200, height = 50, margin = 10 },
                jui.Button { label = "Continue", width = 200, height = 50, margin = 10 },
                jui.Button { label = "Exit", width = 200, height = 50, margin = 10 },
            }
        },
        jui.Box {
            id = "around",
            alignx = jui.alignx.center,
            aligny = jui.aligny.bottom,
            width = 800,
            margin = { bottom = 100 },
            layout = jui.layout.linear { direction = jui.direction.left, spacing = jui.spacing.around },
            children = {
                jui.Button { label = "New Game", width = 200, height = 50, margin = 10 },
                jui.Button { label = "Continue", width = 200, height = 50, margin = 10 },
                jui.Button { label = "Exit", width = 200, height = 50, margin = 10 },
            }
        },
        jui.Box {
            id = "between",
            alignx = jui.alignx.center,
            aligny = jui.aligny.bottom,
            width = 800,
            margin = { bottom = 20 },
            layout = jui.layout.linear { direction = jui.direction.left, spacing = jui.spacing.between },
            children = {
                jui.Button { label = "New Game", width = 200, height = 50, margin = 10 },
                jui.Button { label = "Continue", width = 200, height = 50, margin = 10 },
                jui.Button { label = "Exit", width = 200, height = 50, margin = 10 },
            }
        },
        jui.Box {
            id = "linear down",
            alignx = jui.alignx.right,
            aligny = jui.aligny.center,
            margin = { right = 20 },
            layout = jui.layout.linear { direction = jui.direction.down },
            children = {
                jui.Button { label = "New Game", width = jui.vw(20), height = 50, margin = 10, alignx = jui.alignx.right },
                jui.Button { label = "Continue", width = jui.vw(20), height = 50, margin = 10, alignx = jui.alignx.right },
                jui.Button { label = "Exit", width = jui.vw(20), height = 50, margin = 10, alignx = jui.alignx.right },
            }
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

function love.resized(width, height)
    menu:send(jui.love.convertEvent("windowresized", width, height))
end

function love.draw()
    jui.newFrame()
    menu:draw()
end
