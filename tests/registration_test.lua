package.path = 'ModCoreTemplates/Scripts/?.lua;' .. package.path
local definitions=dofile('Fangdango/tests/load_templates.lua')()
local minima,template,bar=definitions[1],definitions[2],definitions[3]
local minimaPath='_ModCore_X_Fangdango/Scripts/mc_minima.lua'
local path='_ModCore_X_Fangdango/Scripts/mc_wheels.lua'
local barPath='_ModCore_X_Fangdango/Scripts/mc_bars.lua'
assert(minima.name=='Minima' and minima.category=='player.quickslots')
assert(minima.module=='Fangdango' and minima.managed==nil and minima.version=='0.2.1')
assert(minima.author=='Jorge Pereira (kell)')
assert(type(minima.attach)=='function' and minima.objects[1]=='switcher')
assert(template.category=='player.quickslots' and template.version=='0.2.1')
assert(bar.category=='player.quickslots' and bar.name=='Bar')
assert(template.managed==nil and bar.managed==nil)
assert(template.requiredTargets==nil and bar.requiredTargets==nil)
assert(template.objects[1]=='switcher' and template.objects.abilities.properties[1]=='opacity'
    and template.objects.consumables.properties[1]=='opacity')
assert(type(template.attach)=='function' and type(bar.attach)=='function')
local category=dofile('ModCoreTemplates/Scripts/categories/player_quickslots.lua')
assert(category.objects.switcher.properties[1]=='activeIndex')
assert(category.objects.abilities.properties[1]=='parent')
assert(category.objects.actions.source=='create'
    and category.objects.actions.class=='/Script/UMG.CanvasPanel'
    and category.objects.actions.outer=='switcher'
    and category.objects.actions.parent=='hud_root')
assert(bar.objects.actions~=nil and bar.objects.hud_root~=nil)
assert(bar.objects.buttons.abilitySlots[1]=='ability_button_left'
    and bar.objects.buttons.consumableSlots[4]=='consumable_button_bottom'
    and bar.objects.buttons.properties[1]=='parent')
assert(template.render==nil)
local barFields=bar.menu[1].fields
assert(bar.menu~=template.menu and barFields[1].id=='Tightness')
assert(barFields[2].values.min==-50 and barFields[2].values.max==150 and barFields[2].default==100)
assert(barFields[3].values.min==-100 and barFields[3].values.max==100)
assert(barFields[1].values.min==-25 and barFields[1].values.max==50 and barFields[1].default==-25)
assert(bar.settings.Spacing==10)
local model=require('mc.menu_model').build(
    {{name='player.quickslots',single=true,objects={root={source='lookup',object='switcher'}}}},
    {minima,template,bar},{minimaPath,path,barPath})
local menu=require('mc.menu').generate(model.registry)
assert(template.menuTarget=='module' and bar.menuTarget=='module')
local page=assert(menu.providers['ModCoreTemplates.module.Fangdango'])
assert(page.author=='Jorge Pereira (kell)')
assert(page.version=='0.2.1')
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
assert(style.Label=='Style' and style.PresetLabels=='Swap|Separate'
    and style.PresetValues=='0|1')
assert(style.Description and style.Description:find('Use Edit controls below',1,true))
local controlLink=rows[definition.navigation.ControlLayoutLink]
assert(controlLink and controlLink.Label=='Control Layout'
    and controlLink.PresetLabels=='Edit controls|Open'
    and controlLink.mcNavigation==1 and controlLink.mcLinkProvider=='ModCoreControls')
local count=0
for _ in pairs(definition.settings) do count=count+1 end
assert(count==10)
for _,settingId in pairs(definition.settings) do
    assert(rows[settingId].Description and #rows[settingId].Description>0)
end
assert(not definition.settings.WheelsOpacity and not definition.settings.Wheel1Opacity
    and not definition.settings.Wheel2Opacity)
for _,group in ipairs({'Wheels','Wheel1','Wheel2'}) do
    for _,field in ipairs({'X','Y','Size'}) do
        local row=rows[definition.settings[group..field]]
        assert(row.VisibleWhen==selector.id and row.VisibleValues==value)
        if field=='Size' then
            assert(row.Type=='picker' and row.PresetLabels=='Small|Medium|Large'
                and row.PresetValues=='85|100|110'
                and row.Default==(group=='Wheel2' and 85 or 100))
        end
    end
end
assert(page.manifest:find('VisibleWhen='..definition.settings.Style,1,true))
local settings=menu.decodeState(values)['player.quickslots'].selections[template.id]
assert(settings.Style==0 and settings.WheelsSize==100 and settings.Wheel2Y==-360)
assert(template.settings.WheelsOpacity==100 and template.settings.Wheel1Opacity==100
    and template.settings.Wheel2Opacity==85)
assert(settings.access==nil and settings.AccessMode==nil)
local tightness=rows[barDefinition.settings.Tightness]
assert(tightness and tightness.Default==-25 and not barDefinition.settings.Orientation)
print('AF Wheels registration and settings contract passed')

assert(#definitions==3 and definitions[1].name=='Minima'
    and definitions[2].name=='Wheels' and definitions[3].name=='Bar')
print('Fangdango registered template list passed')

local originalStartup=package.loaded['mc.lua_startup']
local files={}
package.loaded['mc.lua_startup']={start=function()
    return {registerTemplate=function(_,path)
        files[#files+1]={path=path};return true
    end}
end}
dofile('ModCoreTemplates/Scripts/main.lua')
-- Core loads first and caches the public mc API; the provider then registers.
dofile('Fangdango/Scripts/main.lua')
package.loaded['mc.lua_startup']=originalStartup
assert(#files==3)
assert(files[1].path:match('Fangdango/Scripts/mc_minima%.lua$'))
assert(files[2].path:match('Fangdango/Scripts/mc_wheels%.lua$'))
assert(files[3].path:match('Fangdango/Scripts/mc_bars%.lua$'))
print('Fangdango templates are explicitly registered with ModCoreTemplates')
