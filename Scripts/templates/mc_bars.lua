local objectSpec={
    switcher={},hud_root={},actions={},abilities={},consumables={},
    ability_box={properties={'widthOverride','heightOverride'}},
    consumable_box={properties={'widthOverride','heightOverride'}},
    ability_panel={},consumable_panel={},
    buttons={
        abilitySlots={'ability_button_left','ability_button_top','ability_button_right','ability_button_bottom'},
        consumableSlots={'consumable_button_left','consumable_button_top','consumable_button_right','consumable_button_bottom'},
        properties={'parent','order','slot','position','size'},
    },
}
local bar = {
    name='Bar',
    description='Arrange two quickslot wheels side by side, from staggered diamonds to a straight row.',
    objects=objectSpec, settings={Spacing=10},
    menu={enabled=true,fields={
        {id='Tightness',type='integer',group='Bar',label='Tightness',
            min=-25,max=50,step=5,suffix='%',default=-25,order=1},
        {id='Size',type='integer',group='Bar',label='Size',
            min=-50,max=150,step=5,suffix='%',default=100,order=2},
        {id='Margin',type='integer',group='Bar',label='Margin',
            min=-100,max=100,step=1,default=0,order=3},
    },groups={{id='Bar',label='Bar',order=1}}},
}

-- Slot identity: 0=Left, 1=Top, 2=Right, 3=Bottom.
local MC=require('mc')
local Widget=MC.load('widget')
local Objects=MC.load('objects')
local kinds={'ability','consumable'}

local function baitPanel(tree,label,color)
    local panel=assert(StaticConstructObject(
        assert(StaticFindObject('/Script/UMG.Overlay'),'Overlay class unavailable'),tree),
        'could not construct switcher panel')
    local size=assert(StaticConstructObject(
        assert(StaticFindObject('/Script/UMG.SizeBox'),'SizeBox class unavailable'),tree),
        'could not construct switcher marker size box')
    size:SetWidthOverride(280)
    size:SetHeightOverride(90)
    local background=assert(StaticConstructObject(
        assert(StaticFindObject('/Script/UMG.Border'),'Border class unavailable'),tree),
        'could not construct switcher marker background')
    background:SetBrushColor(color)
    local marker=assert(StaticConstructObject(
        assert(StaticFindObject('/Script/UMG.TextBlock'),'TextBlock class unavailable'),tree),
        'could not construct switcher marker')
    local text=assert(StaticFindObject('/Script/Engine.Default__KismetTextLibrary'),
        'text conversion unavailable')
    marker:SetText(text:Conv_StringToText(label))
    assert(Objects.valid(background:AddChild(marker)),'could not add switcher marker text')
    assert(Objects.valid(size:AddChild(background)),'could not add switcher marker background')
    assert(Objects.valid(panel:AddChild(size)),'could not add switcher marker size box')
    return panel
end

local function moveToActions(widget,actions)
    local previous=assert(Objects.parent(widget),'quickslot parent unavailable')
    assert(previous:RemoveChild(widget)~=false,'could not detach quickslot')
    local slot=assert(actions:AddChild(widget),'could not add quickslot to Actions')
    assert(Objects.valid(slot),'Actions quickslot slot unavailable')
    local slotClass=Objects.call(slot,'GetClass')
    assert(Objects.call(slotClass,'GetName')=='CanvasPanelSlot',
        'Actions does not provide a CanvasPanelSlot')
    slot:SetLayout({
        Offsets={Left=0,Top=0,Right=0,Bottom=0},
        Anchors={Minimum={X=0,Y=0},Maximum={X=0,Y=0}},
        Alignment={X=0,Y=0},
    })
    slot:SetAutoSize(true)
end

