local jui = require("jui.love").init()

-- A box without a parent has a virtual box the size of the whole window as its parent
local winW, winH = love.graphics.getDimensions()
local menu = jui.Box {
    width = winW, -- can't do percent sizes yet, which would be nice here
    height = winH,
    children = {
        jui.Box {
            alignx = jui.alignx.center,
            aligny = jui.aligny.top,
            height = 120,
            margin = 20,
            flowDirection = jui.direction.right,
            children = {
                jui.Box { id = "New Game", width = 200, height = 50, margin = 10, aligny = jui.aligny.top },
                jui.Box { id = "Continue", width = 200, height = 50, margin = 10, aligny = jui.aligny.center },
                jui.Box { id = "Exit", width = 200, height = 50, margin = 10, aligny = jui.aligny.bottom },
            }
        },
        jui.Box {
            alignx = jui.alignx.center,
            aligny = jui.aligny.bottom,
            width = 800,
            margin = { bottom = 180 },
            flowDirection = jui.direction.left,
            spacing = jui.spacing.even,
            children = {
                jui.Box { id = "New Game", width = 200, height = 50, margin = 10 },
                jui.Box { id = "Continue", width = 200, height = 50, margin = 10 },
                jui.Box { id = "Exit", width = 200, height = 50, margin = 10 },
            }
        },
        jui.Box {
            alignx = jui.alignx.center,
            aligny = jui.aligny.bottom,
            width = 800,
            margin = { bottom = 100 },
            flowDirection = jui.direction.left,
            spacing = jui.spacing.around,
            children = {
                jui.Box { id = "New Game", width = 200, height = 50, margin = 10 },
                jui.Box { id = "Continue", width = 200, height = 50, margin = 10 },
                jui.Box { id = "Exit", width = 200, height = 50, margin = 10 },
            }
        },
        jui.Box {
            alignx = jui.alignx.center,
            aligny = jui.aligny.bottom,
            width = 800,
            margin = { bottom = 20 },
            flowDirection = jui.direction.left,
            spacing = jui.spacing.between,
            children = {
                jui.Box { id = "New Game", width = 200, height = 50, margin = 10 },
                jui.Box { id = "Continue", width = 200, height = 50, margin = 10 },
                jui.Box { id = "Exit", width = 200, height = 50, margin = 10 },
            }
        },
        jui.Box {
            alignx = jui.alignx.right,
            aligny = jui.aligny.center,
            margin = { right = 20 },
            width = 300,
            flowDirection = jui.direction.down,
            -- overlap = lrbt (negative margin)?
            -- padding = lrbt
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
    --menu:update(love.timer.getTime())
end

function love.draw()
    jui.newFrame()
    menu:draw()
end
