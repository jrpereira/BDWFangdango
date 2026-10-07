local MC = require('mc')
local Widget = MC.load('widget')
local Objects = MC.load('objects')
local Helpers=require('fangdango.helpers')
local log=Helpers.log

-- Spacing between neighbouring keys, as a fraction of the key size.
local SPC=0.075
-- A label's measured box runs past its drawn text, leaving a visible gap; a
-- Double bar's keys overlap it by this fraction of its reach on each side.
local LABEL_OVERLAP=0.5
-- Screen pixels between a key and its label beside it.
local LABEL_GAP=4
-- Slots are listed Left, Top, Right, Bottom; the bar runs L, T, R, B per wheel.
local sequence={1,2,3,4}
-- Key Indicators values by orientation: each lists its bar's own sides first.
local sides={horizontal={[0]='above','below','left','right'},
    vertical={[0]='left','right','above','below'}}

-- Screen edges, numbered as MCT's alignments, that a bar's Position offers.
local MIDDLE_RIGHT,BOTTOM_RIGHT,BOTTOM_CENTER=5,6,7
-- At Margin 0% a bar's anchors sit REFERENCE screen pixels above the bottom
-- and, at a right edge, in from the right, lining it up with the native HUD.
-- -100% brings the bar's outer edges to CORNER pixels from the screen's edges,
-- and each percent moves it as far again the other way up to 100%.
local REFERENCE,CORNER=160,8
-- A Single Underbar's line sits this many screen pixels lower for each side
-- of its labels.
local shiftPixels={above=16,below=41.6,left=48,right=48}
-- A Single Sidebar's 0% sits where these X and Y Margins would otherwise put
-- it, for each side of its labels.
local shiftPercent={left={-30,-40}}
local MARGINS={min=-100,max=100,step=5,suffix='%'}
local positionChoices={
    [true]={[MIDDLE_RIGHT]='Middle/Right',[BOTTOM_RIGHT]='Bottom/Right'},
    [false]={[BOTTOM_CENTER]='Bottom/Center',[BOTTOM_RIGHT]='Bottom/Right'},
}

-- Offset of a key from the shared center, one pitch per place; horizontal runs
-- right and vertical runs down.
-- Single puts both wheels in one bar: abilities end half a pitch before the
-- center and consumables start half a pitch after it, so neither wheel moves
-- when the other gains or loses keys.
-- Double gives each wheel its own full bar centered on the center, consumables
-- one row (or column) further from the screen edge by cross.
local function fan(w,i,n,double,vertical,pitchX,pitchY,cross)
    local along
    if double then along=i-2.5
    else along=w==1 and i-n-0.5 or i-0.5 end
    local x,y=0,along*pitchY
    if not vertical then x,y=along*pitchX,0 end
    if double and w==2 then
        if vertical then x=x-cross else y=y-cross end
    end
    return x,y
end

-- Empty slots take no place in a Single bar. A consumable slot is empty without
-- a displayed item; an ability slot is empty while its ability widget is hidden.
local function filled(button,w)
    if w==2 then
        return Objects.valid(Widget.property(button,'Displayed Item Asset'))
    end
    local ability=Widget.property(button,'AbilityWidget')
    return Objects.valid(ability) and Objects.call(ability,'IsVisible')~=false
end

-- Wheel decorations a bar has no use for.
local decorationNames={{'cross','Darken','Glow','Dpad'},{'cross','Dpad'}}

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
    log.trace('label unmeasured, treated as empty: ',box)
    local pivot=Widget.property(label,'RenderTransformPivot')
    return {width=0,height=0,pivotX=tonumber(Widget.property(pivot,'X')) or 0.5,
        pivotY=tonumber(Widget.property(pivot,'Y')) or 0.5}
end

