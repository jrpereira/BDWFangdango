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
-- Pixels between a key and its label beside it, scaled like the distances below.
local LABEL_GAP=4

-- Screen edges, numbered as MCT's alignments; a bar's Position offers them by key.
local MIDDLE_RIGHT,BOTTOM_RIGHT,BOTTOM_CENTER=Helpers.ALIGNS.middle_right,Helpers.ALIGNS.bottom_right,
    Helpers.ALIGNS.bottom_center
-- Distances here are pixels of a 1080-high screen, scaled to the screen's own
-- units by Helpers.unit. At Margin 0% a bar's anchors sit REFERENCE pixels
-- above the bottom and, at a right edge, in from the right, lining it up with
-- the native HUD. -100% brings the bar's outer edges to CORNER pixels from the
-- screen's edges, and each percent moves it as far again the other way up to
-- 100%.
local REFERENCE,CORNER=160,8
-- A Single Underbar's line sits this many pixels lower for each side of its
-- labels.
local shiftPixels={above=16,below=41.6,left=48,right=48}
-- A Single Sidebar's 0% sits where these X and Y Margins would otherwise put
-- it, for each side of its labels.
local shiftPercent={left={-30,-40}}
local MARGINS={min=-100,max=100,step=5,suffix='%'}
-- Each orientation's Position choices and its default edge.
local positionChoices={
    [true]=Helpers.edges({'middle_right','bottom_right'}),
    [false]=Helpers.edges({'bottom_right','bottom_center'}),
}
local positionDefault={[true]='bottom_right',[false]='bottom_center'}
-- Whether a list of keyed choices offers a key.
local function offers(choices,key)
    for _,choice in ipairs(choices) do if choice.key==key then return true end end
    return false
end

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

-- Wheel decorations a bar has no use for, found by name. They are not blueprint members,
-- so MCT's ability_cross, ability_darken, ability_glow and consumable_cross targets never
-- resolve (checked live, 2026-11-16); declaring them leaves the template not ready.
local decorationNames={{'cross','Darken','Glow','Dpad'},{'cross','Dpad'}}

-- Center a widget in its overlay, then place its scaled center at x,y from there.
local function center(widget,box,x,y,scale)
    local slot=assert(Widget.slot(widget),'quickslot widget slot unavailable')
    slot:SetPadding({Left=0,Top=0,Right=0,Bottom=0})
    slot:SetHorizontalAlignment(2)
    slot:SetVerticalAlignment(2)
    Widget.position(widget,box,x+box.width*(1-scale)/2,y+box.height*(1-scale)/2,scale)
end

-- A shown key without a layout size yet waits: MCT retries a 'not_ready'
-- attach on its next lifecycle event without reporting an error.
local function measureKey(button)
    local ok,box=pcall(Widget.measure,button)
    if ok then return box end
    if tostring(box):find('layout size is not ready',1,true) then
        error('not_ready: key layout',0)
    end
    error(box,0)
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

-- Whether any quickslot of either wheel has a ModCore Controls Global key.
local function anyGlobal(global)
    for w=1,2 do
        for index=1,4 do
            if Helpers.globalKey(global,w,index) then return true end
        end
    end
    return false
end

