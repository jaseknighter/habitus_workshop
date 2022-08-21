fn = {}

function fn.deep_copy(orig, copies)
    copies = copies or {}
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        if copies[orig] then
            copy = copies[orig]
        else
            copy = {}
            copies[orig] = copy
            for orig_key, orig_value in next, orig, nil do
                copy[fn.deep_copy(orig_key, copies)] = fn.deep_copy(orig_value, copies)
            end
            setmetatable(copy, fn.deep_copy(getmetatable(orig), copies))
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end
  
function fn.find_closer(comparator1,comparator2,comparatee)
    comp1 = math.abs(comparator1-comparatee)
    comp2 = math.abs(comparator2-comparatee)
    
    if comp1<=comp2 then 
        return comparator1 
    else 
        return comparator2 
    end
end

function fn.quantize(val,quant_table)
    -- make a copy of the table to be quantized
    local qts = fn.deep_copy(quant_table)
    -- print(#quant_table)
    -- sort the copy of the table
    table.sort(qts)

    -- find the closest value in the table 
    local found_closest = false
    for i=1,#qts,1 do
        -- print(i)
        if val <= qts[i] then
            if qts[i-1] then
                local closest_val = fn.find_closer(qts[i-1],qts[i],val)
                return closest_val
            end
        end
    end
end

function fn.dirty_screen(bool)
    if bool == nil then return screen_dirty end
    screen_dirty = bool
    return screen_dirty
end

function rerun()
  norns.script.load(norns.state.script)
end

function r()
    rerun()
end

return fn
