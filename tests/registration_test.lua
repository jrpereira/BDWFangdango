package.path = 'ModCoreTemplates/Scripts/?.lua;' .. package.path
local definitions=dofile('Fangdango/tests/load_templates.lua')()
local template,bar=definitions[1],definitions[2]
local path='9_ModCore_Fangdango/Scripts/mc_wheels.lua'
local barPath='9_ModCore_Fangdango/Scripts/mc_bars.lua'
assert(template.category=='player.quickslots' and template.version=='1.0.1')
assert(bar.category=='player.quickslots' and bar.name=='Bars Fangdango')
assert(template.managed==nil and bar.managed==nil)
assert(template.requiredTargets==nil and bar.requiredTargets==nil)
assert(template.objects.abilities==nil and template.objects.consumables==nil
    and template.objects.wheels.abilities.properties==nil
    and template.objects.wheels.properties[1]=='box'
    and template.objects.wheels.properties[4]=='size'
    and template.objects.change_prompt.properties[1]=='opacity')
assert(type(template.attach)=='function' and type(bar.attach)=='function')
local category=dofile('ModCoreTemplates/Scripts/categories/player_quickslots.lua')
assert(table.concat(category.sharedObjects,',')=='actions,bait1,bait2')
assert(category.objects.ability_host==nil and category.objects.consumable_host==nil)
assert(category.objects.bait1.reparent=='abilities'
    and category.objects.bait1.destination=='actions'
    and category.objects.bait2.reparent=='consumables'
    and category.objects.bait2.destination=='actions')
assert(category.objects.switcher.properties==nil)
assert(category.objects.abilities.properties==nil)
assert(category.objects.actions.source=='create'
    and category.objects.actions.class=='/Script/UMG.CanvasPanel'
    and category.objects.actions.outer=='switcher'
    and category.objects.actions.parent=='hud_root'
    and category.objects.actions.layout=='fill')
assert(category.objects.change_prompt.member=='@owner.WBP_HUD_Quickslots_ChangePrompt')
-- Bars moves keys inside their native panels: no canvas, panel or frame targets.
assert(bar.objects.actions==nil and bar.objects.wheels.abilities~=nil
    and bar.objects.wheels.consumables~=nil and bar.objects.hud_root==nil
    and bar.objects.switcher==nil)
assert(bar.objects.wheels.properties[1]=='box'
    and bar.objects.abilities==nil and bar.objects.boxes==nil
    and bar.objects.panels==nil
    and bar.objects.decorations==nil)
assert(bar.objects.buttons.abilitySlots[1]=='ability_button_left'
    and bar.objects.buttons.consumableSlots[4]=='consumable_button_bottom'
    and bar.objects.buttons.properties[1]=='slot')
for _,property in ipairs(bar.objects.buttons.properties) do
    assert(property~='parent' and property~='order','Bars must not reparent keys')
end
assert(template.render==nil)
local barFields=bar.menu[1].fields
assert(bar.menu~=template.menu and bar.menu[1].id=='Bars' and barFields[1].id=='.A')
assert(barFields[1].values[7]=='Horizontal' and barFields[1].values[5]=='Vertical'
    and barFields[1].default==7)
assert(#barFields==5 and barFields[2].id=='.KH' and barFields[3].id=='.KV'
    and barFields[4].id=='.S' and barFields[5].id=='.M')
assert(barFields[2].values[0]=='Above' and barFields[2].values[1]=='Below'
    and barFields[2].default==0)
assert(barFields[3].values[0]=='Left' and barFields[3].values[1]=='Right'
    and barFields[3].default==0)
assert(barFields[4].values.min==-50 and barFields[4].values.max==100 and barFields[4].default==100)
-- Margin matches Wheels' Margin to Screen Edge.
assert(barFields[5].values.min==-100 and barFields[5].values.max==100
    and barFields[5].values.step==10 and barFields[5].values.suffix=='%')
assert(bar.objects.labels.abilityLabels[1]=='ability_left'
    and bar.objects.labels.consumableLabels[4]=='consumable_bottom')
local model=require('mc.menu_model').build(
    {category},
    {template,bar},{path,barPath})
local menu=require('mc.menu').generate(model.registry)
assert(template.menuTarget=='module' and bar.menuTarget=='module')
-- Fangdango's module entry links to Controls > Visuals; settings live in the slot page.
assert(menu.providers['ModCoreTemplates.module.Fangdango']==nil)
local entry
for _,candidate in ipairs(menu.pages) do
    if candidate.id=='ModCoreTemplates.module.Fangdango' then entry=candidate end
