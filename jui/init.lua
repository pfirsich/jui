local requirePrefix = (...):match("(.+%.)[^%.]+$") or ""
require(requirePrefix .. "strict")

local draw = require(requirePrefix .. "draw")
local jui = require(requirePrefix .. "jui")
local util = require(requirePrefix .. "util")

jui.backend = {}

jui.inputState = {
    mouse = {},
    keyboard = {},
    controllers = {},
}
jui.windowSize = {}

jui.inputConfig = {
    mouse = {
        buttons = {left = true},
        edge = "up"
    },
    keyboard = {
        left = "left",
        right = "right",
        up = "up",
        down = "down",
        activate = "return",
    },
}

jui.alignx = util.enum("left", "center", "right")
jui.aligny = util.enum("top", "center", "bottom")
jui.direction = util.enum("left", "right", "up", "down")
jui.size = {
    fit = "fit",
    fill = util.unit("fill"),
}
jui.spacing = util.enum("around", "between", "even")
jui.layoutType = util.enum("direct", "linear", "grid")
jui.layout = {
    direct = {layoutType = "direct"},
    linear = util.addValueWrapper("layoutType", "linear"),
    grid = util.addValueWrapper("layoutType", "grid"),
}

jui.pct = util.unit("pct")
jui.vw = util.unit("vw")
jui.vh = util.unit("vh")
jui.px = function(v) return v end

jui.Box = require(requirePrefix .. "box")
jui.Button = require(requirePrefix .. "button")

local defaultConfig = {
    numVertices = 4096,
}

function jui.init(config)
    jui.config = config or {}
    for k, v in pairs(defaultConfig) do
        if jui.config[k] == nil then
            jui.config[k] = v
        end
    end
    for k, v in pairs(jui.backend.defaultConfig) do
        jui.config[k] = v
    end
    jui.backend.init()
    return jui
end

function jui.update()
    jui.backend.update()
end

function jui.newFrame()
    draw.newFrame()
    jui.backend.newFrame()
end

return jui
