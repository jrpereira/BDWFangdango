package.path='Fangdango/Scripts/?.lua;ModCoreTemplates/Scripts/?.lua;ModCoreTemplates/Scripts/vendor/?.lua;'..package.path
-- MCT keeps objects as UE4SSLuaEventBridge weak handles; use its test double.
dofile('ModCoreTemplates/tests/support/lifetimes.lua').install()
local definitions=dofile('Fangdango/tests/load_templates.lua')()
local barsById={}
for index=2,#definitions do barsById[definitions[index].menu[1].id]=definitions[index] end
local bar=barsById.SingleUnderbar
local category=dofile('ModCoreTemplates/Scripts/categories/player_quickslots.lua')
local graph=require('mc.selectors').compile(category.objects)
local TemplateTargets=require('mc.template_targets')
local Manager=require('mc.managed_template')
-- UE4SS answers an unknown property with an invalid placeholder, not nil.
local placeholder={IsValid=function() return false end}
placeholder.RootWidget=placeholder
local baseWidget=dofile('Fangdango/tests/support/widget.lua')
-- Keys and labels sit in switcher or overlay slots.
local function panelSlot()
    local slot={Padding={Left=0,Top=0,Right=0,Bottom=0},HorizontalAlignment=0,VerticalAlignment=0}
    function slot:IsValid() return true end
    function slot:GetClass() return {GetName=function() return 'WidgetSwitcherSlot' end} end
    function slot:SetPadding(value) self.Padding=value end
    function slot:SetHorizontalAlignment(value) self.HorizontalAlignment=value end
    function slot:SetVerticalAlignment(value) self.VerticalAlignment=value end
    return slot
end
local function widget(name)
    local w=baseWidget(name,panelSlot,{active=0,WidgetTree=placeholder})
    function w:GetActiveWidgetIndex() return self.active end
    function w:SetActiveWidgetIndex(index) self.active=index end
    function w:SetActiveWidget(child)
        for index,item in ipairs(self.children) do
            if item==child then self.active=index-1; return end
        end
        error('active widget is not a child')
    end
    return w
end

local owner,switcher=widget('Owner'),widget('Switcher')
-- MCT's widget layer forces a layout prepass on panels it measures.
function switcher:ForceLayoutPrepass() end
owner:AddChild(switcher)
local tree={name='WidgetTree'}
function tree:IsValid() return true end
function switcher:GetOuter() return tree end
local hudRoot=widget('HUD Root')
tree.RootWidget=hudRoot
local addHudChild=hudRoot.AddChild
function hudRoot:AddChild(child)
    local slot=addHudChild(self,child)
    function slot:GetClass() return {GetName=function() return 'OverlaySlot' end} end
    return slot
end
local function canvasSlot()
    local slot={LayoutData={Offsets={Left=0,Top=0,Right=0,Bottom=0},
        Anchors={Minimum={X=0,Y=0},Maximum={X=0,Y=0}},Alignment={X=0,Y=0}},
        ZOrder=0,bAutoSize=false}
    function slot:IsValid() return true end
    function slot:GetClass() return {GetName=function() return 'CanvasPanelSlot' end} end
    function slot:SetLayout(value)
        self.LayoutData=value
        self.position={X=value.Offsets.Left,Y=value.Offsets.Top}
    end
    function slot:SetAutoSize(value) self.bAutoSize=value end
    function slot:SetPosition(value)
        self.position=value
        self.LayoutData.Offsets.Left=value.X
        self.LayoutData.Offsets.Top=value.Y
    end
    function slot:SetSize(value)
        self.size=value
        self.LayoutData.Offsets.Right=value.X
        self.LayoutData.Offsets.Bottom=value.Y
    end
    function slot:SetZOrder(value) self.ZOrder=value end
    return slot
end
StaticFindObject=function(path)
    if path=='/Script/UMG.Overlay' or path=='/Script/UMG.CanvasPanel' then
        return {path=path}
    end
    error('unexpected class lookup: '..path)
end
local createdCount=0
StaticConstructObject=function(class,outer)
    assert(outer==tree)
    createdCount=createdCount+1
    local created=widget(class.path..createdCount)
    if class.path=='/Script/UMG.CanvasPanel' then
        created.slotFor=canvasSlot
        function created:ForceLayoutPrepass() end
    end
    return created
end
local objects={switcher=switcher,hud_root=hudRoot,change_prompt=widget('Change prompt'),
    wheels={},panels={},buttons={abilitySlots={},consumableSlots={}},
    labels={abilityLabels={},consumableLabels={}}}
