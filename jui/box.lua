local requirePrefix = (...):match("(.+%.)[^%.]+$") or ""
local class = require(requirePrefix .. "class")
local draw = require(requirePrefix .. "draw")
local jui = require(requirePrefix .. "jui")
local util = require(requirePrefix .. "util")

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
    util.addFallback(params, Box.defaultProperties or {})
    self.id = params.id or getNextId() -- this is not unique. Keep them unique yourself
    self.layout = params.layout or jui.layout.direct
    if params.children and #params.children > 0 then
        self.width = params.width or jui.size.fit
        self.height = params.height or jui.size.fit
    else
        self.width = params.width or jui.size.fill
        self.height = params.height or jui.size.fill
    end
    self.hidden = params.hidden or false
    self.alignx = params.alignx or jui.alignx.left
    self.aligny = params.aligny or jui.aligny.top
    self.margin = parseLRTB(params.margin or {})
    self.padding = parseLRTB(params.padding or {})
    self.children = params.children or {}

    if self.layout.layoutType == jui.layoutType.linear then
        assert(self.layout.direction, "'direction' is mandatory for linear layout")
        self.layout.spacing = self.layout.spacing or jui.spacing.even
    elseif self.layout.layoutType == jui.layoutType.grid then
        assert(self.width ~= jui.size.fit and self.height ~= jui.size.fit)
        assert(not util.isUnit(self.width, jui.size.fill) and not util.isUnit(self.height, jui.size.fill))
        assert(self.layout.rows, "'rows' is mandatory for grid layout")
        if type(self.layout.rows) == "number" then
            self.layout.rows = util.repeatValue(1, self.layout.rows)
        end
        assert(self.layout.columns, "'columns' is mandatory for grid layout")
        if type(self.layout.columns) == "number" then
            self.layout.columns = util.repeatValue(1, self.layout.columns)
        end
        self.layout.rowGap = self.layout.rowGap or 0
        self.layout.columnGap = self.layout.columnGap or 0
    end

    self.gridCell = params.gridCell
    if self.gridCell then
        assert(self.gridCell.row)
        if type(self.gridCell.row) == "number" then
            self.gridCell.row = {self.gridCell.row, self.gridCell.row}
        end
        assert(self.gridCell.column)
        if type(self.gridCell.column) == "number" then
            self.gridCell.column = {self.gridCell.column, self.gridCell.column}
        end
    end

    for _, child in ipairs(self.children) do
        child.parent = self
    end

    self.eventHandlers = {}
    self:registerHandler("windowresized", Box.onWindowResized)
end

-- Finds the **first** child (depth first) that has a matching id.
function Box:findChild(id)
    for _, child in ipairs(self.children) do
        if child.id == id then
            return child
        end
        local found = child:findChild(id)
        if found then
            return found
        end
    end
    return nil
end

function Box:getChild(index)
    return self.children[index]
end

function Box:onWindowResized(event)
    jui.windowSize.x, jui.windowSize.y = event.width, event.height
    if self.parent == nil then
        self:calculateLayout()
    end
end

function Box:getClipBox()
    if self._clipBox == nil then
        return nil
    end
    return self._clipBox
end

function Box:getInnerBox()
    if self._clipBox == nil then
        return nil
    end
    return {
        x = self._clipBox.x + padding.left,
        y = self._clipBox.y + padding.top,
        w = self._clipBox.w - padding.left - padding.right,
        h = self._clipBox.h - padding.top - padding.bottom,
    }
end

function Box:getOuterBox()
    if self._clipBox == nil then
        return nil
    end
    return {
        x = self._clipBox.x - margin.left,
        y = self._clipBox.y - margin.top,
        w = self._clipBox.w + margin.left + margin.right,
        h = self._clipBox.h + margin.top + margin.bottom,
    }
end

local function dirToAxis(dir)
    if dir == jui.direction.left then
        return "x", -1
    elseif dir == jui.direction.right then
        return "x", 1
    elseif dir == jui.direction.up then
        return "y", -1
    elseif dir == jui.direction.down then
        return "y", 1
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

function Box:positionDirectly(parentX, parentY, parentW, parentH)
    local px, py, pw, ph = parentX, parentY, parentW, parentH
    local w, h = self._clipBox.w, self._clipBox.h

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

    self._clipBox.x, self._clipBox.y = x, y
end

local cross = {
    x = "y",
    y = "x",
    w = "h",
    h = "w",
}

local size = {
    x = "w",
    y = "h",
}

local sizeLong = {
    x = "width",
    y = "height",
}

