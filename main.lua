local examples = {}
local currentExampleIndex = 1

local function currentExample()
    return examples[currentExampleIndex]
end

local function selectExample(index)
    if type(index) == "string" then
        for i, example in ipairs(examples) do
            if example.name == index then index = i end
        end
    end

    currentExampleIndex = index
    local example = currentExample()
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
    for i, file in ipairs(exampleFiles) do
        local example = {
            name = file,
            func = love.filesystem.load("examples/" .. file),
        }
        table.insert(examples, example)
    end

    selectExample("layout_linear.lua")
end

function love.keypressed(key, ...)
    local ctrl = love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")
    if ctrl and key == "left" then
        local idx = currentExampleIndex - 1
        if idx < 1 then
            idx = #examples
        end
        selectExample(idx)
    elseif ctrl and key == "right" then
        local idx = currentExampleIndex + 1
        if idx > #examples then
            idx = 1
        end
        selectExample(idx)
    end

    if currentExample().fenv.love.keypressed then
        currentExample().fenv.love.keypressed(key, ...)
    end
end