local nativeBoxes={}
for _,kind in ipairs({'ability','consumable'}) do
    local wheel,box,panel=widget(kind),widget(kind..'Box'),widget(kind..'Panel')
    objects[kind=='ability' and 'abilities' or 'consumables']=wheel
    wheel.RenderTransformPivot={X=0.5,Y=0.5}
    function wheel:GetDesiredSize() return {X=200,Y=160} end
    objects.panels[kind..'_panel']=panel
    nativeBoxes[kind]=box
    switcher:AddChild(wheel);wheel:AddChild(box);box:AddChild(panel)
    -- Like the native UserWidget, the wheel reaches its tree only through
    -- WidgetTree.RootWidget, not as panel children.
    wheel.WidgetTree={RootWidget=box}
    function wheel:GetChildrenCount() error('UserWidget is not a panel') end
    wheel.inner=widget(kind..'.Inner');panel:AddChild(wheel.inner)
    wheel.cross=widget(kind..'.cross');wheel.inner:AddChild(wheel.cross)
    if kind=='ability' then
        wheel.Darken=widget(kind..'.Darken');wheel.Glow=widget(kind..'.Glow')
        panel:AddChild(wheel.Darken);panel:AddChild(wheel.Glow)
    end
    box.WidthOverride,box.HeightOverride=321,234
    box.bOverride_WidthOverride,box.bOverride_HeightOverride=false,true
    function box:SetWidthOverride(value) self.WidthOverride=value;self.bOverride_WidthOverride=true end
    function box:SetHeightOverride(value) self.HeightOverride=value;self.bOverride_HeightOverride=true end
    function box:ClearWidthOverride()self.bOverride_WidthOverride=false end
    function box:ClearHeightOverride()self.bOverride_HeightOverride=false end
    for index=1,4 do
        local button=widget(kind..index)
        button.RenderTransformPivot={X=0.5,Y=0.25}
        button.desired={X=100,Y=80}
        function button:GetDesiredSize()return self.desired end
        -- Ability L and B are empty: their ability widget is hidden, and the
        -- empty L has no size. Consumables all hold an item.
        if kind=='ability' then
            local empty=index==1 or index==4
            if index==1 then button.desired={X=0,Y=0} end
            button.AbilityWidget={IsValid=function() return true end,
                IsVisible=function() return not empty end}
        else
            button['Displayed Item Asset']={IsValid=function() return true end}
        end
        panel:AddChild(button)
        objects.buttons[kind..'Slots'][index]=button
    end
    -- The binding labels live in a nested Bindings UserWidget with a Dpad image.
    local bindings,bindingsBox,bindingsPanel=widget(kind..'.Bindings'),
        widget(kind..'.BindingsBox'),widget(kind..'.BindingsPanel')
    panel:AddChild(bindings);bindings:AddChild(bindingsBox);bindingsBox:AddChild(bindingsPanel)
    bindings.WidgetTree={RootWidget=bindingsBox}
    function bindings:GetChildrenCount() error('UserWidget is not a panel') end
    wheel.Dpad=widget(kind..'.Dpad');bindingsPanel:AddChild(wheel.Dpad)
    for index=1,4 do
        local label=widget(kind..'.Label'..index)
        label.RenderTransformPivot={X=0.5,Y=0.5}
        -- An unbound key's label can be empty; it must still move with its key.
        label.desired=(kind=='consumable' and index==4) and {X=0,Y=0} or {X=30,Y=20}
        function label:GetDesiredSize() return self.desired end
        bindingsPanel:AddChild(label)
        objects.labels[kind..'Labels'][index]=label
    end
end
switcher.active=1
assert(bar.loaded==nil,'Bar must not install a click-transition runtime')
local sharedGraph=require('mc.selectors').project(graph,category.sharedObjects)
local sharedCreated={}
for _,name in ipairs(sharedGraph.order) do
    local selector=sharedGraph.byName[name]
    if selector.create then
        sharedCreated[#sharedCreated+1]={name=name,class=selector.class,from=selector.from,
            parent=selector.parent,adopt=selector.adopt,
            adoptLayout=selector.adoptLayout,opacity=selector.opacity,
            layout=selector.layout,prepass=selector.prepass}
    end
end
local sharedTargets={}
local sharedDefinition={attach=function(_,_,original) return original end}
local sharedManager=Manager.new(sharedDefinition,
    TemplateTargets.compile(sharedGraph,category.sharedObjects),sharedGraph.order,sharedCreated)
local function managerFor(template)
    local projected=require('mc.selectors').project(graph,template.objects)
    return Manager.new(template,TemplateTargets.compile(projected,template.objects),projected.order)
end
local managers={}
for id,template in pairs(barsById) do managers[id]=managerFor(template) end
local manager=managers.SingleUnderbar
-- Orientation 7 is an Underbar (bottom/center), 5 a Sidebar (bottom/right);
-- double picks the Double version. Each names its settings after its menu.
-- ModCore Controls has reported abilities (group 1) as focused. Single key
-- indicators default Above (Underbar) and Left (Sidebar).
-- Double bars also merge their key indicators unless merge is 0.
local function params(size,margin,orientation,state,kh,kv,double,position,merge)
    orientation=orientation or 7
    local id=(double and 'Double' or 'Single')..(orientation==5 and 'Sidebar' or 'Underbar')
    local settings={[id..'S']=size or 'standard',[id..'M']=margin or 0,focus=bar.settings.focus}
    settings[id..'K']=(orientation==5 and kv or kh) or (orientation==5 and 'left' or 'above')
    if double then settings[id..'J']=merge or 1 end
    if double or orientation~=5 then
        settings[id..'A']=position or (orientation==5 and 'bottom_right' or 'bottom_center')
    end
    return {id=id,settings=settings,
        screen={width=1920,height=1080,scale=1,center=960,middle=540},
        state=state or {controls={group={from=1,to=1}}}}
end
-- Switching bars selects another template: the active one detaches before the
-- other attaches, as when the user picks it.
local active
local function layout(p)
    local wanted=managers[p.id]
    if active==wanted then return wanted:update(switcher,objects,p) end
    if active then assert(active:detach(switcher)) end
    active=wanted
    return wanted:attach(switcher,objects,p)
