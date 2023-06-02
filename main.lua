local examples = {}
local currentExampleIndex = 1

local function runExample(example)
    love.window.setTitle(example.name .. " - Use ctrl+left / ctrl+right to cycle through")
    -- use a fresh fenv every time
    example.fenv = {
        love = {
            window = love.window,
            keyboard = love.keyboard,
            mouse = love.mouse,
            joystick = love.joystick,
            graphics = love.graphics,
        },
        require = require,
    }
    setfenv(example.func, example.fenv)
    example.func()
    if example.fenv.love.load then
        example.fenv.love.load()
    end
end

local function currentExample()
    return examples[currentExampleIndex]
end

function love.load()
    -- keypressed is special, because we need to intercept it and load is special, because we need to do it on load
    local callbacks = {
        "draw", "update", "focus", "resize", "keyreleased", "mousemoved", "mousepressed",
        "mousereleased", "wheelmoved", "gamepadaxis", "gamepadpressed", "gamepadreleased",
    }
    for _, callback in ipairs(callbacks) do
        love[callback] = function(...)
            if currentExample().fenv.love[callback] then
                currentExample().fenv.love[callback](...)
            end
        end
    end

    local exampleFiles = love.filesystem.getDirectoryItems("examples/")
    table.sort(exampleFiles)
    for _, file in ipairs(exampleFiles) do
        local example = {
            name = file,
            func = love.filesystem.load("examples/" .. file),
        }
        table.insert(examples, example)
    end
    runExample(currentExample())
end

function love.keypressed(key, ...)
    local ctrl = love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")
    if ctrl and key == "left" then
        currentExampleIndex = currentExampleIndex - 1
        if currentExampleIndex < 1 then
            currentExampleIndex = #examples
        end
        runExample(currentExample())
    elseif ctrl and key == "right" then
        currentExampleIndex = currentExampleIndex + 1
        if currentExampleIndex > #examples then
            currentExampleIndex = 1
        end
        runExample(currentExample())
    end

    if currentExample().fenv.love.keypressed then
        currentExample().fenv.love.keypressed(key, ...)
    end
end
