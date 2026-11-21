package.path = 'ModCoreTemplates/Scripts/?.lua;ModCoreTemplates/Scripts/vendor/?.lua;' .. package.path
local definitions=dofile('Fangdango/tests/load_templates.lua')()
local template=definitions[1]
-- ModCore Templates after 1.8.0 prefixes a template's id with its module's and
-- keeps the declared one as localId.
local function localId(definition) return definition.localId or definition.id end
-- Single and Double Underbar and Sidebar, by menu id.
local bars,barList={},{}
local barIds={'SingleUnderbar','DoubleUnderbar','SingleSidebar','DoubleSidebar'}
local barNames={'Single Underbar','Double Underbar','Single Sidebar','Double Sidebar'}
for index,id in ipairs(barIds) do
    local definition=definitions[index+1]
    assert(definition.category=='player.quickslots' and localId(definition)==id and definition.label==barNames[index]
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
-- The module is the mod folder; ModCoreSettings shows its mod.json name and version.
assert(template.category=='player.quickslots' and template.module=='Fangdango')
assert(template.managed==nil and template.requiredTargets==nil)
assert(template.objects.abilities==nil and template.objects.consumables==nil
    and template.objects.wheels.abilities.properties==nil
    and template.objects.wheels.properties[1]=='box'
    and template.objects.wheels.properties[4]=='size'
    and template.objects.change_prompt.properties[1]=='opacity')
assert(type(template.attach)=='function' and type(bar.attach)=='function')
local category=dofile('ModCoreTemplates/Scripts/categories/player_quickslots.lua')
-- Bars moves keys inside their native panels: no canvas, panel or frame targets.
assert(bar.objects.actions==nil and bar.objects.wheels.abilities~=nil
    and bar.objects.wheels.consumables~=nil and bar.objects.hud_root==nil
    and bar.objects.switcher==nil)
assert(bar.objects.wheels.properties[1]=='box'
    and bar.objects.abilities==nil and bar.objects.boxes==nil
    and bar.objects.panels==nil)
assert(bar.objects.buttons.abilitySlots[1]=='ability_button_left'
    and bar.objects.buttons.consumableSlots[4]=='consumable_button_bottom'
    and bar.objects.buttons.properties[1]=='slot')
for _,property in ipairs(bar.objects.buttons.properties) do
    assert(property~='parent' and property~='order','Bars must not reparent keys')
end
-- No bar has Relative Placement. Every bar chooses its Key Indicators, listing
-- its own bar's sides first; Double bars may also merge them between rows.
-- All bars but the Single Sidebar choose their Position first.
local wheelFields=template.menu[1].fields
-- Pickers are keyed: each choice saves its key, in the order listed.
local function choices(field)
    local out={}
    for index,choice in ipairs(field.values) do
        assert(type(choice.key)=='string' and choice.value==nil,'keyed choice expected')
        out[index]=choice.key..'='..choice.label
    end
    return table.concat(out,'|')
end
local sizes='smaller=Smaller|small=Small|standard=Standard|large=Large|larger=Larger'
assert(wheelFields[1].id=='.A' and wheelFields[1].default=='bottom_right'
    and choices(wheelFields[1])=='middle_right=Middle/Right|bottom_right=Bottom/Right|bottom_center=Bottom/Center')
assert(wheelFields[2].id=='.R' and wheelFields[2].default=='side_by_side'
    and choices(wheelFields[2])=='overlap=Overlap|side_by_side=Side by Side|stacked=Stacked|perspective=Perspective')
local sizeFields,marginFields={wheelFields[3]},{}
local wheelMargin=wheelFields[4]
assert(wheelMargin.id=='.M' and wheelMargin.default==50 and wheelMargin.values.min==0
    and wheelMargin.values.max==100 and wheelMargin.values.step==10)
for id,definition in pairs(bars) do
    local fields=definition.menu[1].fields
    local single=id:match('^Single')~=nil
    local positioned=id~='SingleSidebar'
    local first=positioned and 2 or 1
    assert(#fields==(positioned and 4 or 3)+(single and 0 or 1),id)
    for _,field in ipairs(fields) do
        assert(field.conditions==nil and field.id~='.R',id)
        assert(field.id~='.J' or not single,id)
    end
    local keys=fields[first]
    local underbar=id:match('Underbar$')~=nil
    assert(keys.id=='.K' and keys.label=='Key Indicators' and keys.default==(underbar and 'above' or 'left'),id)
    assert(choices(keys)==(underbar and 'above=Above|below=Below|left=Left|right=Right'
        or 'left=Left|right=Right|above=Above|below=Below'),id)
    if not single then
        local merge=fields[first+1]
        assert(merge.id=='.J' and merge.label=='Merge key indicators when possible'
            and merge.widget=='switch' and merge.default==1
            and merge.values[0]=='Off' and merge.values[1]=='On',id)
    end
    if positioned then
        local position=fields[1]
        assert(position.id=='.A' and position.label=='Position')
        if id:match('Sidebar$') then
            assert(choices(position)=='middle_right=Middle/Right|bottom_right=Bottom/Right'
                and position.default=='bottom_right')
        else
            assert(choices(position)=='bottom_right=Bottom/Right|bottom_center=Bottom/Center'
                and position.default=='bottom_center')
        end
    end
    sizeFields[#sizeFields+1],marginFields[#marginFields+1]=fields[#fields-1],fields[#fields]
end
-- Every field of every template has a one-line description in ModCore Templates' text.
for _,definition in ipairs(definitions) do
    for _,field in ipairs(definition.menu[1].fields) do
        local text=field.description
        assert(type(text)=='string' and #text>0 and not text:find('[%c|;%[%]]')
            and text:match('^%u') and text:match('%.$'),localId(definition)..field.id)
    end
end
-- Size matches Wheels; bars' Margin runs either side of the native HUD.
for _,field in ipairs(sizeFields) do
    assert(field.id=='.S' and field.default=='standard' and choices(field)==sizes)
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
-- Rows are ModCoreSettings menu data: an enum's values, or an integer's.
local function labels(row)
    local out={}
    for index,choice in ipairs(row.values) do out[index]=choice.label end
    return table.concat(out,'|')
end
-- Whether a page shows some row only while selector holds value.
local function gated(menu,selector,value)
    for _,field in ipairs(menu.fields) do
        local rule=field.conditions and field.conditions.visible
        if rule and rule.field==selector and #rule.values==1 and rule.values[1]==value then return true end
    end
    return false
end
local entry=assert(menu.providers['ModCoreTemplates.module.9ModCoreFangdango'])
assert(entry.merged=='controls:visuals' and entry.module==nil and entry.link==nil)
-- ModCoreSettings names the page from the folder's mod.json; MCT passes only the folder.
assert(entry.author==nil and entry.version==nil and entry.moduleRoot=='9_ModCore_Fangdango')
assert(entry.rows and #entry.rows>1)
local notice=entry.rows[1]
assert(notice.id=='MCT_MergedNotice' and notice.link=='controls:visuals'
    and notice.label=='These settings have been merged into Controls and can also be edited there')
assert(notice.action and notice.widget=='tabs' and notice.style=='notice' and labels(notice)=='Controls')
local page=assert(menu.providers['ModCoreTemplates.slot.player.quickslots'])
assert(page.slot=='controls:visuals')
-- After the notice, its only navigation row, the module page edits the slot
-- page's rows in the same order.
assert(#entry.rows==#page.rows+1)
for index,row in ipairs(page.rows) do
    local moduleRow=entry.rows[index+1]
    assert(moduleRow.id==row.id and not moduleRow.action,
        'module row differs from slot page: '..tostring(moduleRow.id))
end
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
assert(template.id==definition.id and localId(template)=='Wheels' and template.label=='Wheels Plenty')
assert(not definition.access and not definition.direct)
local rows,values={},{}
for _,row in ipairs(page.rows) do
    rows[row.id]=row
    if row.default~=nil then values[row.id]=row.default end
end
values[selector.id]=value
-- The template picker, labelled Quickslots, heads the slot's rows and the module page's
-- (ModCore Templates' slot pages); each template's group, named after it, is unheaded there.
local function menuField(menu,id)
    for _,field in ipairs(menu.fields) do if field.id==id then return field end end
end
for _,shown in ipairs({page.menu,entry.menu}) do
    local picker=assert(menuField(shown,selector.id))
    assert(picker.style=='category' and picker.label=='Quickslots')
    local barRow=assert(menuField(shown,menu.definitions['player.quickslots'][barValues.SingleUnderbar].settings.SingleUnderbarK))
    for _,group in ipairs(shown.groups) do
        if group.id==barRow.group then assert(group.label=='Single Underbar' and group.style=='none') end
        if group.label=='Wheels Plenty' then assert(group.style=='none','Wheels is unheaded like the bars') end
    end
end
local count=0
for _ in pairs(definition.settings) do count=count+1 end
assert(count==4)
local align=rows[definition.settings.WheelsA]
local placement=rows[definition.settings.WheelsR]
assert(align and labels(align)=='Middle/Right|Bottom/Right|Bottom/Center')
-- Each template's fields show only while that template is selected.
assert(gated(page.menu,selector.id,value))
assert(placement and labels(placement)=='Overlap|Side by Side|Stacked|Perspective')
local settings=menu.decodeState(values)['player.quickslots'].selections[template.id]
assert(settings.WheelsA=='bottom_right' and settings.WheelsM==50
    and settings.WheelsR=='side_by_side' and settings.WheelsS=='standard')
-- ModCore Templates offers a keyed picker's keys only: an old numeric value is refused.
local Menu=require('mc.menu')
assert(Menu.keyed(align) and Menu.keyed(placement) and Menu.keyed(rows[definition.settings.WheelsS]))
assert(Menu.accepts(align,'middle_right') and not Menu.accepts(align,6) and not Menu.accepts(align,'6'))
-- Each bar's rows show only while that bar is selected; its settings are named
-- after its menu.
for barId,definition in pairs(bars) do
    local barValue=barValues[barId]
    assert(gated(page.menu,selector.id,barValue))
    local barDefinition=menu.definitions['player.quickslots'][barValue]
    local single=barId:match('^Single')~=nil
    assert(barDefinition.settings[barId..'R']==nil
        and (barDefinition.settings[barId..'A']~=nil)==(barId~='SingleSidebar'),barId)
    local keys=assert(rows[barDefinition.settings[barId..'K']],barId)
    assert(labels(keys)==(barId:match('Underbar$') and 'Above|Below|Left|Right'
        or 'Left|Right|Above|Below'),barId)
    local merge=rows[barDefinition.settings[barId..'J'] or '']
    assert((merge~=nil)==not single,barId)
    if merge then assert(merge.widget=='switch' and labels(merge)=='Off|On' and merge.default==1,barId) end
    values[selector.id]=barValue
    local barSettings=menu.decodeState(values)['player.quickslots'].selections[definition.id]
    local position,side
    if barId=='DoubleSidebar' then position='bottom_right' elseif barId~='SingleSidebar' then position='bottom_center' end
    side=barId:match('Underbar$') and 'above' or 'left'
    assert(barSettings[barId..'S']=='standard' and barSettings[barId..'M']==0
        and barSettings[barId..'K']==side and barSettings[barId..'A']==position
        and barSettings[barId..'J']==(not single and 1 or nil),barId)
end
print('Fangdango Wheels and bars registration and settings contract passed')

assert(#definitions==5 and localId(definitions[1])=='Wheels')
for index,id in ipairs(barIds) do assert(localId(definitions[index+1])==id) end
-- MCT's ability_cross, ability_darken, ability_glow and consumable_cross targets never
-- resolve in game (the decorations are not blueprint members), and a declared target that
-- does not resolve keeps a template from attaching: no template may declare them.
for _,definition in ipairs(definitions) do
    for _,group in pairs(definition.objects or {}) do
        for _,name in ipairs({'ability_cross','ability_darken','ability_glow','consumable_cross'}) do
            assert(type(group)~='table' or group[name]==nil,localId(definition)..' declares '..name)
        end
    end
end
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