end
local function near(a,b) assert(math.abs(a-b)<0.00001,tostring(a)..' ~= '..tostring(b)) end
-- Focus tints each key of the other wheel and fades its shown label.
-- lit[kind][index] marks a key with a Global key.
local dim=bar.settings.focus.tint.A
local function focusIs(group,lit)
    for w,kind in ipairs({'ability','consumable'}) do
        for index=1,4 do
            local on=w==group or (lit and lit[kind] and lit[kind][index])
            near(objects.buttons[kind..'Slots'][index].ColorAndOpacity.A,on and 1 or dim)
            local label=objects.labels[kind..'Labels'][index]
            if label.opacity>0 then near(label.opacity,on and 1 or dim) end
        end
    end
end
local function bounds(button)
    local size,pivot,transform=button.desired,button.RenderTransformPivot,button.RenderTransform
    local scale=transform.Scale.X
    return transform.Translation.X+pivot.X*size.X*(1-scale)+math.min(0,scale*size.X),
        transform.Translation.Y+pivot.Y*size.Y*(1-scale)+math.min(0,scale*size.Y)
end
assert(sharedManager:attach(switcher,sharedTargets,params(),objects))
objects.actions=sharedTargets.actions
objects.wheels.abilities=objects.abilities
objects.wheels.consumables=objects.consumables
local abilityWheel,consumableWheel=objects.abilities,objects.consumables
local actions=assert(sharedTargets.actions)
assert(abilityWheel:GetParent()==actions and consumableWheel:GetParent()==actions,
    'MCT must place both wheels directly in its canvas without host buttons')
assert(layout(params()))
assert(switcher.active==1,'Bar must not change the native switcher index')
assert(objects.change_prompt.opacity==0,'Bar must hide the native swap prompt')
assert(switcher:GetChildrenCount()==0,'MCT leaves nothing in the native switcher')
assert(actions:GetParent()==hudRoot and actions:GetChildrenCount()==2)
assert(actions:GetChildAt(0)==abilityWheel and actions:GetChildAt(1)==consumableWheel)
-- Both wheels share one box at the chosen edge, as in Wheels' Overlap placement.
local function wheelsAt(x,y)
    for _,wheel in ipairs({abilityWheel,consumableWheel}) do
        near(wheel.Slot.position.X,x);near(wheel.Slot.position.Y,y)
    end
end
-- The shared box sits flush with the bottom edge; at Margin 0% the reference
-- line is 160 px above it, at 1080-160=920, the box's top.
wheelsAt(860,920)
-- A widget's center offset from its overlay's center; keys and labels are
-- center-aligned.
local function centerOf(widget)
    assert(widget.Slot.HorizontalAlignment==2 and widget.Slot.VerticalAlignment==2)
    local x,y=bounds(widget)
    local factor=math.abs(widget.RenderTransform.Scale.X)
    return x+(factor-1)*widget.desired.X/2,y+(factor-1)*widget.desired.Y/2
end
local function offset(kind,index)
    local button=objects.buttons[kind..'Slots'][index]
    assert(button:GetParent()==objects.panels[kind..'_panel'],'Bar must not reparent keys')
    return centerOf(button)
end
-- Shown keys are one pitch (key size * 1.075) apart in bar order L,T,R,B.
-- Empty slots take no place. Abilities end half a pitch before the center,
-- consumables start half a pitch after it. Horizontal runs right, vertical
-- runs down. Each binding label sits centered on its key's top edge; an empty
-- key's label is hidden. Ability L and B are empty, so only T and R show.
-- Labels are centered on one edge of their key: by default the left or right
-- edge in a vertical bar and the top or bottom edge in a horizontal one (side
-- -1 or 1), or the other pair when across. Labels beside their keys keep gap
-- px clear of them, 4 unless given.
local along={ability={nil,-1.5,-0.5,nil},consumable={0.5,1.5,2.5,3.5}}
local function lined(W,H,vertical,dx,dy,side,across,gap)
    side=side or -1
    dx=dx or 0
    gap=gap or 4
    for _,kind in ipairs({'ability','consumable'}) do
        for index=1,4 do
            local label=objects.labels[kind..'Labels'][index]
            local a=along[kind][index]
            if a then
                local x,y=offset(kind,index)
                local ex,ey=dx+a*W*1.075,dy
                if vertical then ex,ey=dx,dy+a*H*1.075 end
                near(x,ex);near(y,ey)
                local lx,ly=centerOf(label)
                if (vertical==true)~=(across==true) then
                    near(lx,ex+side*(W/2+gap));near(ly,ey)
                else
                    near(lx,ex);near(ly,ey+side*H/2)
                end
                assert(label.RenderTransform.Scale.X>=0,'labels must not mirror')
                assert(label.opacity>0,kind..' shown label must stay visible')
            else
                assert(label.opacity==0,kind..' empty slot label must be hidden')
            end
        end
    end
end
-- With labels above, their top edge hangs from the line: 920-1000=-80 from
-- the box's, less the labels' offset of -40-20/2=-50. The line sits 16 px
-- lower: -14.
lined(100,80,false,nil,-30+16)
for _,kind in ipairs({'ability','consumable'}) do
    local wheel=objects[kind=='ability' and 'abilities' or 'consumables']
    assert(wheel:GetParent()==actions)
    assert(wheel.cross.opacity==0 and wheel.Dpad.opacity==0)
