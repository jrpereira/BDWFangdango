package.path = 'ModCoreTemplates/Scripts/?.lua;' .. package.path
local definitions=dofile('Fangdango/tests/load_templates.lua')()
local template=definitions[1]
-- Single and Double Underbar and Sidebar, by menu id.
local bars,barList={},{}
local barIds={'SingleUnderbar','DoubleUnderbar','SingleSidebar','DoubleSidebar'}
local barNames={'Single Underbar','Double Underbar','Single Sidebar','Double Sidebar'}
for index,id in ipairs(barIds) do
    local definition=definitions[index+1]
    assert(definition.category=='player.quickslots' and definition.name==barNames[index]
        and definition.menu[1].id==id and definition.menu[1].label==barNames[index])
    assert(definition.managed==nil and definition.requiredTargets==nil
        and type(definition.attach)=='function')
    for _,other in pairs(bars) do
        assert(other.objects~=definition.objects and other.menu~=definition.menu)
    end
    bars[id],barList[index]=definition,definition
end
local bar=bars.SingleUnderbar
local path='9_ModCore_Fangdango/Scripts/mc_wheels.lua'
local barPath='9_ModCore_Fangdango/Scripts/mc_bars.lua'
assert(template.category=='player.quickslots' and template.version=='1.0.1')
assert(template.managed==nil and template.requiredTargets==nil)
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
-- No bar has Relative Placement. Single bars choose their Key Indicators,
-- listing their own bar's sides first; Double bars share them between rows.
-- All bars but the Single Sidebar choose their Position first.
local wheelFields=template.menu[1].fields
local sizes={[80]='Smaller',[90]='Small',[100]='Standard',[110]='Large',[120]='Larger'}
local sizeFields,marginFields={wheelFields[3]},{}
local wheelMargin=wheelFields[4]
assert(wheelMargin.id=='.M' and wheelMargin.default==50 and wheelMargin.values.min==0
    and wheelMargin.values.max==100 and wheelMargin.values.step==10)