-- Settings are named after the template's menu, e.g. SingleUnderbarK.
local function onAttach(id,vertical,double,objects,params,original)
    local settings=params.settings
    local abilityBox=original.wheels.abilities.box
    local consumableBox=original.wheels.consumables.box
    local boxes={abilityBox,consumableBox}

    -- A vertical bar sits in the bottom-right corner and a horizontal one at
    -- bottom center, unless the bar's Position chooses another edge.
    local align=vertical and BOTTOM_RIGHT or BOTTOM_CENTER
    if (double or not vertical) and positionChoices[vertical][settings[id..'A']] then
        align=settings[id..'A']
    end
    -- The wheels' shared box sits flush with the edge; the keys then move onto
    -- the reference lines.
    local screenScale=params.screen.scale or 1
    local positions=Helpers.pair({WheelsA=align,WheelsR=0,WheelsS=100},
        params.screen,abilityBox,consumableBox)
    local wheels={objects.wheels.abilities,objects.wheels.consumables}
    local slots={objects.buttons.abilitySlots,objects.buttons.consumableSlots}
    local labels={objects.labels.abilityLabels,objects.labels.consumableLabels}

    local scale=settings[id..'S']/100
    local factor=math.abs(scale)

    -- Lay out the shown keys in bar order: L, T, R, B of each wheel. A Single
    -- bar packs them; a Double bar keeps each slot's place, so a key and the one
    -- beside it in the other row share a binding. An empty key may have no size,
    -- so the pitch comes from the first shown key.
    local shown,counts,first={},{},nil
    for w=1,2 do
        shown[w],counts[w]={},0
        for _,index in ipairs(sequence) do
            if filled(slots[w][index],w) then
                counts[w]=counts[w]+1
                shown[w][index]=double and index or counts[w]
                first=first or Widget.measure(slots[w][index])
            end
        end
    end
    log.debug(id,': align ',align,', size ',settings[id..'S'],'%, keys shown ',
        counts[1],' ability, ',counts[2],' consumable')
    if not first then log.debug(id,': no key shown; nothing to lay out') end
    local W,H=first and first.width*factor or 0,first and first.height*factor or 0
    local pitchX,pitchY=W*(1+SPC),H*(1+SPC)
    -- The largest shown label sets the labels' reach.
    local labelW,labelH=0,0
    for w=1,2 do
        for index in pairs(shown[w]) do
            local box=labelBox(labels[w][index])
            labelW,labelH=math.max(labelW,box.width*factor),math.max(labelH,box.height*factor)
        end
    end

    -- The point placed on the reference lines, as an offset right and down
    -- from the ability wheel's center, before any shift. Each comes from the
    -- full run, so no key moves when another gains or loses its item.
    -- Outer edges are the full run's lowest and rightmost reach of keys and
    -- labels, from the same center.
    local labelX,labelY,cross,anchorX,anchorY,right,bottom=0,0,0,0,0,0,0
    local shift,calibration=0,nil
    if double then
        -- Both rows share one binding label per slot, centered in the gap
        -- between them; the gap fits the drawn text of the largest shown label
        -- across the bar, without its box's blank edges.
        local reach=vertical and labelW or labelH
        local key=vertical and W or H
        cross=key+reach*(1-2*LABEL_OVERLAP)+2*key*SPC
        -- A column's labels between its keys center on the line along them,
        -- and a row's labels hang from it by their top edge; across, the last
        -- label towards the corner centers on it.
        if vertical then
            anchorX,anchorY=-cross/2,1.5*pitchY
            right=math.max(W/2,-cross/2+labelW/2)
            bottom=1.5*pitchY+math.max(H/2,labelH/2)
        else
            anchorX,anchorY=1.5*pitchX,-cross/2-reach/2
            right=1.5*pitchX+math.max(W/2,labelW/2)
            bottom=H/2
        end
    else
        -- Binding labels sit centered on their chosen edge of the key.
        local side=vertical and (sides.vertical[settings[id..'K']] or 'left')
            or (sides.horizontal[settings[id..'K']] or 'above')
        labelX=side=='left' and -W/2 or side=='right' and W/2 or 0
        labelY=side=='above' and -H/2 or side=='below' and H/2 or 0
        -- A column's labels on its left end on the line along it, at the edge
        -- facing their keys, and a row's labels above hang from it by their top
        -- edge; otherwise the keys center on it. Across, the last label towards
        -- the corner centers on the line.
        local along=0
        if side==(vertical and 'left' or 'above') then
            along=vertical and labelX+labelW/2 or labelY-labelH/2
        end
        if vertical then
            anchorX,anchorY=along,3.5*pitchY+labelY
            calibration=shiftPercent[side]
        else
            anchorX,anchorY=3.5*pitchX+labelX,along
            shift=shiftPixels[side] or 0
        end
        -- Labels beside their keys keep clear of them; the keys stay put.
        if side=='left' or side=='right' then
            labelX=labelX+(side=='left' and -1 or 1)*LABEL_GAP/screenScale
        end
        right=math.max(W/2,labelX+labelW/2)
        bottom=math.max(H/2,labelY+labelH/2)
        if vertical then bottom=3.5*pitchY+bottom else right=3.5*pitchX+right end
    end
    -- Place the lines for 0%, then step them so -100% leaves CORNER pixels
    -- between the outer edges and the screen's.
    local margin=settings[id..'M'] or 0
    local lineX=params.screen.width-REFERENCE/screenScale
    local lineY=params.screen.height-(REFERENCE-shift)/screenScale
    -- A row in the corner keeps as far from the right edge as from the bottom.
    if not vertical and align==BOTTOM_RIGHT then
        lineX=lineX+(lineY-anchorY+bottom)-params.screen.height+params.screen.width
            -(lineX-anchorX+right)
    end
    local function steps()
        return (params.screen.width-(lineX-anchorX+right)-CORNER/screenScale)/100,
            (params.screen.height-(lineY-anchorY+bottom)-CORNER/screenScale)/100
    end
    local stepX,stepY=steps()
    if calibration then
        lineX,lineY=lineX-stepX*calibration[1],lineY-stepY*calibration[2]
        stepX,stepY=steps()
    end
    lineX,lineY=lineX-stepX*margin,lineY-stepY*margin
    log.debug(id,': margin ',margin,'%, step ',stepX,' x ',stepY)
    local groupHeight=math.max(abilityBox.height,consumableBox.height)

    for w=1,2 do
        local position=positions[w]
        local placed, reason=Widget.canvasPosition(wheels[w], position.box, position.x, position.y, 1)
        assert(placed,reason)
        Helpers.hideDecorations(wheels[w],decorationNames[w],params.onCleanup)

        -- Anchors meet the reference lines; a row at Bottom/Center stays
        -- centered, and a column at Middle/Right centers on the box.
        local dx=lineX-(position.x+boxes[w].width/2)-anchorX
        local dy=lineY-(position.y+boxes[w].height/2)-anchorY
        if align==BOTTOM_CENTER then dx=0 end
        if align==MIDDLE_RIGHT then dy=groupHeight/2-boxes[w].height/2 end
        -- A Double bar's label sits halfway towards the other row.
        if double then
            local toward=w==1 and -cross/2 or cross/2
            if vertical then labelX=toward else labelY=toward end
        end

        for index,button in ipairs(slots[w]) do
            local label=labels[w][index]
            local place=shown[w][index]
            if place then
                local x,y=fan(w,place,counts[w],double,vertical,pitchX,pitchY,cross)
                x,y=x+dx,y+dy
                center(button,Widget.measure(button),x,y,scale)
                -- Text is never mirrored.
                center(label,labelBox(label),x+labelX,y+labelY,factor)
            else
                -- An empty key draws nothing; hide its label too.
                Widget.setOpacity(label,0)
            end
        end
    end
    -- The native prompt describes swapping the switcher's active panel; bars
    -- show both wheels at once.
    Widget.setOpacity(objects.change_prompt,0)
    -- A rebuild restores native opacity; apply the current focus.
    Helpers.onGroupFocus(params,{name='controls.group.focus',group=params.state.controls.group},objects)
    return original