-- A Double bar merges its labels while Merge is on and no quickslot has a
-- Global key: both labels of a slot share one place between the rows, as they
-- name the same grouped key, and only the focused wheel's shows. Otherwise
-- every shown key's own label sits on its Key Indicators side, dimmed by focus
-- and Global keys as elsewhere. Runs again on every focus and Global keys
-- event, after Helpers has applied the focus and the keys have their place.
local function pairLabels(layout,params,group,global,objects,merged)
    local focused=group and group.to
    local tint=params.settings.focus.tint
    local labels={objects.labels.abilityLabels,objects.labels.consumableLabels}
    for w=1,2 do
        local toward=w==1 and -layout.toward or layout.toward
        for index=1,4 do
            local key=layout.points[w][index]
            if key then
                local label=labels[w][index]
                local x,y=key.x+layout.labelX,key.y+layout.labelY
                if merged then
                    x,y=key.x,key.y
                    if layout.vertical then x=x+toward else y=y+toward end
                end
                center(label,labelBox(label),x,y,layout.scale)
                if merged and layout.points[3-w][index] then
                    Widget.setOpacity(label,(focused==2 and 2 or 1)==w and 1 or 0)
                else
                    -- Any other shown label dims with its wheel, as Helpers does:
                    -- not at all before ModCore Controls reports a focus.
                    local lit=(focused~=1 and focused~=2) or focused==w
                        or Helpers.globalKey(global,w,index)
                    Widget.setOpacity(label,lit and 1 or tint.A)
                end
            end
        end
    end
end

local function globalOf(params,event)
    local controls=params.state and params.state.controls
    return event.global or controls and controls.global
end

-- Place every shown key of a layout, its rows layout.cross apart; a Single
-- bar's labels go with their keys, and an empty key's label hides.
local function placeKeys(layout,objects)
    local slots={objects.buttons.abilitySlots,objects.buttons.consumableSlots}
    local labels={objects.labels.abilityLabels,objects.labels.consumableLabels}
    local points={{},{}}
    for w=1,2 do
        for index,button in ipairs(slots[w]) do
            local label=labels[w][index]
            local place=layout.shown[w][index]
            if place then
                local x,y=fan(w,place,layout.counts[w],layout.double,layout.vertical,
                    layout.pitchX,layout.pitchY,layout.cross)
                x,y=x+layout.dx[w],y+layout.dy[w]
                points[w][index]={x=x,y=y}
                center(button,layout.boxes[w][index],x,y,layout.scale)
                -- A Double bar's labels are placed by pairLabels.
                if not layout.double then
                    center(label,labelBox(label),x+layout.labelX,y+layout.labelY,layout.scale)
                end
            elseif not layout.double or not layout.points then
                -- An empty key draws nothing; hide its label too.
                Widget.setOpacity(label,0)
            end
        end
    end
    layout.points=points
end

-- A Double bar's rows sit the merged gap apart while its labels merge, and
-- the wider unmerged gap otherwise.
local function mergesFor(layout,global)
    return layout.merge and not anyGlobal(global)
end

-- After a focus or Global keys event: a change in whether the labels merge
-- moves the far row to its gap, then the labels follow.
local function refresh(layout,params,group,global,objects)
    if not layout then return end
    local merged=mergesFor(layout,global)
    local cross=merged and layout.mergedCross or layout.wideCross
    if cross~=layout.cross then
        local previous=layout.cross
        layout.cross=cross
        local ok,why=pcall(placeKeys,layout,objects)
        if not ok then layout.cross=previous;error(why,0) end
        log.debug(layout.id,': rows ',cross,' apart, labels ',merged and 'merged' or 'unmerged')
    end
    pairLabels(layout,params,group,global,objects,merged)
end

