local requirePrefix = (...):match("(.+%.)[^%.]+$") or ""
local jui = require(requirePrefix .. "jui")
local util = require(requirePrefix .. "util")

local draw = {}

local function parseColor(hex)
    assert(hex:sub(1, 1) == '#')
    local r = tonumber(hex:sub(2, 3), 16) / 255.0
    local g = tonumber(hex:sub(4, 5), 16) / 255.0
    local b = tonumber(hex:sub(6, 7), 16) / 255.0
    return {r, g, b, 1.0}
end

local colors = {
    parseColor("#696969"), -- dimgray
    parseColor("#2e8b57"), -- seagreen
    parseColor("#8b0000"), -- darkred
    parseColor("#808000"), -- olive
    parseColor("#00008b"), -- darkblue
    parseColor("#ff0000"), -- red
    parseColor("#ff8c00"), -- darkorange
    parseColor("#ffd700"), -- gold
    parseColor("#ba55d3"), -- mediumorchid
    parseColor("#00ff7f"), -- springgreen
    parseColor("#0000ff"), -- blue
    parseColor("#f08080"), -- lightcoral
    parseColor("#adff2f"), -- greenyellow
    parseColor("#ff00ff"), -- fuchsia
    parseColor("#1e90ff"), -- dodgerblue
    parseColor("#dda0dd"), -- plum
    parseColor("#87ceeb"), -- skyblue
    parseColor("#ff1493"), -- deeppink
    parseColor("#7fffd4"), -- aquamarine
    parseColor("#ffdab9"), -- peachpuff
}

local nextColorIndex = 1
local function getNextColor()
    local idx = nextColorIndex
    nextColorIndex = nextColorIndex + 1
    if nextColorIndex > #colors then
        nextColorIndex = 1
    end
    return colors[idx]
end

function draw.newFrame()
    nextColorIndex = 1
end

function draw.simpleBox(color, x, y, w, h)
    local r, g, b, a = unpack(color)
    local vertices = {
        {x,     y,       0, 0,   r, g, b, a},
        {x,     y + h,   0, 1,   r, g, b, a},
        {x + w, y + h,   1, 1,   r, g, b, a},
        {x + w, y,       1, 0,   r, g, b, a},
    }
    local indices = {
        1, 2, 3,
        1, 3, 4,
    }
    jui.backend.draw({
        {type = "geometry", texture = nil, vertices = vertices, indices = indices}
    })
end

function draw.box(color, texture, x, y, w, h, cornerRadius, border)
    local r, g, b, a = unpack(color)

    cornerRadius = cornerRadius or {}
    local rtl = cornerRadius.topLeft or 0
    local rtr = cornerRadius.topRight or 0
    local rbl = cornerRadius.bottomLeft or 0
    local rbr = cornerRadius.bottomRight or 0
    local radii = {rtl, rbl, rbr, rtr}

    local vertices = {}
    local function vert(vx, vy)
        table.insert(vertices, {vx, vy,    (vx - x) / w, (vy - y) / h,    r, g, b, a})
        return #vertices
    end

    local indices = {}
    local function tri(i, j, k)
        table.insert(indices, i)
        table.insert(indices, j)
        table.insert(indices, k)
    end

    -- center quad
    local ctl = vert(x     + rtl, y     + rtl)
    local cbl = vert(x     + rbl, y + h - rbl)
    local cbr = vert(x + w - rbr, y + h - rbr)
    local ctr = vert(x + w - rtr, y     + rtr)

    tri(ctl, cbl, cbr)
    tri(ctl, cbr, ctr)

    -- corners
    local firstCornerVert = {}
    local lastCornerVert = {}
    for corner = 1, 4 do
        local steps = radii[corner]
        local angle = math.pi + (corner - 1) * math.pi * 1.5
        firstCornerVert[corner] = steps > 0 and #vertices + 1 or corner
        for i = 0, steps do
            local base = vertices[corner]
            local v = vert(
                base[1] + math.cos(angle) * radii[corner],
                base[2] + math.sin(angle) * radii[corner]
            )
            angle = angle + math.pi * 0.5 / steps
            if i > 0 then
                tri(corner, v, v - 1)
            end
        end
        lastCornerVert[corner] = steps > 0 and #vertices or corner
    end

    -- edge quads
    for corner = 1, 4 do
        local nextCorner = corner + 1
        if nextCorner > 4 then
            nextCorner = 1
        end
        tri(firstCornerVert[corner], lastCornerVert[nextCorner], nextCorner)
        tri(firstCornerVert[corner], nextCorner, corner)
    end

    jui.backend.draw({
        {type = "geometry", texture = texture, vertices = vertices, indices = indices}
    })

    if border then
        local points = {}
        for corner = 1, 4 do
            local steps = radii[corner]
            -- the round corners go in the wrong direction, so we have to reverse it
            for i = lastCornerVert[corner], firstCornerVert[corner], -1 do
                table.insert(points, vertices[i][1])
                table.insert(points, vertices[i][2])
            end
        end
        table.insert(points, points[1])
        table.insert(points, points[2])
        draw.line(border.color, border.width, points)
    end
end


function draw.debugBox(x, y, w, h)
    draw.simpleBox(getNextColor(), x, y, w, h)
end

function draw.alignText(text, color, alignx, aligny, x, y, w, h)
    local tw, th = jui.backend.getTextDimensions(nil, text)
    local tx, ty = x, y
    if alignx == jui.alignx.center then
        tx = x + w/2 - tw/2
    end
    if aligny == jui.aligny.center then
        ty = y + h/2 - th/2
    end
    tx = util.round(tx)
    ty = util.round(ty)
    jui.backend.draw({
        {type = "text", color = color, text = text, x = tx, y = ty}
    })
end

function draw.line(color, width, points)
    -- TODO: Don't use löve here, but generate geometry!
    -- https://wwwtyro.net/2019/11/18/instanced-lines.html
    love.graphics.setColor(color)
    love.graphics.setLineWidth(width)
    love.graphics.line(points)
end

return draw