end

-- Single and Double Underbar and Sidebar differ in orientation and in whether
-- the wheels share one row or take one each. Single bars choose where their
-- Key Indicators sit, listing the bar's own sides first; Double bars share them
-- between the rows. All but the Single Sidebar, always at Bottom/Right, choose
-- their Position.
local function bar(name,id,vertical,double,indicators)
    local fields={
        {id='.S', label='Size', values=Helpers.SIZES, default=100},
        {id='.M', label='Margin to Screen Edge', values=MARGINS, default=0},
    }
    if not double then
        table.insert(fields,1,{id='.K', label='Key Indicators', values=indicators, default=0})
    end
    if double or not vertical then
        table.insert(fields,1,{id='.A', label='Position', values=positionChoices[vertical],
            default=vertical and BOTTOM_RIGHT or BOTTOM_CENTER})
    end
    return {
        name=name,
        description=('Arrange quickslot keys in %s %s.'):format(double and 'two' or 'one',
            vertical and (double and 'columns' or 'column') or (double and 'rows' or 'row')),
        category='player.quickslots',
        settings={focus={dim=0.7}},
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
        menu={{id=id, label=name, fields=fields}},
        events={['controls.group.focus']=Helpers.onGroupFocus},
        attach=function(objects,params,original)
            return onAttach(id,vertical,double,objects,params,original)
        end,
    }
end

local horizontal={[0]='Above',[1]='Below',[2]='Left',[3]='Right'}
local vertical={[0]='Left',[1]='Right',[2]='Above',[3]='Below'}
return {
    bar('Single Underbar','SingleUnderbar',false,false,horizontal),
    bar('Double Underbar','DoubleUnderbar',false,true),
    bar('Single Sidebar','SingleSidebar',true,false,vertical),
    bar('Double Sidebar','DoubleSidebar',true,true),
}
