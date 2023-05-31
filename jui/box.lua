local requirePrefix = (...):match("(.+%.)[^%.]+$") or ""
local class = require(requirePrefix .. "class")
local draw = require(requirePrefix .. "draw")
local jui = require(requirePrefix .. "jui")

local Box = class("Box")

local function parseLRTB(value)
    if type(value) == "number" then
        return {left = value, right = value, top = value, bottom = value}
    end
    local lrtb = {
        left = value.left or 0,
        right = value.right or 0,
        top = value.top or 0,
        bottom = value.bottom or 0,
    }
    if value.x then
        lrtb.left, lrtb.right = value.x, value.x
    end
    if value.y then
        lrtb.top, lrtb.bottom = value.y, value.y
    end
    return lrtb
end

local idCounter = 1
local function getNextId()
    local id = idCounter
    idCounter = idCounter + 1
    return tostring(id)
end

function Box:initialize(params)
    self.id = params.id or getNextId()
    self.width = params.width or jui.size.fit
    self.height = params.height or jui.size.fit
    self.hidden = params.hidden or false
    self.alignx = params.alignx or jui.alignx.left
    self.aligny = params.aligny or jui.aligny.top
    self.margin = parseLRTB(params.margin or {})
    self.flowDirection = params.flowDirection or nil
    self.spacing = params.spacing or jui.spacing.even
    self.children = params.children or {}

    for _, child in ipairs(self.children) do
        child.parent = self
    end

    self._calculatedBox = {}
end

local cross = {
    x = "y",
    y = "x",
    w = "h",
    h = "w",
}

local function dirToAxis(dir)
    if dir == jui.direction.left then
        return "x", "w", -1
    elseif dir == jui.direction.right then
        return "x", "w", 1
    elseif dir == jui.direction.up then
        return "y", "h", -1
    elseif dir == jui.direction.down then
        return "y", "h", 1
    end
end

local function getMargins(margin, axis, dir)
    if axis == "x" then
        if dir > 0 then
            return margin.left, margin.right
        else
            return margin.right, margin.left
        end
    else
        if dir > 0 then
            return margin.top, margin.bottom
        else
            return margin.bottom, margin.top
        end
    end
end

