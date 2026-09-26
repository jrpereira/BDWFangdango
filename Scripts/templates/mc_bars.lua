local targets={
    switcher={},abilities={},consumables={},
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
    targets=targets, settings={Spacing=10},
    menu={target='module',enabled=true,fields={
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
    local owner=assert(MC.parent(objects.switcher),'HUD panel unavailable')
    local slate=assert(StaticFindObject('/Script/UMG.Default__SlateBlueprintLibrary'),
        'Slate coordinate conversion unavailable')
    local center={X=0,Y=0}
    slate:ScreenToWidgetLocal(owner,owner:GetCachedGeometry(),
        {X=params.screen.center,Y=params.screen.middle},center,true)
    center={X=Widget.number(center,'X'),Y=Widget.number(center,'Y')}
    -- Measure before reparenting the two wheel widgets and arranging their buttons.
    local measured={ability={},consumable={}}
    for _,kind in ipairs(kinds) do
        for index,button in ipairs(objects.buttons[kind..'Slots']) do
            measured[kind][index]=Widget.measure(button)
        end
    end
    local groups=plan(measured,factor,spacing,margin,settings.Tightness or -25)
    for _,kind in ipairs(kinds) do
        local wheel=objects[kind=='ability' and 'abilities' or 'consumables']
        local box,panel=objects[kind..'_box'],objects[kind..'_panel']
        local group=groups[kind]
        Widget.reparent(wheel,owner)
        Widget.setScale(wheel,1)
        box:SetWidthOverride(group.width)
        box:SetHeightOverride(group.height)
        Widget.setTranslation(wheel,center.X+group.x,center.Y+group.y)
        for index,button in ipairs(objects.buttons[kind..'Slots']) do
            local point=group.points[index]
            Widget.reparent(button,panel)
            Widget.position(button,measured[kind][index],point.x,point.y,scale)
        end
        hideDecorations(panel,kind,params.onCleanup)
    end
    return original
end

return bar