end
assert(objects.abilities.Darken.opacity==0 and objects.abilities.Glow.opacity==0)
-- Attach applies the initial focus: abilities stay opaque, consumables dim.
focusIs(1)
assert(objects.labels.abilityLabels[1].opacity==0,'focus must keep an empty key\'s label hidden')
assert(switcher.active==1,'Bar update must not change the native switcher index')
local focusParams=params()
bar.events['controls.group.focus'](focusParams,{name='controls.group.focus',group={from=2,to=1}},objects)
focusIs(1)
-- A key with a ModCore Controls Global key fires whatever the focus, so it keeps
-- the native look.
local global={controls={group={from=2,to=1},
    global={[1]={false,false,false,false},[2]={true,false,false,true}}}}
bar.events['controls.group.focus'](params('standard',0,7,global),
    {name='controls.group.focus',group={from=2,to=1}},objects)
focusIs(1,{consumable={true,false,false,true}})
-- A rebuild applies the current focus from the state.
assert(layout(params('standard',0,7,{controls={group={from=1,to=2}}})))
focusIs(2)
-- Margin steps so -100% leaves 8 px below the bar: at 0% the keys' bottom is
-- at 1000-14+40=1026, so each percent moves (1080-1026-8)/100=0.46 px. 50%
-- raises the keys 23 px; the box stays flush.
assert(layout(params('standard',50)))
focusIs(1)
wheelsAt(860,920)
lined(100,80,false,nil,-14-23)
-- -50% lowers them as far, and -100% puts their bottom at 1080-8=1072.
assert(layout(params('standard',-50)))
lined(100,80,false,nil,-14+23)
assert(layout(params('standard',-100)))
lined(100,80,false,nil,1072-40-1000)
-- Horizontal labels can sit below their keys instead; the keys then center on
-- the line, which sits 41.6 px lower.
assert(layout(params('standard',0,7,nil,'below')))
lined(100,80,false,nil,-80+41.6,1)
-- Position Bottom/Right puts the box in the corner, at the keys' height
-- as at Bottom/Center. The full row's right edge, 3.5*107.5+50=426.25 right of
-- its center, keeps as far from the right edge as its bottom from the bottom
-- (1080-1026=54): 1920-54-1820-426.25=-380.25.
assert(layout(params('standard',0,7,nil,'above',nil,nil,'bottom_right')))
wheelsAt(1720,920)
lined(100,80,false,-380.25,-14)
-- Horizontal Key Indicators also offer Left and Right; the line then
-- sits 48 px lower.
assert(layout(params('standard',0,7,nil,'left')))
lined(100,80,false,nil,-80+48,-1,true)
assert(layout(params('standard',0,7,nil,'right')))
lined(100,80,false,nil,-80+48,1,true)
-- Vertical: one column in the bottom-right corner, its box flush with it:
-- 1920-200=1720. The X reference line is also 160 px in, at 1760. With labels
-- on the left, their right edge meets it: 1760-1820=-60, less the labels'
-- offset of -50+30/2=-35, puts the keys at -25. The bottom label of a full
-- consumable run centers on the line: -80-3.5*86=-381. Labels on the left
-- then take 0% from where Margin -30% across and -40% along would put them:
-- the keys' right edge (1845) steps (1920-1845-8)/100=0.67 px and their
-- bottom (1000-381+3.5*86+40=960) steps (1080-960-8)/100=1.12 px per
-- percent, so the keys sit at -25+20.1=-4.9 and -381+44.8=-336.2. Each axis
-- keeps its own step from there. Abilities sit above the shared center,
-- consumables below, the nearest of each half a pitch (43) from it.
assert(layout(params('standard',0,5)))
wheelsAt(1720,920)
lined(100,80,true,-4.9,-336.2)
local _,abilityNearest=offset('ability',3)
local _,consumableNearest=offset('consumable',1)
near(abilityNearest,-336.2-43);near(consumableNearest,-336.2+43)
-- At -100% its right edge and bottom sit 8 px from the corner.
assert(layout(params('standard',-100,5)))
lined(100,80,true,1912-50-1820,1072-341-1000)
-- With labels on the right, the keys center on the line instead: -60.
assert(layout(params('standard',0,5,nil,nil,'right')))
lined(100,80,true,-60,-381,1)
-- The Single Sidebar has no Position; a saved one is ignored.
local saved=params('standard',0,5)
saved.settings.SingleSidebarA='middle_right'
assert(layout(saved))
wheelsAt(1720,920)
lined(100,80,true,-4.9,-336.2)
-- Vertical Key Indicators also offer Above and Below; the keys center
-- on the X line, and the bottom label, half a key off its key, stays on the Y
-- line.
assert(layout(params('standard',0,5,nil,nil,'above')))
lined(100,80,true,-60,-341,-1,true)
assert(layout(params('standard',0,5,nil,nil,'below')))
lined(100,80,true,-60,-421,1,true)
-- Double bars give each wheel its own full bar centered on the center, every
-- slot in its own place even when empty, so a key and the one beside it in the
-- other row share a binding: ability T and R sit at -0.5 and 0.5 pitches,
-- consumables at all four. Consumables are one row (or column) further from
-- the edge, by the key plus two spacings: keys overlap each label by half of
-- it. Merged, both rows' labels sit halfway between them; a pair names one
-- grouped key, so only the focused wheel's label shows, and a label without a
-- pair shows dimmed with its wheel. Unmerged (side given), every shown label
-- sits on that side of its own key, as in a Single bar, and shows, dimmed
-- unless its wheel has focus or lit[kind][index] marks a Global key. Keys and
-- labels take the size scale k, 1 unless given; the 4 px gap beside a key
-- does not.
local placed={ability={nil,-0.5,0.5,nil},consumable={-1.5,-0.5,0.5,1.5}}
local sideOffset={above={0,-40},below={0,40},left={-50,0},right={50,0}}
local function doubled(vertical,dx,dy,cross,focused,side,lit,k)
    focused=focused or 1
    k=k or 1
    for w,kind in ipairs({'ability','consumable'}) do
        for index=1,4 do
            local toward=kind=='ability' and -cross/2 or cross/2
            local paired=placed.ability[index] and placed.consumable[index]
            local label=objects.labels[kind..'Labels'][index]
            local a=placed[kind][index]
            if a then
                local x,y=offset(kind,index)
                local ex,ey=a*100*k*1.075,0
                if vertical then ex,ey=0,a*80*k*1.075 end
                ex,ey=ex+dx,ey+dy
                if kind=='consumable' then
                    if vertical then ex=ex-cross else ey=ey-cross end
                end
                near(x,ex);near(y,ey)
                local lx,ly=centerOf(label)
                local on=w==focused or (lit and lit[kind] and lit[kind][index])
                if side then
                    local ox,oy=sideOffset[side][1]*k,sideOffset[side][2]*k
                    if ox~=0 then ox=ox+(ox<0 and -4 or 4) end
                    near(lx,ex+ox);near(ly,ey+oy)
                    near(label.opacity,on and 1 or dim)
                else
                    if vertical then near(lx,ex+toward);near(ly,ey) else near(lx,ex);near(ly,ey+toward) end
                    if paired then
                        near(label.opacity,w==focused and 1 or 0)
                    else
                        near(label.opacity,on and 1 or dim)
                    end
                end
            else
                assert(label.opacity==0,kind..' empty slot label must be hidden')
            end
        end
    end
    -- Merged labels of the same slot meet.
    if not side then
        local ax,ay=centerOf(objects.labels.abilityLabels[2])
        local cx,cy=centerOf(objects.labels.consumableLabels[2])
        near(ax,cx);near(ay,cy)
    end
