local Defaults=require('mc.template_defaults')
local Metadata=require('mc.module_metadata')
local Bootstrap=require('mc.bootstrap')

return function()
    local entries={}
    require('mc')._setTemplateRegistrar(function(path)
        entries[#entries+1]={path=path};return true
    end)
    dofile('Fangdango/Scripts/main.lua')
    local definitions={}
    for _,entry in ipairs(entries) do
        -- Load as MCT does, so template helpers resolve from Fangdango's Scripts folder.
        -- A file returns one template or a list of them.
        local loaded=Bootstrap.executeTemplate(entry.path)
        for _,template in ipairs(loaded.category and {loaded} or loaded) do
            definitions[#definitions+1]=Metadata.apply(Defaults.apply(template),entry.path)
        end
    end
    return definitions,entries
end
