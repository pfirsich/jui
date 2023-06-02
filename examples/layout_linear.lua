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
                jui.Box { id = "New Game", width = 200, height = 50, margin = 10, aligny = jui.aligny.top },
                jui.Box { id = "Continue", width = 200, height = 50, margin = 10, aligny = jui.aligny.center },
                jui.Box { id = "Exit", width = 200, height = 50, margin = 10, aligny = jui.aligny.bottom },
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
                jui.Box { id = "New Game", width = jui.size.fill(2), height = 50, margin = 10 },
                jui.Box { id = "Continue", width = jui.size.fill, height = 50, margin = 10 },
                jui.Box { id = "Exit", width = jui.size.fill, height = 50, margin = 10 },
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
                jui.Box { id = "New Game", width = 200, height = 50, margin = 10 },
                jui.Box { id = "Continue", width = 200, height = 50, margin = 10 },
                jui.Box { id = "Exit", width = 200, height = 50, margin = 10 },
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
                jui.Box { id = "New Game", width = 200, height = 50, margin = 10 },
                jui.Box { id = "Continue", width = 200, height = 50, margin = 10 },
                jui.Box { id = "Exit", width = 200, height = 50, margin = 10 },
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
                jui.Box { id = "New Game", width = 200, height = 50, margin = 10 },
                jui.Box { id = "Continue", width = 200, height = 50, margin = 10 },
                jui.Box { id = "Exit", width = 200, height = 50, margin = 10 },
            }
        },
        jui.Box {
            id = "linear down",
            alignx = jui.alignx.right,
            aligny = jui.aligny.center,
            margin = { right = 20 },
            width = 300,
            layout = jui.layout.linear { direction = jui.direction.down },
            -- offset = {x, y} -- manual override
            -- position = {x, y} -- even harder manual override, but you can use it with percentages
            children = {
                jui.Box { id = "New Game", width = 200, height = 50, margin = 10, alignx = jui.alignx.right },
                jui.Box { id = "Continue", width = 200, height = 50, margin = 10, alignx = jui.alignx.right },
                jui.Box { id = "Exit", width = 200, height = 50, margin = 10, alignx = jui.alignx.right },
            }
        }
    }
}

function love.update(dt)
    jui.update()
    menu:calculateLayout()
    --menu:update(love.timer.getTime())
end

function love.draw()
    jui.newFrame()
    menu:draw()
end
