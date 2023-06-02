local util =  {}

function util.updateTable(a, b)
    for k, v in pairs(b) do
        a[k] = v
    end
end

function util.enum(...)
    local enum = {}
    local values = {...}
    for i = 1, #values do
        enum[values[i]] = values[i]
    end
    return enum
end

function util.unit(name)
    return function(v)
        return {unit = name, value = v}
    end
end

function util.isUnit(value, name)
    return type(value) == "table" and value.unit == name
end

function util.round(x)
    return math.floor(x + 0.5)
end

function util.addValueWrapper(key, value)
    return function(tbl)
        tbl[key] = value
        return tbl
    end
end

return util