end
-- Double Underbar: labels are 20 high, so consumables sit 80+2*6=92 above, and
-- the labels between the rows hang from the line by their top edge:
-- -80+92/2+20/2=-24.
local doubleUnder=function(state,kh,merge,position,margin)
    return params('standard',margin or 0,7,state,kh,nil,true,position,merge)
end
assert(layout(doubleUnder()))
wheelsAt(860,920)
doubled(false,0,-24,92)
assert(objects.change_prompt.opacity==0,'bars always hide the swap prompt')
-- Focus dims the other wheel's keys, as in every bar.
focusIs(1)
barsById.DoubleUnderbar.events['controls.group.focus'](doubleUnder(),
    {name='controls.group.focus',group={from=1,to=2}},objects)
focusIs(2)
-- Focus swaps which label of a shared pair shows.
doubled(false,0,-24,92,2)
-- A Global key on any slot makes merging impossible: every label of both rows
-- moves to its Key Indicators side, Above by default, and shows, the unfocused
-- wheel's dimmed unless Global. The keys stay put.
local noGlobal={[1]={false,false,false,false},[2]={false,false,false,false}}
local abilityLGlobal={[1]={true,false,false,false},[2]={false,false,false,false}}
local doubleGlobal={controls={group={from=2,to=1},global=abilityLGlobal}}
assert(layout(doubleUnder(doubleGlobal)))
doubled(false,0,-24,96,1,'above')
-- Ability L is empty: a Global key on a slot that shows nothing un-merges too.
-- A Global key on consumable T keeps its label lit whatever the focus.
local consumableTGlobal={[1]={false,false,false,false},[2]={false,true,false,false}}
barsById.DoubleUnderbar.events['controls.slots.global'](doubleUnder(doubleGlobal),
    {name='controls.slots.global',global=consumableTGlobal},objects)
doubled(false,0,-24,96,1,'above',{consumable={false,true,false,false}})
-- The focus event keeps the reported Global keys.
local consumableTState={controls={group={from=1,to=2},global=consumableTGlobal}}
barsById.DoubleUnderbar.events['controls.group.focus'](doubleUnder(consumableTState),
    {name='controls.group.focus',group={from=1,to=2}},objects)
doubled(false,0,-24,96,2,'above',{consumable={false,true,false,false}})
-- Clearing every Global key merges the labels again.
barsById.DoubleUnderbar.events['controls.slots.global'](doubleUnder(doubleGlobal),
    {name='controls.slots.global',global=noGlobal},objects)
doubled(false,0,-24,92,1)
barsById.DoubleUnderbar.events['controls.slots.global'](doubleUnder(doubleGlobal),
    {name='controls.slots.global',global={}},objects)
doubled(false,0,-24,92,1)
-- Merge Off never merges, with or without Global keys.
assert(layout(doubleUnder(nil,nil,0)))
doubled(false,0,-24,96,1,'above')
barsById.DoubleUnderbar.events['controls.slots.global'](doubleUnder(nil,nil,0),
    {name='controls.slots.global',global=noGlobal},objects)
