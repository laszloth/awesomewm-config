local hfnc = {}

function hfnc.add_pango_fg(color, text)
    return [[<span foreground="]]..color..[[">]]..text..[[</span>]]
end

function hfnc.string_contains(string, pattern)
    for _ in string.gmatch(string, pattern) do
        return true
    end
    return false
end

function hfnc.str_to_table(string, delimiter, exclude_patterns)
    if not string then return nil end
    exclude_patterns = exclude_patterns or {}
    delimiter = delimiter or ' '

    local rt = {}

    for dev in string.gmatch(string, "[^"..delimiter.."]+") do
        for _, exc_val in pairs(exclude_patterns) do
            if hfnc.string_contains(dev, exc_val) then
                goto continue
            end
        end

        table.insert(rt, dev)

        ::continue::
    end

    return rt
end

function hfnc.table_to_str(t, depth)
    depth = depth or 0

    if type(t) ~= "table" then
        return tostring(t)
    end

    local dpref = " "
    for _ = 1, depth do
        dpref = dpref.." "
    end

    local str = "{ "
    for key, value in pairs(t) do
        str = str.."\n"..dpref.."["..tostring(key).."] = "..
                hfnc.table_to_str(value, depth+1)..", "
    end
    return str.."}"
end

function hfnc.print_table(t, name)
    name = name or "table"
    debug_print_perm(name..' '..hfnc.table_to_str(t))
end

function hfnc.print_table_perm(t, name)
    name = name or "table"
    debug_print_perm(name..' '..hfnc.table_to_str(t))
end

function hfnc.round(number, decimal_places)
    decimal_places = decimal_places or 0
    local multiplier =  10 ^ (decimal_places)
    return math.floor(number * multiplier + 0.5) / multiplier
end

function hfnc.add_decimal_padding(number, pad_count)
    pad_count = pad_count or 0
    return string.format("%." .. pad_count .. "f", tostring(number))
end

return hfnc

-- vim: autoindent tabstop=8 shiftwidth=4 expandtab softtabstop=4 filetype=lua