local function findChild(root,name)
    if not Objects.valid(root) then return nil end
    local full=Objects.call(root,'GetFullName')
    if type(full)=='string' and full:sub(-#name-1)=='.'..name then return root end
    local count=Objects.call(root,'GetChildrenCount')
    if type(count)~='number' then return nil end
    for index=0,count-1 do
        local found=findChild(Objects.call(root,'GetChildAt',index),name)
        if found then return found end
    end
end

local function hideDecorations(panel,kind,onCleanup)
    local names=kind=='ability' and {'cross','Darken','Glow'} or {'cross'}
    for _,name in ipairs(names) do
        local decoration=assert(findChild(panel,name),kind..' '..name..' unavailable')
        local opacity=Widget.opacity(decoration)
        onCleanup(function()
            if Objects.valid(decoration) then Widget.setOpacity(decoration,opacity) end
        end)
        Widget.setOpacity(decoration,0)
    end
end

local function plan(measured,factor,spacing,margin,tightness)
    local blend=(tightness+25)/75
    assert(blend>=0 and blend<=1,'Tightness must be between -25 and 50')
    local groups={}
    for _,kind in ipairs(kinds) do
        local boxes=measured[kind]
        local maxWidth,maxHeight=0,0
        for _,box in ipairs(boxes) do
            maxWidth=math.max(maxWidth,box.width*factor)
            maxHeight=math.max(maxHeight,box.height*factor)
        end
        local pitch=maxWidth*(1+spacing)
        local rowHeight=maxHeight*(1+spacing)*(1-blend)
        local compact=kind=='ability' and {0,0.5,1,1.5} or {0,0.5,1.5,1}
        local upper=kind=='ability' and {[2]=true,[4]=true} or {[1]=true,[4]=true}
        local points,width={},0
        for index,box in ipairs(boxes) do
            local x=(compact[index]*(1-blend)+(index-1)*blend)*pitch
            local y=upper[index] and 0 or rowHeight
            points[index]={x=x,y=y}
            width=math.max(width,x+box.width*factor)
        end
        groups[kind]={points=points,width=width,height=rowHeight+maxHeight}
    end
    local height=math.max(groups.ability.height,groups.consumable.height)
    groups.ability.x=-groups.ability.width-margin/2
    groups.consumable.x=margin/2
    groups.ability.y,groups.consumable.y=-height/2,-height/2
    return groups
end

bar.attach = function(objects,params,original)
    print('[Fangdango] Bar attach')
    local settings=params.settings
    local scale=settings.Size/100
    local factor=math.abs(scale)
    local spacing=(settings.Spacing or 10)/100
    local margin=settings.Margin or 0
    local switcher=objects.switcher
    local tree=assert(switcher:GetOuter(),'QuickslotsSwitcher WidgetTree unavailable')
    local hudRoot=objects.hud_root
    assert(Objects.valid(hudRoot),'HUD root invalid')
    assert(Objects.same(Objects.parent(objects.actions),hudRoot),
        'Actions must be attached to the HUD before Bar attach')
    local panels={}
    params.onCleanup(function()
        -- Restore the native wheels before removing their temporary host.
        for _,wheel in ipairs({objects.abilities,objects.consumables}) do
            if Objects.valid(wheel) and not Objects.same(Objects.parent(wheel),switcher) then
                Widget.reparent(wheel,switcher)
            end
        end
        for _,panel in ipairs(panels) do
            if Objects.valid(panel) and Objects.same(Objects.parent(panel),switcher) then
                assert(switcher:RemoveChild(panel)~=false,'could not remove switcher bait')
            end
        end
    end)
    local bait={
        {label='HUD BAIT',color={R=0.8,G=0.12,B=0.08,A=0.85}},
        {label='AA BAIT',color={R=0.06,G=0.25,B=0.8,A=0.85}},
    }
    for _,spec in ipairs(bait) do
        local panel=baitPanel(tree,spec.label,spec.color)
        panels[#panels+1]=panel
        assert(Objects.valid(switcher:AddChild(panel)),'could not add switcher bait')
    end
    -- Measure before reparenting the two wheel widgets and arranging their buttons.
    local measured={ability={},consumable={}}
    for _,kind in ipairs(kinds) do
        for index,button in ipairs(objects.buttons[kind..'Slots']) do
            measured[kind][index]=Widget.measure(button)
        end
    end
    local groups=plan(measured,factor,spacing,margin,settings.Tightness or -25)
    local actionsSlot=assert(Widget.property(objects.actions,'Slot'),'Actions HUD slot unavailable')
    assert(Objects.valid(actionsSlot),'Actions HUD slot unavailable')
    local slotClass=Objects.call(actionsSlot,'GetClass')
    local slotName=Objects.call(slotClass,'GetName')
    if slotName=='CanvasPanelSlot' then
        actionsSlot:SetLayout({
            Offsets={Left=0,Top=0,Right=0,Bottom=0},
            Anchors={Minimum={X=0.5,Y=0.5},Maximum={X=0.5,Y=0.5}},
            Alignment={X=0,Y=0},
        })
        actionsSlot:SetAutoSize(true)
    else
        local centered,why=pcall(function()
            actionsSlot:SetPadding({Left=0,Top=0,Right=0,Bottom=0})
            actionsSlot:SetHorizontalAlignment(1)
            actionsSlot:SetVerticalAlignment(1)
        end)
        assert(centered,'HUD root slot '..tostring(slotName)..' cannot center Actions: '..tostring(why))
    end
    Widget.setTranslation(objects.actions,0,0)
    for _,kind in ipairs(kinds) do
        local wheel=objects[kind=='ability' and 'abilities' or 'consumables']
        local box,panel=objects[kind..'_box'],objects[kind..'_panel']
        local group=groups[kind]
        moveToActions(wheel,objects.actions)
        Widget.setScale(wheel,1)
        box:SetWidthOverride(group.width)
        box:SetHeightOverride(group.height)
        Widget.setTranslation(wheel,group.x,group.y)
        for index,button in ipairs(objects.buttons[kind..'Slots']) do
            local point=group.points[index]
            Widget.reparent(button,panel)
            Widget.position(button,measured[kind][index],point.x,point.y,scale)
        end
        hideDecorations(panel,kind,params.onCleanup)
    end
    switcher:SetActiveWidgetIndex(math.min(1,math.max(0,original.switcher.activeIndex)))
    return original
end

return bar
