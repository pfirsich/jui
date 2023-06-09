local requirePrefix = (...):match("(.+%.)[^%.]+$") or ""
local class = require(requirePrefix .. "class")
local draw = require(requirePrefix .. "draw")
local jui = require(requirePrefix .. "jui")
local util = require(requirePrefix .. "util")
local Box = require(requirePrefix .. "box")
local style = require(requirePrefix .. "style")

local Button = class("Button", Box)

local defaultStyle = {
    {
        selector = {},
        color = {0.75, 0.75, 0.75, 1.0},
        textColor = {0, 0, 0, 1},
        borderRadiusTopLeft = 10,
        borderRadiusTopRight = 10,
        borderRadiusBottomLeft = 10,
        borderRadiusBottomRight = 10,
        borderColor = {0, 0, 0, 1},
        borderWidth = 2,
    },
    {
        selector = {hovered = true},
        color = {1.0, 1.0, 1.0, 1.0},
    },
    {
        selector = {pressed = true},
        color = {1.0, 1.0, 0.75, 1.0},
    }
}

function Button:initialize(params)
    Box.initialize(self, params)
    util.addFallback(params, Button.defaultProperties or {})
    self.label = params.label or ""
    self.textAlignx = params.textAlignx or jui.alignx.center
    self.textAligny = params.textAligny or jui.aligny.center
    self.onEnter = params.onEnter or util.nop
    self.onExit = params.onExit or util.nop
    self.onActivate = params.onActivate or util.nop
    self.style = {}
    util.append(self.style, defaultStyle)
    util.append(self.style, params.style or {})

    self.hovered = false
    self.pressed = false

    self:registerHandler("mousemove", Button.onMouseMove)
    self:registerHandler("mousedown", Button.onMouseDown)
    self:registerHandler("mouseup", Button.onMouseUp)
end

function Button:contains(x, y)
    if self._clipBox == nil then
        return false
    end
    return x > self._clipBox.x and x < self._clipBox.x + self._clipBox.w
        and y > self._clipBox.y and y < self._clipBox.y + self._clipBox.h
end

function Button:onMouseMove(event)
    if self._clipBox == nil then
        return
    end
    local hoveredBefore = self.hovered
    self.hovered = self:contains(event.x, event.y)
    if not hoveredBefore and self.hovered then
        self:onEnter()
    elseif hoveredBefore and not self.hovered then
        self:onExit()
    end
end

function Button:onMouseDown(event)
    local pressedBefore = self.pressed
    self.pressed = self.hovered and jui.inputConfig.mouse.buttons[event.button]
    if jui.inputConfig.mouse.edge == "down" and not pressedBefore and self.pressed then
        self:onActivate()
    end
end

function Button:onMouseUp(event)
    local released = self.hovered and self.pressed and event.button == "left"
    self.pressed = false
    if jui.inputConfig.mouse.edge == "up" and released then
        self:onActivate()
    end
end

function Button:drawElement()
    local s = style.compute(self)
    local rad = {
        topLeft = s.borderRadiusTopLeft,
        bottomLeft = s.borderRadiusBottomLeft,
        bottomRight = s.borderRadiusBottomRight,
        topRight = s.borderRadiusTopRight,
    }
    local border = {
        color = s.borderColor,
        width = s.borderWidth,
    }
    draw.box(s.color, s.texture, self._clipBox.x, self._clipBox.y, self._clipBox.w, self._clipBox.h, rad, border)
    draw.alignText(self.label, s.textColor, self.textAlignx, self.textAligny,
        self._clipBox.x, self._clipBox.y, self._clipBox.w, self._clipBox.h)
end

return Button