-- Settings are named after the template's menu, e.g. SingleUnderbarK.
local function onAttach(id,vertical,double,indicators,objects,params,original,store)
    local settings=params.settings
    local abilityBox=original.wheels.abilities.box
    local consumableBox=original.wheels.consumables.box
    local boxes={abilityBox,consumableBox}

    -- A vertical bar sits in the bottom-right corner and a horizontal one at
    -- bottom center, unless the bar's Position chooses another edge.
    local align=vertical and BOTTOM_RIGHT or BOTTOM_CENTER
    if (double or not vertical) and offers(positionChoices[vertical],settings[id..'A']) then
        align=Helpers.ALIGNS[settings[id..'A']]
    end
    -- The wheels' shared box sits flush with the edge; the keys then move onto
    -- the reference lines.
    local unit=Helpers.unit(params.screen)
    local groupWidth=math.max(abilityBox.width,consumableBox.width)
    local groupHeight=math.max(abilityBox.height,consumableBox.height)
    local left,top=Helpers.edge(params.screen,align,0,groupWidth,groupHeight)
    local wheels={objects.wheels.abilities,objects.wheels.consumables}
    local slots={objects.buttons.abilitySlots,objects.buttons.consumableSlots}
    local labels={objects.labels.abilityLabels,objects.labels.consumableLabels}
    local keyBoxes={{},{}}

    local scale=Helpers.SCALES[settings[id..'S']] or 1

    -- Slots are listed Left, Top, Right, Bottom; lay out the shown keys in bar
    -- order: L, T, R, B of each wheel. A Single
    -- bar packs them; a Double bar keeps each slot's place, so a key and the one
    -- beside it in the other row share a binding unless one of them has a
    -- Global key (see pairLabels). An empty key may have no size,
    -- so the pitch comes from the first shown key.
    local shown,counts,first={},{},nil
    for w=1,2 do
        shown[w],counts[w]={},0
        for index=1,4 do
            if filled(slots[w][index],w) then
                counts[w]=counts[w]+1
                shown[w][index]=double and index or counts[w]
                keyBoxes[w][index]=measureKey(slots[w][index])
                first=first or keyBoxes[w][index]
            end
        end
    end
    log.debug(id,': align ',align,', size ',settings[id..'S'],', keys shown ',
        counts[1],' ability, ',counts[2],' consumable')
    if not first then log.debug(id,': no key shown; nothing to lay out') end
    local W,H=first and first.width*scale or 0,first and first.height*scale or 0
    local pitchX,pitchY=W*(1+SPC),H*(1+SPC)
    -- The largest shown label sets the labels' reach.
    local labelW,labelH=0,0
    for w=1,2 do
        for index in pairs(shown[w]) do
            local box=labelBox(labels[w][index])
            labelW,labelH=math.max(labelW,box.width*scale),math.max(labelH,box.height*scale)
        end
    end

    -- The point placed on the reference lines, as an offset right and down
    -- from the ability wheel's center, before any shift. Each comes from the
    -- full run, so no key moves when another gains or loses its item.
    -- Outer edges are the full run's lowest and rightmost reach of keys and
    -- labels, from the same center.
    local mergedCross,wideCross,anchorX,anchorY,right,bottom=0,0,0,0,0,0
    local shift,calibration=0,nil
    -- Binding labels a bar does not merge sit centered on their chosen edge of
    -- the key. Key Indicators name a side, listing the bar's own sides first.
    local side=settings[id..'K']
    if not offers(indicators,side) then side=indicators[1].key end
    local labelX=side=='left' and -W/2 or side=='right' and W/2 or 0
    local labelY=side=='above' and -H/2 or side=='below' and H/2 or 0
    -- Labels beside their keys keep clear of them; the keys stay put.
    local besideX=labelX
    if side=='left' or side=='right' then
        besideX=labelX+(side=='left' and -1 or 1)*LABEL_GAP*unit
    end
    if double then
        -- Merged labels share one place per slot, centered in the gap between
        -- the rows; the gap fits the drawn text of the largest shown label
        -- across the bar, without its box's blank edges.
        local reach=vertical and labelW or labelH
        local key=vertical and W or H
        mergedCross=key+reach*(1-2*LABEL_OVERLAP)+2*key*SPC
        -- Unmerged labels on a side across the bar enter the gap from one row:
        -- it then fits the keys, the labels' reach past their key and one
        -- spacing, so they clear the other row's keys, and never narrows.
        -- Labels on a side along the bar stay level with their keys, so the
        -- gap stays the merged one.
        wideCross=mergedCross
        if (vertical and (side=='left' or side=='right'))
            or (not vertical and (side=='above' or side=='below')) then
            local past=vertical and LABEL_GAP*unit+labelW/2 or labelH/2
            wideCross=math.max(mergedCross,key+past+key*SPC)
        end
        -- A column's labels between its keys center on the line along them,
        -- and a row's labels hang from it by their top edge; across, the last
        -- label towards the corner centers on it. The row nearest the edge
        -- holds these lines in both gaps, the far row moving away from the
        -- edge, and the outer edges take the merged and unmerged labels' reach
        -- alike.
        if vertical then
            anchorX,anchorY=-mergedCross/2,1.5*pitchY
            right=math.max(W/2,-mergedCross/2+labelW/2,besideX+labelW/2)
            bottom=1.5*pitchY+math.max(H/2,labelH/2,labelY+labelH/2)
        else
            anchorX,anchorY=1.5*pitchX,-mergedCross/2-reach/2
            right=1.5*pitchX+math.max(W/2,labelW/2,besideX+labelW/2)
            bottom=math.max(H/2,labelY+labelH/2)
        end
        labelX=besideX
    else
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
        labelX=besideX
        right=math.max(W/2,labelX+labelW/2)
        bottom=math.max(H/2,labelY+labelH/2)
        if vertical then bottom=3.5*pitchY+bottom else right=3.5*pitchX+right end
    end
    -- Place the lines for 0%, then step them so -100% leaves CORNER pixels
    -- between the outer edges and the screen's.
    local margin=settings[id..'M'] or 0
    local lineX=params.screen.width-REFERENCE*unit
    local lineY=params.screen.height-(REFERENCE-shift)*unit
    -- A row in the corner keeps as far from the right edge as from the bottom.
    if not vertical and align==BOTTOM_RIGHT then
        lineX=lineX+(lineY-anchorY+bottom)-params.screen.height+params.screen.width
            -(lineX-anchorX+right)
    end
    local function steps()
        return (params.screen.width-(lineX-anchorX+right)-CORNER*unit)/100,
            (params.screen.height-(lineY-anchorY+bottom)-CORNER*unit)/100
    end
    local stepX,stepY=steps()
    if calibration then
        lineX,lineY=lineX-stepX*calibration[1],lineY-stepY*calibration[2]
        stepX,stepY=steps()
    end
    lineX,lineY=lineX-stepX*margin,lineY-stepY*margin
    log.debug(id,': margin ',margin,'%, step ',stepX,' x ',stepY)
    -- A Double bar's rows start in the gap for the current Global keys.
    local event={name='controls.group.focus',group=params.state.controls.group}
    local global=globalOf(params,event)
    local layout={id=id,shown=shown,counts=counts,double=double,vertical=vertical,
        pitchX=pitchX,pitchY=pitchY,scale=scale,boxes=keyBoxes,dx={},dy={},
        labelX=labelX,labelY=labelY,toward=mergedCross/2,merge=settings[id..'J']~=0,
        mergedCross=mergedCross,wideCross=wideCross,cross=0}
    if double then
        layout.cross=mergesFor(layout,global) and mergedCross or wideCross
    end

    for w=1,2 do
        local placed, reason=Widget.canvasPosition(wheels[w], boxes[w], left, top, 1)
        assert(placed,reason)
        Helpers.hideDecorations(wheels[w],decorationNames[w],params.onCleanup)

        -- Anchors meet the reference lines; a row at Bottom/Center centers on
        -- the shared box, and a column at Middle/Right too.
        local dx=lineX-(left+boxes[w].width/2)-anchorX
        local dy=lineY-(top+boxes[w].height/2)-anchorY
        if align==BOTTOM_CENTER then dx=groupWidth/2-boxes[w].width/2 end
        if align==MIDDLE_RIGHT then dy=groupHeight/2-boxes[w].height/2 end
        layout.dx[w],layout.dy[w]=dx,dy
    end
    placeKeys(layout,objects)
    -- The native prompt describes swapping the switcher's active panel; bars
    -- show both wheels at once.
    Widget.setOpacity(objects.change_prompt,0)
    if double then
        store.layout=layout
        params.onCleanup(function() if store.layout==layout then store.layout=nil end end)
    end
    -- A rebuild restores native opacity; apply the current focus.
    Helpers.onGroupFocus(params,event,objects)
    if double then pairLabels(layout,params,event.group,global,objects,mergesFor(layout,global)) end
    return original