end
assert(entry and entry.link=='controls:visuals' and entry.rows==nil)
assert(entry.author=='Jorge Pereira (kell)')
assert(entry.version=='1.0.1')
local page=assert(menu.providers['ModCoreTemplates.slot.player.quickslots'])
assert(page.slot=='controls:visuals')
-- Saved Fangdango values are copied once from the module config, never removed.
assert(page.migrate[1]=='9_ModCore_Fangdango/config.ini')
local selector=menu.selectors['player.quickslots']
local value,barValue
for option,id in pairs(selector.byValue) do
    if id==template.id then value=option end
    if id==bar.id then barValue=option end
end
assert(value and barValue and value~=barValue)
local definition=menu.definitions['player.quickslots'][value]
assert(template.id==definition.id and template.name=='Wheels Fangdango')
assert(not definition.access and not definition.direct)
local barDefinition=menu.definitions['player.quickslots'][barValue]
local rows,values={},{}
for _,row in ipairs(page.rows) do
    rows[row.Id]=row
    if row.Default~=nil then values[row.Id]=tonumber(row.Default) or row.Default end
end
values[selector.id]=value
assert(rows[selector.id].mcHeading==true and rows[selector.id].mcLevel==nil)
local count=0
for _ in pairs(definition.settings) do count=count+1 end
assert(count==4)
local align=rows[definition.settings.WheelsA]
local placement=rows[definition.settings.WheelsR]
assert(align and align.PresetLabels=='Right/Center|Bottom/Right|Bottom/Center')
-- Each template's fields show only while that template is selected.
assert(page.manifest:find('VisibleValues='..value..'\nVisibleWhen='..selector.id,1,true))
assert(page.manifest:find('VisibleValues='..barValue..'\nVisibleWhen='..selector.id,1,true))
assert(placement and placement.PresetLabels=='Overlap|Side by Side|Stacked|Perspective')
local settings=menu.decodeState(values)['player.quickslots'].selections[template.id]
assert(settings.WheelsA==6 and settings.WheelsM==0
    and settings.WheelsR==1 and settings.WheelsS==100)
-- Unrecognized or legacy saved keys are ignored, never a failure.
for _,legacy in ipairs({'MCT_WheelsSize','MCT_WheelsX','MCT_WheelsY','MCT_BarsR'}) do
    values[legacy]=50
end
local tolerant=menu.decodeState(values)['player.quickslots'].selections[template.id]
assert(tolerant.WheelsA==6 and tolerant.WheelsS==100 and tolerant.WheelsSize==nil)
local orientation=rows[barDefinition.settings.BarsA]
assert(orientation and tonumber(orientation.Default)==7)
local above=rows[barDefinition.settings.BarsKH]
local side=rows[barDefinition.settings.BarsKV]
assert(above and above.PresetLabels=='Above|Below')
assert(side and side.PresetLabels=='Left|Right')
-- Each Key Indicators row shows only for its own orientation, on the slot page too.
assert(above.VisibleWhen==orientation.Id and tostring(above.VisibleValues)=='7')
assert(side.VisibleWhen==orientation.Id and tostring(side.VisibleValues)=='5')
assert(page.manifest:find('VisibleValues=7\nVisibleWhen='..orientation.Id,1,true))
assert(page.manifest:find('VisibleValues=5\nVisibleWhen='..orientation.Id,1,true))
values[selector.id]=barValue
local barSettings=menu.decodeState(values)['player.quickslots'].selections[bar.id]
assert(barSettings.BarsA==7 and barSettings.BarsKH==0 and barSettings.BarsKV==0)
print('AF Wheels registration and settings contract passed')

assert(#definitions==2 and definitions[1].name=='Wheels Fangdango'
    and definitions[2].name=='Bars Fangdango')
print('Fangdango registered template list passed')

local originalStartup=package.loaded['mc.lua_startup']
local originalRegistration=package.loaded['mc.registration']
local originalModRef=ModRef
local files={}
package.loaded['mc.lua_startup']={start=function()
    return {registerTemplate=function(_,path)
        files[#files+1]={path=path};return true
    end}
end}
package.loaded['mc.registration']={
    install=function() return true end,
    publisher=function()
        return {begin=function() end,collect=function() return {} end}
    end,
}
ModRef={}
dofile('./ModCoreTemplates/Scripts/main.lua')
-- Core loads first and caches the public mc API; the provider then registers.
dofile('Fangdango/Scripts/main.lua')
package.loaded['mc.lua_startup']=originalStartup
package.loaded['mc.registration']=originalRegistration
ModRef=originalModRef
assert(#files==2)
assert(files[1].path:match('Fangdango/Scripts/mc_wheels%.lua$'))
assert(files[2].path:match('Fangdango/Scripts/mc_bars%.lua$'))
print('Fangdango templates are explicitly registered with ModCoreTemplates')
