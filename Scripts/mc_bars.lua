local MC = require('mc')
local Widget = MC.load('widget')
local Objects = MC.load('objects')
local Helpers=require('fangdango.helpers')

local template = {
    name='Bars Fangdango',
    description='Arrange quickslot keys in a horizontal or vertical bar.',

    category='player.quickslots',
    settings={focus={dim=0.7}},
    events={
        ['controls.group.focus']=Helpers.onGroupFocus,
    },
    -- Both wheels overlap at the chosen edge, as in Wheels' Overlap placement.
    -- Bars then lines every key and its binding label up from that shared
    -- center; nothing is reparented.
    objects={
        wheels={abilities={},consumables={},
            properties={'box','slot','position','size','opacity'}},
        change_prompt={properties={'opacity'}},
        buttons={
            abilitySlots={'ability_button_left','ability_button_top','ability_button_right','ability_button_bottom'},
            consumableSlots={'consumable_button_left','consumable_button_top','consumable_button_right','consumable_button_bottom'},
            properties={'slot','position','size'},
        },
        labels={
            abilityLabels={'ability_left','ability_top','ability_right','ability_bottom'},
            consumableLabels={'consumable_left','consumable_top','consumable_right','consumable_bottom'},
            properties={'slot','position','size','opacity'},
        },
    },
    menu = {
        {id='Bars', label='Bars', fields={
            {id='.A', label='Orientation', values={[7]='Horizontal', [5]='Vertical'}, default=7},
            {id='.KH', label='Horizontal Key Indicators', values={[0]='Above', [1]='Below'}, default=0,
                conditions={visible={field='.A', match={7}}}},
            {id='.KV', label='Vertical Key Indicators', values={[0]='Left', [1]='Right'}, default=0,
                conditions={visible={field='.A', match={5}}}},
            {id='.S', label='Size',
                values={min=-50,max=100,step=10,suffix='%'}, default=100},
            {id='.M', label='Margin to Screen Edge',
                values={min=-100,max=100,step=10,suffix='%'}, default=0},
        }},
    }
}

-- Spacing between neighbouring keys, as a fraction of the key size.
local SPC=0.075
-- Slots are listed Left, Top, Right, Bottom; the bar runs L, T, R, B per wheel.
local sequence={1,2,3,4}

-- Offset of a shown key from the shared center, which is the edge between the
-- two wheels. Shown keys are one pitch apart: abilities end half a pitch before
-- the center and consumables start half a pitch after it, so neither wheel
-- moves when the other gains or loses keys. Horizontal runs right; vertical
-- runs down, so abilities end up above.
local function fan(w,i,n,vertical,pitchX,pitchY)
    local along=w==1 and i-n-0.5 or i-0.5
    if vertical then return 0,along*pitchY end
    return along*pitchX,0
end

-- Empty slots take no place in the bar. A consumable slot is empty without a
-- displayed item; an ability slot is empty while its ability widget is hidden.
local function filled(button,w)
    if w==2 then
        return Objects.valid(Widget.property(button,'Displayed Item Asset'))
    end
    local ability=Widget.property(button,'AbilityWidget')
    return Objects.valid(ability) and Objects.call(ability,'IsVisible')~=false
end