for id,definition in pairs(bars) do
    local fields=definition.menu[1].fields
    local single=id:match('^Single')~=nil
    local positioned=id~='SingleSidebar'
    assert(#fields==(single and positioned and 4 or 3),id)
    for _,field in ipairs(fields) do
        assert(field.conditions==nil and field.id~='.R',id)
    end
    if single then
        local keys=fields[positioned and 2 or 1]
        assert(keys.id=='.K' and keys.default==0)
        local labels=id=='SingleUnderbar' and {'Above','Below','Left','Right'}
            or {'Left','Right','Above','Below'}
        for value=0,3 do assert(keys.values[value]==labels[value+1],id) end
    end
    if positioned then
        -- Positions are numbered as MCT's alignments.
        local position=fields[1]
        assert(position.id=='.A' and position.label=='Position')
        if id:match('Sidebar$') then
            assert(position.values[5]=='Middle/Right' and position.values[6]=='Bottom/Right'
                and position.values[7]==nil and position.default==6)
        else
            assert(position.values[7]=='Bottom/Center' and position.values[6]=='Bottom/Right'
                and position.values[5]==nil and position.default==7)
        end
    end
    sizeFields[#sizeFields+1],marginFields[#marginFields+1]=fields[#fields-1],fields[#fields]
end
-- Size matches Wheels; bars' Margin runs either side of the native HUD.
for _,field in ipairs(sizeFields) do
    assert(field.id=='.S' and field.default==100)
    local count=0
    for value,label in pairs(field.values) do
        assert(sizes[value]==label);count=count+1
    end
    assert(count==5)
end
for _,field in ipairs(marginFields) do
    assert(field.id=='.M' and field.default==0 and field.values.min==-100
        and field.values.max==100 and field.values.step==5 and field.values.suffix=='%')
end
assert(bar.objects.labels.abilityLabels[1]=='ability_left'
    and bar.objects.labels.consumableLabels[4]=='consumable_bottom')
local model=require('mc.menu_model').build(
    {category},
    {template,barList[1],barList[2],barList[3],barList[4]},{path,barPath,barPath,barPath,barPath})
local menu=require('mc.menu').generate(model.registry)
assert(template.menuTarget=='module')
for _,definition in ipairs(barList) do assert(definition.menuTarget=='module') end
-- Fangdango's module page is a real page merged into Controls > Visuals: a
-- notice linking there, then the same rows as the slot page.
local entry=assert(menu.providers['ModCoreTemplates.module.Fangdango'])
assert(entry.merged=='controls:visuals' and entry.module==nil and entry.link==nil)
assert(entry.author=='Jorge Pereira (kell)')
assert(entry.version=='1.0.1')
assert(entry.rows and #entry.rows>1)
local notice=entry.rows[1]
assert(notice.Id=='MCT_MergedNotice' and notice.mcLinkPage=='controls:visuals'
    and notice.Label=='These settings have been merged into Controls and can also be edited there')
assert(notice.mcNavigation==1 and notice.mcType=='tab' and notice.mcLevel==5
    and notice.PresetLabels=='Controls|Controls')
local page=assert(menu.providers['ModCoreTemplates.slot.player.quickslots'])
assert(page.slot=='controls:visuals')
-- After the notice, its only navigation row, the module page edits the slot
-- page's rows in the same order.
assert(#entry.rows==#page.rows+1)
for index,row in ipairs(page.rows) do
    local moduleRow=entry.rows[index+1]
    assert(moduleRow.Id==row.Id and moduleRow.mcNavigation==nil,
        'module row differs from slot page: '..tostring(moduleRow.Id))
end
-- Saved Fangdango values are copied once from the module config, never removed.
assert(page.migrate[1]=='9_ModCore_Fangdango/config.ini')
local selector=menu.selectors['player.quickslots']
local value
local barValues,seenValues={},{}
for option,id in pairs(selector.byValue) do
    assert(not seenValues[option]);seenValues[option]=true
    if id==template.id then value=option end
    for barId,definition in pairs(bars) do
        if id==definition.id then barValues[barId]=option end
    end
end
assert(value)
for _,barId in ipairs(barIds) do assert(barValues[barId],barId) end
local definition=menu.definitions['player.quickslots'][value]
assert(template.id==definition.id and template.name=='Wheels')
assert(not definition.access and not definition.direct)
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
assert(placement and placement.PresetLabels=='Overlap|Side by Side|Stacked|Perspective')
local settings=menu.decodeState(values)['player.quickslots'].selections[template.id]
assert(settings.WheelsA==6 and settings.WheelsM==50
    and settings.WheelsR==1 and settings.WheelsS==100)
-- Each bar's rows show only while that bar is selected; its settings are named
-- after its menu.
for barId,definition in pairs(bars) do
    local barValue=barValues[barId]
    assert(page.manifest:find('VisibleValues='..barValue..'\nVisibleWhen='..selector.id,1,true))
    local barDefinition=menu.definitions['player.quickslots'][barValue]
    local single=barId:match('^Single')~=nil
    assert(barDefinition.settings[barId..'R']==nil
        and (barDefinition.settings[barId..'A']~=nil)==(barId~='SingleSidebar'),barId)
    local keys=rows[barDefinition.settings[barId..'K']]
    assert((keys~=nil)==single,barId)
    if single then
        assert(keys.PresetLabels==(barId=='SingleUnderbar' and 'Above|Below|Left|Right'
            or 'Left|Right|Above|Below'))
    end
    values[selector.id]=barValue
    local barSettings=menu.decodeState(values)['player.quickslots'].selections[definition.id]
    local position
    if barId=='DoubleSidebar' then position=6 elseif barId~='SingleSidebar' then position=7 end
    assert(barSettings[barId..'S']==100 and barSettings[barId..'M']==0
        and barSettings[barId..'K']==(single and 0 or nil) and barSettings[barId..'A']==position)
end
print('AF Wheels registration and settings contract passed')

assert(#definitions==5 and definitions[1].name=='Wheels')
for index,name in ipairs(barNames) do assert(definitions[index+1].name==name) end
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
