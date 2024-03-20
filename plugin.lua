local workspace = require "workspace"

local function extractPathComponents(path)
    local components = {}
    for component in path:gmatch("[^/]+") do
        table.insert(components, component)
    end

    return components
end

local import = function(path, fileUri)
    local callerPath = fileUri
 
    local pathStack = {}
    
    if (path:sub(1, 1) == ".") then
        local components = extractPathComponents(callerPath)
        
        for i = 1, #components - 1 do
            pathStack[i] = components[i]
        end
    end

    local components = extractPathComponents(path)

    for _, component in ipairs(components) do
        if (component == ".") then
            -- Skip
        elseif (component == "..") then
            table.remove(pathStack, #pathStack)
        else
            table.insert(pathStack, component)
        end
    end

    local out = table.concat(pathStack, ".")
    
    return "require(\""..out.."\")"
end

function OnSetText(uri, text)
    local diffs = {}

    local transformedUri = ""
    transformedUri = uri:sub(#workspace.rootUri+2)

    for startPos, path, finish in text:gmatch '()import%(([^()]+)%)()' do
        diffs[#diffs+1] = {
            start  = startPos,
            finish = finish,
            text   = import(path:gsub('\"',""), transformedUri),
        }
    end

    return diffs
end