function Box:positionChildren()
    local selfX, selfY, selfW, selfH = self._clipBox.x, self._clipBox.y,
                                       self._clipBox.w, self._clipBox.h
    if self.layout.layoutType == jui.layoutType.linear then
        local mainAxis, dir = dirToAxis(self.layout.direction)

        -- We do this to position on the cross axis only
        for _, child in ipairs(self.children) do
            child:positionDirectly(selfX, selfY, selfW, selfH)
        end

        local selfPos = mainAxis == "x" and selfX or selfY
        local selfSize = mainAxis == "x" and selfW or selfH

        local childrenW = self:getChildrenSizeAxis("x", true)
        local childrenH = self:getChildrenSizeAxis("y", true)
        local childrenSize = mainAxis == "x" and childrenW or childrenH
        local leftOverSize = selfSize - childrenSize

        local cursor = dir > 0 and selfPos or selfPos + selfSize
        local childSpacing
        if self.layout.spacing == jui.spacing.between then
            -- for #self.children == 1, this variable is unused, so inf is fine
            childSpacing = leftOverSize / (#self.children - 1)
        elseif self.layout.spacing == jui.spacing.around then
            cursor = cursor + dir * leftOverSize / 2
            childSpacing = 0
        elseif self.layout.spacing == jui.spacing.even then
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
                child._clipBox[mainAxis] = cursor - child._clipBox[size[mainAxis]]
            else
                child._clipBox[mainAxis] = cursor
            end
            cursor = cursor + dir * child._clipBox[size[mainAxis]]
            cursor = cursor + dir * childSpacing
        end
    elseif self.layout.layoutType == jui.layoutType.grid then
        for _, child in ipairs(self.children) do
            child._clipBox.x = selfX + self._gridCellRanges.x[child.gridCell.column[1]].min
            child._clipBox.y = selfY + self._gridCellRanges.y[child.gridCell.row[1]].min
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

function Box:getParent()
    if self.parent then
        return self.parent
    else
        local window = Box {id = "window"}
        -- Need the child for 'fill', which does parent:getChildrenSize(), but we don't pass it to the constructor
        -- because then self would have .parent = window.
        window.children = {self}
        window._clipBox = {x = 0, y = 0, w = jui.windowSize.x, h = jui.windowSize.y}
        return window
    end
end

local function getFillWeight(size)
    if size == jui.size.fill then
        return 1
    elseif util.isUnit(size, "fill") then
        return size.value
    else
        return nil
    end
end

local function isParentDetermined(size)
    return util.isUnit(size, "pct") or isFill(size)
end

function Box:getChildrenSizeAxis(axis, includeFillChildren)
    if self.layout.layoutType == jui.layoutType.direct then
        assert(false, "Not Implemented: boxes with dynamic size ('fill', 'fit') and layout 'direct'")
        for _, child in ipairs(self.children) do
            child:calculateSizeAxis(axis)
        end
        -- TODO: Find the biggest box that can fit all children!
        return self.width, self.height
    elseif self.layout.layoutType == jui.layoutType.linear then
        local childrenSizeMain, childrenSizeCross = 0, 0
        local mainAxis, dir = dirToAxis(self.layout.direction)
        if axis == mainAxis then
            local childrenSizeMain = 0

            for i = 1, #self.children do
                local child = self.children[i]
                -- We have to include the margin even for children with fill, so the fillable space does not include them
                local margin, _ = getMargins(child.margin, mainAxis, dir)
                if i > 1 then
                    local _, prevEndMargin = getMargins(self.children[i - 1].margin, mainAxis, dir)
                    margin = math.max(margin, prevEndMargin)
                end
                childrenSizeMain = childrenSizeMain + margin
                -- I am not sure if this is the right check, but for fill or fit, you want to skip fill children
                if includeFillChildren or getFillWeight(child[sizeLong[axis]]) == nil then
                    child:calculateSizeAxis(axis)
                    childrenSizeMain = childrenSizeMain + child._clipBox[size[mainAxis]]
                end
            end

            if #self.children > 0 then
                local _, endMargin = getMargins(self.children[#self.children].margin, mainAxis, dir)
                childrenSizeMain = childrenSizeMain + endMargin
            end

            return childrenSizeMain
        else
            local childrenSizeCross = 0

            for i = 1, #self.children do
                local child = self.children[i]
                local crossMarginStart, crossMarginEnd = getMargins(child.margin, cross[mainAxis], dir)
                local childSizeCross = crossMarginStart + crossMarginEnd
                if includeFillChildren or getFillWeight(child[sizeLong[axis]]) == nil then
                    child:calculateSizeAxis(axis)
                    childSizeCross = childSizeCross + child._clipBox[size[cross[mainAxis]]]
                end
                childrenSizeCross = math.max(childrenSizeCross, childSizeCross)
            end

            return childrenSizeCross
        end
    elseif self.layout.layoutType == jui.layoutType.grid then
        assert(false)
    end
end

function Box:resetLayout()
    self._clipBox = nil
    self._childFillSpace = nil
    self._gridCellRanges = nil

    for _, child in ipairs(self.children) do
        child:resetLayout()
    end
end

function Box:getChildFillSpace(axis)
    if self._childFillSpace then
        return self._childFillSpace
    end

    local weightSum = 0
    for _, child in ipairs(self.children) do
        local weight = getFillWeight(child[sizeLong[axis]])
        if weight then
            weightSum = weightSum + weight
        end
    end

    assert(self._clipBox[size[axis]])
    local childrenSize = self:getChildrenSizeAxis(axis, false)
    self._childFillSpace = util.round((self._clipBox[size[axis]] - childrenSize) / weightSum)
    return self._childFillSpace
end

function Box:calculateGrid(axis)
    assert(self.layout.layoutType == jui.layoutType.grid)
    if self._gridCellRanges and self._gridCellRanges[axis] then
        return
    end
    self._gridCellRanges = self._gridCellRanges or {}
    self._gridCellRanges[axis] = {}
    local cells = self.layout[axis == "x" and "rows" or "columns"]
    local weightSum = 0
    for i = 1, #cells do
        weightSum = weightSum + cells[i]
    end
    local gapSize = self.layout[axis == "x" and "columnGap" or "rowGap"]
    local noGapsSize = self._clipBox[size[axis]] - gapSize * (#cells - 1)
    local cursor = 0
    for i = 1, #cells do
        local size = noGapsSize / weightSum * cells[i]
        self._gridCellRanges[axis][i] = {min = cursor, max = cursor + size}
        cursor = cursor + size + gapSize
    end
end

function Box:calculateSizeAxis(axis)
    local sz = size[axis]
    if self._clipBox == nil then
        self._clipBox = {}
    end
    if self._clipBox[sz] then
        return
    end

    local parent = self:getParent()

    if parent.layout.layoutType == jui.layoutType.grid then
        parent:calculateGrid(axis)
        local cell = self.gridCell[axis == "x" and "column" or "row"]
        self._clipBox[sz] = parent._gridCellRanges[axis][cell[2]].max - parent._gridCellRanges[axis][cell[1]].min
    else
        local size = axis == "x" and self.width or self.height
        if type(size) == "number" then
            self._clipBox[sz] = size
        elseif util.isUnit(size, "vw") then
            self._clipBox[sz] = util.round(jui.windowSize.x * size.value / 100)
        elseif util.isUnit(size, "vh") then
            self._clipBox[sz] = util.round(jui.windowSize.y * size.value / 100)
        elseif util.isUnit(size, "pct") then
            assert(parent._clipBox[sz], "Child has pct size, but parent doesn't have a size") -- parent-determined
            self._clipBox[sz] = util.round(parent._clipBox[sz] * size.value / 100)
        elseif getFillWeight(size) then
            assert(parent._clipBox[sz]) -- parent-determined
            self._clipBox[sz] = parent:getChildFillSpace(axis) * getFillWeight(size)
        elseif size == jui.size.fit then
            self._clipBox[sz] = self:getChildrenSizeAxis(axis, true)
        end
    end
end

function Box:calculateSize()
    self:calculateSizeAxis("x")
    self:calculateSizeAxis("y")

    for _, child in ipairs(self.children) do
        child:calculateSize()
    end
end

function Box:calculateLayout()
    self:resetLayout()
    self:calculateSize()

    self:positionDirectly(0, 0, jui.windowSize.x, jui.windowSize.y)
    self:positionChildren()
end

function Box:registerHandler(eventName, handler)
    if self.eventHandlers[eventName] == nil then
        self.eventHandlers[eventName] = {}
    end
    table.insert(self.eventHandlers[eventName], handler)
end

function Box:send(event)
    for _, handler in ipairs(self.eventHandlers[event.name] or {}) do
        handler(self, event)
    end
    for _, child in ipairs(self.children) do
        child:send(event)
    end
end

function Box:drawElement()
    if jui.config.debugDraw then
        draw.debugBox(self._clipBox.x, self._clipBox.y,
        self._clipBox.w, self._clipBox.h)
        jui.backend.draw({
            {type = "text", color = {1, 1, 1, 1}, text = self.id, x = self._clipBox.x, y = self._clipBox.y}
        })

        if self.layout.layoutType == jui.layoutType.grid then
            -- TODO: Use draw.line as soon as I have it
            for i = 1, #self.layout.rows do
                local yMin = self._clipBox.y + self._gridCellRanges.y[i].min
                love.graphics.line(self._clipBox.x, yMin, self._clipBox.x + self._clipBox.w, yMin)
                local yMax = self._clipBox.y + self._gridCellRanges.y[i].max
                love.graphics.line(self._clipBox.x, yMax, self._clipBox.x + self._clipBox.w, yMax)
            end
            for i = 1, #self.layout.columns do
                local xMin = self._clipBox.x + self._gridCellRanges.x[i].min
                love.graphics.line(xMin, self._clipBox.y, xMin, self._clipBox.y + self._clipBox.h)
                local xMax = self._clipBox.x + self._gridCellRanges.x[i].max
                love.graphics.line(xMax, self._clipBox.y, xMax, self._clipBox.y + self._clipBox.h)
            end
        end
    end
end

function Box:draw()
    if self._clipBox == nil then
        self:calculateLayout()
    end

    self:drawElement()

    for _, child in ipairs(self.children) do
        child:draw(true)
    end
end

return Box
