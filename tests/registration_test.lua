package.path = 'ModCoreTemplates/Scripts/?.lua;' .. package.path
local definitions=dofile('Fangdango/Scripts/templates/mc.lua')
local minima,template,bar=definitions[1],definitions[2],definitions[3]
local minimaPath='_ModCore_Fangtango/Scripts/templates/mc_minima.lua'
local path='_ModCore_Fangtango/Scripts/templates/mc_wheels.lua'
local barPath='_ModCore_Fangtango/Scripts/templates/mc_bars.lua'
assert(minima.name=='Minima' and minima.category=='player.quickslots')
assert(minima.module=='Fangdango' and minima.managed and minima.version=='0.2.1')
assert(type(minima.attach)=='function' and minima.targets[1]=='switcher')
assert(template.category=='player.quickslots' and template.version=='0.2.1')
assert(bar.category=='player.quickslots' and bar.name=='Bar')
assert(template.managed and bar.managed)
assert(template.requiredTargets==nil and bar.requiredTargets==nil)
assert(template.targets[1]=='switcher' and template.targets.abilities.properties[1]=='opacity'
    and template.targets.consumables.properties[1]=='opacity')
assert(type(template.attach)=='function' and type(bar.attach)=='function')
local category=dofile('ModCoreTemplates/Scripts/categories/player_quickslots.lua')
assert(category.targets.switcher.properties[1]=='activeIndex')
assert(category.targets.abilities.properties[1]=='parent')
assert(bar.targets.buttons.abilitySlots[1]=='ability_button_left'
    and bar.targets.buttons.consumableSlots[4]=='consumable_button_bottom'
    and bar.targets.buttons.properties[1]=='parent')
assert(template.render==nil)
assert(bar.menu~=template.menu and bar.menu.fields[1].id=='Tightness')
assert(bar.menu.fields[2].min==-50 and bar.menu.fields[2].max==150 and bar.menu.fields[2].default==100)
assert(bar.menu.fields[3].min==-100 and bar.menu.fields[3].max==100)
assert(bar.menu.fields[1].min==-25 and bar.menu.fields[1].max==50
    and bar.menu.fields[1].default==-25)
assert(bar.settings.Spacing==10)
local model=require('mc.menu_model').build(
    {{name='player.quickslots',single=true,targets={root={object='switcher'}}}},
    {minima,template,bar},{minimaPath,path,barPath})
local menu=require('mc.menu').generate(model.registry)
local page=assert(menu.providers['ModCoreTemplates.module.Fangdango'])
local selector=menu.selectors['player.quickslots']
local minimaValue,value,barValue
for option,id in pairs(selector.byValue) do
    if id==minima.id then minimaValue=option end
    if id==template.id then value=option end
    if id==bar.id then barValue=option end
end
assert(minimaValue and value and barValue and minimaValue~=value and value~=barValue)
assert(not next(menu.definitions['player.quickslots'][minimaValue].settings))
local definition=menu.definitions['player.quickslots'][value]
assert(template.id==definition.id and template.name=='Wheels')
assert(not definition.access and not definition.direct)
local barDefinition=menu.definitions['player.quickslots'][barValue]
local rows,values={},{}
for _,row in ipairs(page.rows) do
    rows[row.Id]=row
    if row.Default~=nil then values[row.Id]=tonumber(row.Default) or row.Default end
end
values[selector.id]=value
assert(rows[selector.id].mcLevel==1)
local style=rows[definition.settings.Style]
assert(style.PresetLabels=='Swap|Distant' and style.PresetValues=='0|1')
local count=0
for _ in pairs(definition.settings) do count=count+1 end
assert(count==13)
for _,group in ipairs({'Wheels','Wheel1','Wheel2'}) do
    for _,field in ipairs({'X','Y','Size','Opacity'}) do
        local row=rows[definition.settings[group..field]]
        assert(row.VisibleWhen==definition.settings.Style)
        assert(row.VisibleValues==(group=='Wheels' and '0' or '1'))
    end
end
local settings=menu.decodeState(values)['player.quickslots'].selections[template.id]
assert(settings.Style==0 and settings.WheelsSize==100 and settings.Wheel2X==360)
assert(settings.access==nil and settings.AccessMode==nil)
local tightness=rows[barDefinition.settings.Tightness]
assert(tightness and tightness.Default==-25 and not barDefinition.settings.Orientation)
print('AF Wheels registration and settings contract passed')

assert(#definitions==3 and definitions[1].name=='Minima'
    and definitions[2].name=='Wheels' and definitions[3].name=='Bar')
print('Fangdango mc.lua template list passed')

local originalStartup=package.loaded['mc.lua_startup']
local originalDirectories=IterateGameDirectories
IterateGameDirectories=function()
    return {mods={__name='Mods',__absolute_path='.',Fangdango={
        __name='Fangdango',__absolute_path='Fangdango',__files={enabled={__name='enabled.txt'}},Scripts={
            __name='Scripts',templates={__name='templates',__files={
                main={__name='mc.lua',__absolute_path='Fangdango/Scripts/templates/mc.lua'},
                minima={__name='mc_minima.lua',__absolute_path='Fangdango/Scripts/templates/mc_minima.lua'},
                wheels={__name='mc_wheels.lua',__absolute_path='Fangdango/Scripts/templates/mc_wheels.lua'},
                bar={__name='mc_bars.lua',__absolute_path='Fangdango/Scripts/templates/mc_bars.lua'},
            }}}}}}
end
package.loaded['mc.lua_startup']={start=function(options) return options end}
local configured=dofile('ModCoreTemplates/Scripts/main.lua')
package.loaded['mc.lua_startup']=originalStartup
IterateGameDirectories=originalDirectories
assert(#configured.templateFiles==1)
assert(configured.templateFiles[1]:match('Fangdango/Scripts/templates/mc%.lua$'))
print('Fangdango mc.lua is discovered by the active ModCoreTemplates entry point')