doubled(false,0,-24,96,1,'above')
-- Each Key Indicators side places the unmerged labels; labels beside their
-- keys keep 4 px clear of them. Above or Below, the labels between the rows
-- reach 20/2=10 past their key, so the gap widens to 80+10+6=96 and the
-- consumables move 4 px further from the edge; Left or Right, the labels stay
-- level with their keys and the gap stays 92. The abilities, nearest the edge,
-- keep their place.
local underGap={above=96,below=96,left=92,right=92}
for _,side in ipairs({'above','below','left','right'}) do
    assert(layout(doubleUnder(nil,side,0)))
    doubled(false,0,-24,underGap[side],1,side)
    -- Merged, the side does not matter.
    assert(layout(doubleUnder(nil,side)))
    doubled(false,0,-24,92,1)
end
-- Labels below reach past the keys: at -100% their bottom (976+40+10=1026 at
-- 0%) sits 8 px from the screen's, 46 px lower, merged or not.
assert(layout(doubleUnder(nil,'below',0,nil,-100)))
doubled(false,0,-24+46,96,1,'below')
assert(layout(doubleUnder(nil,'below',1,nil,-100)))
doubled(false,0,-24+46,92,1)
-- Double Sidebar: labels are 30 wide, so consumables sit 100+2*7.5=115 further
-- left; the labels between the columns center on the X line (-60+115/2=-2.5),
-- and the bottom one on the Y line (-80-1.5*86=-209).
assert(layout(params('standard',0,5,nil,nil,nil,true)))
wheelsAt(1720,920)
doubled(true,-2.5,-209,115)
-- A Global key un-merges the columns' labels to the Left by default, and
-- clearing it merges them again.
barsById.DoubleSidebar.events['controls.slots.global'](params('standard',0,5,nil,nil,nil,true),
    {name='controls.slots.global',global=consumableTGlobal},objects)
doubled(true,-2.5,-209,126.5,1,'left',{consumable={false,true,false,false}})
barsById.DoubleSidebar.events['controls.slots.global'](params('standard',0,5,nil,nil,nil,true),
    {name='controls.slots.global',global=noGlobal},objects)
doubled(true,-2.5,-209,115)
-- Left or Right, the labels between the columns reach 4+30/2=19 past their
-- key, so the gap widens to 100+19+7.5=126.5; Above or Below keeps 115.
local sideGap={left=126.5,right=126.5,above=115,below=115}
for _,side in ipairs({'left','right','above','below'}) do
    assert(layout(params('standard',0,5,nil,nil,side,true,nil,0)))
    doubled(true,-2.5,-209,sideGap[side],1,side)