function Box:getChildrenSize()
    if self.flowDirection then
        local childrenSizeMain, childrenSizeCross = 0, 0
        local mainAxis, mainAxisSize, dir, crossAxis = dirToAxis(self.flowDirection)
        for i = 1, #self.children do
            local child = self.children[i]
            child:calculateSize()
            local margin, _ = getMargins(child.margin, mainAxis, dir)
            if i > 1 then
                local _, prevEndMargin = getMargins(self.children[i - 1].margin, mainAxis, dir)
                margin = math.max(margin, prevEndMargin)
            end
            childrenSizeMain = childrenSizeMain + child._calculatedBox[mainAxisSize] + margin

            local crossMarginStart, crossMarginEnd = getMargins(child.margin, cross[mainAxis], dir)
            childrenSizeCross = math.max(childrenSizeCross,
                child._calculatedBox[cross[mainAxisSize]] + crossMarginStart + crossMarginEnd)
        end

        if #self.children > 0 then
            local _, endMargin = getMargins(self.children[#self.children].margin, mainAxis, dir)
            childrenSizeMain = childrenSizeMain + endMargin
        end

        if mainAxis == "x" then
            return childrenSizeMain, childrenSizeCross
        else
            return childrenSizeCross, childrenSizeMain
        end
    else
        -- TODO: Find the biggest box that can fit all children!
        for _, child in ipairs(self.children) do
            child:calculateSize()
        end
        assert(type(self.width) == "number" and type(self.height) == "number")
        return self.width, self.height
    end
end

function Box:calculateSize()
    local childrenW, childrenH = self:getChildrenSize()

    if self.width == jui.size.fit then
        self._calculatedBox.w = childrenW
    else
        self._calculatedBox.w = self.width
    end

    if self.height == jui.size.fit then
        self._calculatedBox.h = childrenH
    else
        self._calculatedBox.h = self.height
    end
end

function Box:positionDirectly(parentX, parentY, parentW, parentH)
    local px, py, pw, ph = parentX, parentY, parentW, parentH
    local w, h = self._calculatedBox.w, self._calculatedBox.h

    local x = 0
    if self.alignx == jui.alignx.left then
        x = px + self.margin.left
    elseif self.alignx == jui.alignx.center then
        x = px + pw/2 - w/2
    elseif self.alignx == jui.alignx.right then
        x = px + pw - w - self.margin.right
    end

    local y = 0
    if self.aligny == jui.aligny.top then
        y = py + self.margin.top
    elseif self.aligny == jui.aligny.center then
        y = py + ph/2 - h/2
    elseif self.aligny == jui.aligny.bottom then
        y = py + ph - h - self.margin.bottom
    end

    self._calculatedBox.x, self._calculatedBox.y = x, y
end

function Box:positionChildren()
    local selfX, selfY, selfW, selfH = self._calculatedBox.x, self._calculatedBox.y,
                                       self._calculatedBox.w, self._calculatedBox.h
    if self.flowDirection then
        local mainAxis, mainAxisSize, dir = dirToAxis(self.flowDirection)

        -- We do this to position on the cross axis only
        for _, child in ipairs(self.children) do
            child:positionDirectly(selfX, selfY, selfW, selfH)
        end

        local selfPos = mainAxis == "x" and selfX or selfY
        local selfSize = mainAxis == "x" and selfW or selfH

        local childrenW, childrenH = self:getChildrenSize()
        local childrenSize = mainAxis == "x" and childrenW or childrenH
        local leftOverSize = selfSize - childrenSize

        local cursor = dir > 0 and selfPos or selfPos + selfSize
        local childSpacing
        if self.spacing == jui.spacing.between then
            -- for #self.children == 1, this variable is unused, so inf is fine
            childSpacing = leftOverSize / (#self.children - 1)
        elseif self.spacing == jui.spacing.around then
            cursor = cursor + dir * leftOverSize / 2
            childSpacing = 0
        elseif self.spacing == jui.spacing.even then
            childSpacing = leftOverSize / (#self.children + 1)
            cursor = cursor + dir * childSpacing
        end

        for i = 1, #self.children do
            local child = self.children[i]
            local margin, _ = getMargins(child.margin, mainAxis, dir)
            if i > 1 then
                local _, prevEndMargin = getMargins(self.children[i - 1].margin, mainAxis, dir)
                margin = math.max(margin, prevEndMargin)
            end
            cursor = cursor + dir * margin
            if dir < 0 then
                child._calculatedBox[mainAxis] = cursor - child._calculatedBox[mainAxisSize]
            else
                child._calculatedBox[mainAxis] = cursor
            end
            cursor = cursor + dir * child._calculatedBox[mainAxisSize]
            cursor = cursor + dir * childSpacing
        end
    else
        for _, child in ipairs(self.children) do
            child:positionDirectly(selfX, selfY, selfW, selfH)
        end
    end

    for _, child in ipairs(self.children) do
        child:positionChildren()
    end
end

function Box:draw(isChild)
    if not isChild then
        -- the sizes bubble up (ask the children)
        self:calculateSize()

        -- the positions trickle down (ask the parent)
        self:positionDirectly(0, 0, jui.windowSize.x, jui.windowSize.y)
        self:positionChildren()
    end

    draw.debugBox(self._calculatedBox.x, self._calculatedBox.y,
        self._calculatedBox.w, self._calculatedBox.h)
    jui.backend.draw({
        {type = "text", color = {1, 1, 1, 1}, text = self.id, x = self._calculatedBox.x, y = self._calculatedBox.y}
    })

    for _, child in ipairs(self.children) do
        child:draw(true)
    end
end

return Box
