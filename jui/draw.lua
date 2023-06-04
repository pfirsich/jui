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

function draw.box(x, y, w, h, color)
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

function draw.debugBox(x, y, w, h)
    draw.box(x, y, w, h, getNextColor())
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

return draw