-- Decorations are named children, not members, so MCT cannot target them.
-- Find them by name and restore them through onCleanup.
local decorationNames={{'cross','Darken','Glow','Dpad'},{'cross','Dpad'}}
local function findChild(root,name)
    if not Objects.valid(root) then return nil end
    local full=Objects.call(root,'GetFullName')
    if type(full)=='string' and full:sub(-#name-1)=='.'..name then return root end
    -- A UserWidget is not a panel; its children hang off its WidgetTree's root.
    local tree=Widget.property(Widget.property(root,'WidgetTree'),'RootWidget')
    if tree then return findChild(tree,name) end
    local count=Objects.call(root,'GetChildrenCount')
    if type(count)~='number' then return nil end
    for index=0,count-1 do
        local found=findChild(Objects.call(root,'GetChildAt',index),name)
        if found then return found end
    end
end

local function hideDecorations(wheel,names,onCleanup)
    for _,name in ipairs(names) do
        local decoration=findChild(wheel,name)
        if decoration then
            local opacity=Widget.opacity(decoration)
            onCleanup(function()
                if Objects.valid(decoration) then Widget.setOpacity(decoration,opacity) end
            end)
            Widget.setOpacity(decoration,0)
        end
    end
end

-- Center a widget in its overlay, then place its scaled center at x,y from there.
local function center(widget,box,x,y,scale)
    local slot=assert(Widget.slot(widget),'quickslot widget slot unavailable')
    slot:SetPadding({Left=0,Top=0,Right=0,Bottom=0})
    slot:SetHorizontalAlignment(2)
    slot:SetVerticalAlignment(2)
    local factor=math.abs(scale)
    Widget.position(widget,box,x+box.width*(1-factor)/2,y+box.height*(1-factor)/2,scale)
end

-- A label may be empty while its key is unbound; it still moves with its key.
local function labelBox(label)
    local ok,box=pcall(Widget.measure,label)
    if ok then return box end
    local pivot=Widget.property(label,'RenderTransformPivot')
    return {width=0,height=0,pivotX=tonumber(Widget.property(pivot,'X')) or 0.5,
        pivotY=tonumber(Widget.property(pivot,'Y')) or 0.5}
end

template.attach = function(objects, params, original)
    local settings=params.settings
    local abilityBox=original.wheels.abilities.box
    local consumableBox=original.wheels.consumables.box
    local boxes={abilityBox,consumableBox}

    -- Orientation 5 (Vertical) sits in the bottom-right corner; Horizontal at
    -- bottom center.
    local vertical=settings.BarsA==5
    local positions=Helpers.pair({WheelsA=vertical and 6 or 7,WheelsR=0,WheelsS=100,
        WheelsM=settings.BarsM},params.screen,abilityBox,consumableBox)
    local wheels={objects.wheels.abilities,objects.wheels.consumables}
    local slots={objects.buttons.abilitySlots,objects.buttons.consumableSlots}
    local labels={objects.labels.abilityLabels,objects.labels.consumableLabels}

    local scale=settings.BarsS/100
    local factor=math.abs(scale)

    -- Lay out the shown keys in bar order: L, T, R, B of each wheel. An empty
    -- key may have no size, so the pitch comes from the first shown key.
    local shown,counts,first={},{},nil
    for w=1,2 do
        shown[w],counts[w]={},0
        for _,index in ipairs(sequence) do
            if filled(slots[w][index],w) then
                counts[w]=counts[w]+1
                shown[w][index]=counts[w]
                first=first or Widget.measure(slots[w][index])
            end
        end
    end
    local W,H=first and first.width*factor or 0,first and first.height*factor or 0
    local pitchX,pitchY=W*(1+SPC),H*(1+SPC)

    -- Binding labels sit above or below their keys in a horizontal bar, left or
    -- right of them in a vertical one. Right of the keys, the widest shown
    -- label sets the column's reach.
    local below=settings.BarsKH==1
    local right=settings.BarsKV==1
    local labelWidth=0
    if vertical and right then
        for w=1,2 do
            for index in pairs(shown[w]) do
                labelWidth=math.max(labelWidth,labelBox(labels[w][index]).width*factor)
            end
        end
    end
    local groupWidth=math.max(abilityBox.width,consumableBox.width)
    local groupHeight=math.max(abilityBox.height,consumableBox.height)

    for w=1,2 do
        local position=positions[w]
        local placed, reason=Widget.canvasPosition(wheels[w], position.box, position.x, position.y, 1)
        assert(placed,reason)
        hideDecorations(wheels[w],decorationNames[w],params.onCleanup)

        -- The vertical column, with any labels on its right, fills the corner:
        -- its right edge and the bottom of a full consumable run meet the
        -- wheels' shared box, so no key moves when another gains or loses its item.
        local dx,dy=0,0
        if vertical then
            dx=groupWidth-boxes[w].width/2-W/2-(right and W*SPC+labelWidth or 0)
            dy=groupHeight-boxes[w].height/2-(3.5*pitchY+H/2)
        end

        for index,button in ipairs(slots[w]) do
            local label=labels[w][index]
            local place=shown[w][index]
            if place then
                local x,y=fan(w,place,counts[w],vertical,pitchX,pitchY)
                x,y=x+dx,y+dy
                center(button,Widget.measure(button),x,y,scale)
                -- In a horizontal bar the binding label sits centered on its key's
                -- top or bottom edge; in a vertical one it sits left or right of
                -- its key, level with it. Text is never mirrored.
                local box=labelBox(label)
                if vertical then
                    local side=W/2+W*SPC+box.width*factor/2
                    center(label,box,x+(right and side or -side),y,factor)
                else
                    center(label,box,x,y+(below and H/2 or -H/2),factor)
                end
            else
                -- An empty key draws nothing; hide its label too.
                Widget.setOpacity(label,0)
            end
        end
    end
    -- The native prompt describes swapping the switcher's active panel; Bars
    -- shows every key at once.
    Widget.setOpacity(objects.change_prompt,0)
    -- A rebuild restores native opacity; apply the current focus.
    template.events['controls.group.focus'](params,
        {name='controls.group.focus',group=params.state.controls.group},objects)
    return original
end

return template