end
assert(layout(params('standard',0,5,nil,nil,nil,true)))
-- At -100% the column's outer edges sit 8 px from the corner: its right edge
-- moves from 1820-2.5+50=1867.5 to 1912 and its bottom (1.5*86+40 below the
-- ability wheel's center) from 960 to 1072.
assert(layout(params('standard',-100,5,nil,nil,nil,true)))
doubled(true,-2.5+44.5,-209+112,115)
-- Unmerged at -100%, the abilities keep the same place and only the far
-- column moves. With labels on the Right, their right edge (54+15 right of
-- the keys) is the outer edge, merged or not: 1820-2.5+69=1886.5 moves to 1912.
assert(layout(params('standard',-100,5,nil,nil,'left',true,nil,0)))
doubled(true,-2.5+44.5,-209+112,126.5,1,'left')
assert(layout(params('standard',-100,5,nil,nil,'right',true,nil,0)))
doubled(true,-2.5+25.5,-209+112,126.5,1,'right')
assert(layout(params('standard',-100,5,nil,nil,'right',true)))
doubled(true,-2.5+25.5,-209+112,115)

-- Key centers of both rows, to compare layouts.
local function keyCenters()
    local all={}
    for _,kind in ipairs({'ability','consumable'}) do
        for index=1,4 do
            if placed[kind][index] then all[kind..index]={offset(kind,index)} end
        end
    end
    return all
end
-- A widget's drawn box: its center and scaled half size.
local function boxOf(widget)
    local x,y=centerOf(widget)
    local s=math.abs(widget.RenderTransform.Scale.X)
    return x-widget.desired.X*s/2,y-widget.desired.Y*s/2,x+widget.desired.X*s/2,y+widget.desired.Y*s/2
end
local function overlaps(a,b)
    local al,at,ar,ab=boxOf(a)
    local bl,bt,br,bb=boxOf(b)
    return al<br and bl<ar and at<bb and bt<ab
end
-- No shown label overlaps a key of the other row.
local function clear()
    for w,kind in ipairs({'ability','consumable'}) do
        local other=w==1 and 'consumable' or 'ability'
        for index=1,4 do
            local label=objects.labels[kind..'Labels'][index]
            if label.opacity>0 and label.desired.X>0 then
                for o=1,4 do
                    if placed[other][o] then
                        assert(not overlaps(label,objects.buttons[other..'Slots'][o]),
                            kind..' label '..index..' overlaps '..other..' key '..o)
                    end
                end
            end
        end
    end
end
-- Assigning a Global key moves the far row away from the edge when the labels
-- sit across the bar, and clearing it moves it back exactly; the near row stays.
-- Along the bar, nothing moves. The focus event carries the Global keys too.
local function globalMoves(id,make,side,wide,narrow)
    local events=barsById[id].events
    assert(layout(make(nil,side)))
    local merged=keyCenters()
    events['controls.slots.global'](make(nil,side),{name='controls.slots.global',global=consumableTGlobal},objects)
    clear()
    local unmerged=keyCenters()
    local vertical=id=='DoubleSidebar'
    for name,at in pairs(merged) do
        local now=unmerged[name]
        if name:find('^ability') then
            near(now[1],at[1]);near(now[2],at[2])
        elseif vertical then
            near(now[1],at[1]-(wide-narrow));near(now[2],at[2])
        else
            near(now[1],at[1]);near(now[2],at[2]-(wide-narrow))
        end
    end
    events['controls.slots.global'](make(nil,side),{name='controls.slots.global',global=noGlobal},objects)
    for name,at in pairs(keyCenters()) do near(at[1],merged[name][1]);near(at[2],merged[name][2]) end
    -- A focus event reporting Global keys in its state un-merges as well.
    events['controls.group.focus'](make({controls={group={from=2,to=1},global=consumableTGlobal}},side),
        {name='controls.group.focus',group={from=2,to=1}},objects)
    for name,at in pairs(keyCenters()) do near(at[1],unmerged[name][1]);near(at[2],unmerged[name][2]) end
    events['controls.group.focus'](make({controls={group={from=2,to=1},global=noGlobal}},side),
        {name='controls.group.focus',group={from=2,to=1}},objects)
    for name,at in pairs(keyCenters()) do near(at[1],merged[name][1]);near(at[2],merged[name][2]) end
end
local doubleSide=function(state,kv,merge,position,margin)
    return params('standard',margin or 0,5,state,nil,kv,true,position,merge)
end
for side,wide in pairs(underGap) do
    globalMoves('DoubleUnderbar',doubleUnder,side,wide,92)
    -- Merge Off lays out the same clear rows.
    assert(layout(doubleUnder(nil,side,0)))
    clear()
end
for side,wide in pairs(sideGap) do
    globalMoves('DoubleSidebar',doubleSide,side,wide,115)
    -- Merge Off lays out the same clear rows.
    assert(layout(doubleSide(nil,side,0)))
    clear()
end
-- Larger labels widen the gap with their reach: 40 high, the Underbar's
-- reach 80+20+6=106 apart; 60 wide, the Sidebar's 100+4+30+7.5=141.5. The
-- merged gaps leave out the labels' reach and stay 92 and 115.
for _,kind in ipairs({'ability','consumable'}) do
    for _,label in ipairs(objects.labels[kind..'Labels']) do
        if label.desired.X>0 then label.desired={X=60,Y=40} end
    end
end
for side,wide in pairs({above=106,below=106,left=92,right=92}) do
    globalMoves('DoubleUnderbar',doubleUnder,side,wide,92)
    assert(layout(doubleUnder(nil,side,0)))
    clear()
end
for side,wide in pairs({left=141.5,right=141.5,above=115,below=115}) do
    globalMoves('DoubleSidebar',doubleSide,side,wide,115)
    assert(layout(doubleSide(nil,side,0)))
    clear()
end
for _,kind in ipairs({'ability','consumable'}) do
    for _,label in ipairs(objects.labels[kind..'Labels']) do
        if label.desired.X>0 then label.desired={X=30,Y=20} end
    end
end
-- Size scales a Double bar's keys and labels, and its gaps with them. At
-- Larger (1.2) the Underbar's rows sit 1.2*92=110.4 apart merged and
-- 1.2*96=115.2 unmerged Above, and its line moves to -80+110.4/2+24/2=-12.8.
-- The Sidebar's columns sit 1.2*115=138 apart merged; unmerged Left, the 4 px
-- gap stays unscaled: 120+4+18+9=151. Its lines move to -60+138/2=9 across
-- and -80-1.5*1.2*86=-234.8 along.
assert(layout(params('larger',0,7,nil,nil,nil,true)))
doubled(false,0,-12.8,110.4,1,nil,nil,1.2)
assert(layout(params('larger',0,7,nil,'above',nil,true,nil,0)))
doubled(false,0,-12.8,115.2,1,'above',nil,1.2)
clear()
assert(layout(params('larger',0,5,nil,nil,nil,true)))
doubled(true,9,-234.8,138,1,nil,nil,1.2)
assert(layout(params('larger',0,5,nil,nil,'left',true,nil,0)))
doubled(true,9,-234.8,151,1,'left',nil,1.2)
clear()
-- Attaching with a Global key already assigned starts in the wide gap.
assert(layout(doubleUnder({controls={group={from=2,to=1},global=consumableTGlobal}})))
doubled(false,0,-24,96,1,'above',{consumable={false,true,false,false}})
-- Merge Off keeps the wide gap whatever the Global keys.
assert(layout(doubleSide(nil,'left',0)))
barsById.DoubleSidebar.events['controls.slots.global'](doubleSide(nil,'left',0),
    {name='controls.slots.global',global=consumableTGlobal},objects)
doubled(true,-2.5,-209,126.5,1,'left',{consumable={false,true,false,false}})
barsById.DoubleSidebar.events['controls.slots.global'](doubleSide(nil,'left',0),
    {name='controls.slots.global',global=noGlobal},objects)
doubled(true,-2.5,-209,126.5,1,'left')
-- Position Middle/Right (5) moves the box to the right edge's middle,
-- (1080-160)/2=460, and centers the full column on it.
assert(layout(params('standard',0,5,nil,nil,nil,true,'middle_right')))
wheelsAt(1720,460)
doubled(true,-2.5,0,115)
-- Double Underbar at Bottom/Right: the box sits in the corner, and the
-- full row's right edge (1.5*107.5+50 right of its center) keeps as far from
-- the right edge as its bottom (1000-24+40=1016) from the bottom, 64 px:
-- 1920-64-1820-211.25=-175.25.
assert(layout(params('standard',0,7,nil,nil,nil,true,'bottom_right')))
wheelsAt(1720,920)
doubled(false,-175.25,-24,92)
-- An unknown saved Position falls back to the bar's default edge.
assert(layout(params('standard',0,7,nil,nil,nil,true,'middle_right')))
wheelsAt(860,920)
doubled(false,0,-24,92)
-- Choices are saved as keys: a numeric one, as saved before, lays out as the defaults.
local numeric=params()
numeric.settings.SingleUnderbarA,numeric.settings.SingleUnderbarK,numeric.settings.SingleUnderbarS=6,1,120
assert(layout(numeric))
wheelsAt(860,920)
lined(100,80,false,nil,-14)
-- Size scales each shown key in place, and the pitch with it.
assert(layout(params('smaller')))
lined(80,64,false,nil,-80+32+8+16)
for index,button in ipairs(objects.buttons.abilitySlots) do
    near(button.RenderTransform.Scale.X,along.ability[index] and 0.8 or 1)
end
assert(layout(params('larger')))
lined(120,96,false,nil,-80+48+12+16)
-- The reference line's distances are 1080p pixels scaled to the screen: on a
-- 3840x2160 screen they double. The wheels' box sits flush at 2160-160=2000;
-- the line, 16 px lower doubled, is at 2160-288=1872, 128 above the box's top,
-- less the labels' offset of -30.
local big=params()
big.screen={width=3840,height=2160,scale=1,center=1920,middle=1080}
assert(layout(big))
lined(100,80,false,nil,-128-30)
-- The key-to-label gap scales with them: labels Left or Right keep 8 px clear
-- of their keys. The line, 48 px lower doubled, is at 2160-224=1936, 144
-- above the box's center at 2080, and the keys center on it.
for side,sign in pairs({left=-1,right=1}) do
    local beside=params('standard',0,7,nil,side)
    beside.screen=big.screen
    assert(layout(beside))
    lined(100,80,false,nil,-144,sign,true,8)
end
-- Both wheels share the box's left edge; a wider consumable wheel still
-- leaves the Bottom/Center row centered on the box: the ability wheel's
-- center sits 50 px left of the box's.
local nativeSize=objects.consumables.GetDesiredSize
function objects.consumables:GetDesiredSize() return {X=300,Y=160} end
assert(layout(params()))
near(offset('ability',2),50-1.5*107.5)
near(offset('consumable',1),0.5*107.5)
objects.consumables.GetDesiredSize=nativeSize
assert(layout(params()))
local lastKey=objects.buttons.consumableSlots[4]
local setScale=lastKey.SetRenderScale
local fail=true
function lastKey:SetRenderScale(value)
    if fail then fail=false;error('injected Bar key failure') end
    return setScale(self,value)
end
assert(not layout(params('large')))
lastKey.SetRenderScale=setScale
assert(active==manager and manager:detach(switcher))
assert(objects.change_prompt.opacity==1,'detach must restore the native swap prompt')
for _,kind in ipairs({'ability','consumable'}) do
    for index=1,4 do
        near(objects.buttons[kind..'Slots'][index].ColorAndOpacity.A,1)
        assert(objects.labels[kind..'Labels'][index].opacity==1,'detach must restore label opacity')
    end
end
assert(switcher:GetChildrenCount()==0)
assert(actions:GetParent()==hudRoot and actions:GetChildrenCount()==2)
assert(objects.abilities.cross.opacity==1 and objects.consumables.cross.opacity==1)
assert(objects.abilities.Darken.opacity==1 and objects.abilities.Glow.opacity==1)
assert(objects.abilities.Dpad.opacity==1 and objects.consumables.Dpad.opacity==1)
for _,kind in ipairs({'ability','consumable'}) do
    for _,label in ipairs(objects.labels[kind..'Labels']) do
        assert(label.Slot.HorizontalAlignment==0 and label.Slot.VerticalAlignment==0)
        near(label.RenderTransform.Translation.X,0);near(label.RenderTransform.Scale.X,1)
    end
end
for _,kind in ipairs({'ability','consumable'}) do
    local box=nativeBoxes[kind]
    assert(box.WidthOverride==321 and not box.bOverride_WidthOverride)
    assert(box.HeightOverride==234 and box.bOverride_HeightOverride)
    for index,button in ipairs(objects.buttons[kind..'Slots'])do
        assert(objects.panels[kind..'_panel']:GetChildAt(index+(kind=='ability' and 2 or 0))==button)
        assert(button.Slot.HorizontalAlignment==0 and button.Slot.VerticalAlignment==0)
        near(button.RenderTransform.Translation.X,0);near(button.RenderTransform.Scale.X,1)
    end
end
-- A shown key without a size must not partially move either group, and waits
-- as not ready, which MCT retries without reporting an error.
objects.buttons.abilitySlots[2].desired.X=0
local attached,why=manager:attach(switcher,objects,params())
assert(not attached and tostring(why):match('^not_ready:'),tostring(why))
assert(switcher:GetChildrenCount()==0)
assert(sharedManager:detach(switcher))
assert(switcher:GetChildAt(0)==objects.abilities and switcher:GetChildAt(1)==objects.consumables)
assert(actions:GetParent()==nil and actions:GetChildrenCount()==0)
print('PASS Bar: shared wheel canvas, layout, rollback and restoration')