end

-- Single and Double Underbar and Sidebar differ in orientation and in whether
-- the wheels share one row or take one each. Every bar chooses where its Key
-- Indicators sit, listing the bar's own sides first; Double bars may also merge
-- them between the rows. All but the Single Sidebar, always at Bottom/Right,
-- choose their Position.
local function bar(id,label,vertical,double,indicators)
    local fields={
        {id='.K', label='Key Indicators', values=indicators, default=indicators[1].key,
            description='The side of its key each binding label shows on.'},
        {id='.S', label='Size', values=Helpers.SIZES, default='standard',
            description='The size of the keys and their binding labels.'},
        {id='.M', label='Margin to Screen Edge', values=MARGINS, default=0,
            description='How far the bar sits from the screen edge, 0% lining it up with the game\'s own HUD.'},
    }
    if double then
        table.insert(fields,2,{id='.J', label='Merge key indicators when possible',
            values={[0]='Off',[1]='On'}, widget='switch', default=1,
            description='Shows one binding label between the rows for each slot, while no quickslot has a Global key from ModCore Controls.'})
    end
    if double or not vertical then
        table.insert(fields,1,{id='.A', label='Position', values=positionChoices[vertical],
            default=positionDefault[vertical], description='The screen edge the bar sits at.'})
    end
    -- The last attach's Double layout, for its events.
    local store={}
    return {
        id=id,
        label=label,
        description=('Arrange quickslot keys in %s %s.'):format(double and 'two' or 'one',
            vertical and (double and 'columns' or 'column') or (double and 'rows' or 'row')),
        category='player.quickslots',
        uniqueBy='category',
        settings=Helpers.SETTINGS,
        preview=Helpers.PREVIEW,
        -- Both wheels overlap at the chosen edge, as in Wheels' Overlap placement.
        -- Bars then lines every key and its binding label up from that shared
        -- center; nothing is reparented.
        objects={
            wheels={abilities={},consumables={},
                properties={'box','slot','position','size','opacity'}},
            change_prompt={properties={'opacity'}},
            buttons={
                abilitySlots=Helpers.BUTTONS.abilitySlots,
                consumableSlots=Helpers.BUTTONS.consumableSlots,
                properties={'slot','position','size','color'},
            },
            labels={
                abilityLabels=Helpers.LABELS.abilityLabels,
                consumableLabels=Helpers.LABELS.consumableLabels,
                properties={'slot','position','size','opacity'},
            },
        },
        menu={{id=id, label=label, fields=fields}},
        events={
            ['controls.group.focus']=function(params,event,objects)
                Helpers.onGroupFocus(params,event,objects)
                refresh(store.layout,params,event.group,globalOf(params,event),objects)
            end,
            ['controls.slots.global']=function(params,event,objects)
                Helpers.onGlobalKeys(params,event,objects)
                local controls=params.state and params.state.controls
                refresh(store.layout,params,controls and controls.group,event.global,objects)
            end,
        },
        attach=function(objects,params,original)
            return onAttach(id,vertical,double,indicators,objects,params,original,store)
        end,
    }
end

-- Key Indicators: the side of its key each label sits on, the first the default.
local horizontal={{key='above',label='Above'},{key='below',label='Below'},{key='left',label='Left'},
    {key='right',label='Right'}}
local vertical={{key='left',label='Left'},{key='right',label='Right'},{key='above',label='Above'},
    {key='below',label='Below'}}
return {
    bar('SingleUnderbar','Single Underbar',false,false,horizontal),
    bar('DoubleUnderbar','Double Underbar',false,true,horizontal),
    bar('SingleSidebar','Single Sidebar',true,false,vertical),
    bar('DoubleSidebar','Double Sidebar',true,true,vertical),
}
