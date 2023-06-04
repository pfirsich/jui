local style = {}

function style.compute(object)
    local s = object.style
    local res = {}
    for _, rule in ipairs(object.style) do
        local match = true
        for k, v in pairs(rule.selector) do
            if object[k] ~= v then
                match = false
                break
            end
        end

        if match then
            for k, v in pairs(rule) do
                if k ~= "selector" then
                    res[k] = v
                end
            end
        end
    end
    return res
end

return style
