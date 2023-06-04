local jui = require("jui.love").init()
local draw = require("jui.draw")

-- A box without a parent has a virtual box the size of the whole window as its parent
jui.Button.defaultProperties = {onActivate = function(button) print(button.label) end}
local menu = jui.Button {
    label = "Button",
    alignx = jui.alignx.center,
    aligny = jui.aligny.center,
    width = 300,
    height = 300,
}

function menu:contains(x, y)
    local clip = self:getClipBox()
    if clip == nil then
        return false
    end
    local dx = clip.x + clip.w/2 - x
    local dy = clip.y + clip.h/2 - y
    return dx*dx + dy*dy < clip.w/2*clip.w/2
end

function menu:drawElement()
    local color = {1, 1, 1, 1}
    if self.pressed then
        color = {0.75, 0, 0, 1}
    elseif self.hovered then
        color = {1, 0, 0, 1}
    end
    local clip = self:getClipBox()
    love.graphics.setColor(color)
    love.graphics.circle("fill", clip.x + clip.w/2, clip.y + clip.h/2, clip.w/2)
    draw.alignText(self.label, {0, 0, 0, 1}, jui.alignx.center, jui.aligny.center, clip.x, clip.y, clip.w, clip.h)
end

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
