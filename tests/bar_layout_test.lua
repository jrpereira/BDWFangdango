package.path='Fangdango/Scripts/?.lua;ModCoreTemplates/Scripts/?.lua;'..package.path
-- MCT keeps objects as UE4SSLuaEventBridge weak handles; use its test double.
dofile('ModCoreTemplates/tests/support/lifetimes.lua').install()
local definitions=dofile('Fangdango/tests/load_templates.lua')()
local barsById={}
for index=2,#definitions do barsById[definitions[index].menu[1].id]=definitions[index] end
local bar=barsById.SingleUnderbar
local category=dofile('ModCoreTemplates/Scripts/categories/player_quickslots.lua')
local graph=require('mc.selectors').compile(category.objects)
local State=require('mc.target_state')
local Manager=require('mc.managed_template')
-- UE4SS answers an unknown property with an invalid placeholder, not nil.
local placeholder={IsValid=function() return false end}
placeholder.RootWidget=placeholder
local function widget(name)
    local w = {
        name=name, children={}, RenderTransform={Translation={X=0,Y=0},Scale={X=1,Y=1}},
        opacity=1, active=0, WidgetTree=placeholder,
    }
    function w:IsValid() return self.invalid ~= true end
    function w:GetFullName() return self.name end
    function w:GetAddress() return self.name..'-address' end
    function w:GetParent() return self.parent end
    function w:GetChildrenCount() return #self.children end
    function w:GetChildAt(index) return self.children[index+1] end
    function w:AddChild(child)
        assert(child.parent==nil)
        self.children[#self.children+1]=child
        self.maxChildren=math.max(self.maxChildren or 0,#self.children)
        child.parent=self
        child.Slot={Padding={Left=0,Top=0,Right=0,Bottom=0},HorizontalAlignment=0,VerticalAlignment=0}
        function child.Slot:IsValid() return true end
        function child.Slot:GetClass() return {GetName=function() return 'WidgetSwitcherSlot' end} end
        function child.Slot:SetPadding(value) self.Padding=value end
        function child.Slot:SetHorizontalAlignment(value) self.HorizontalAlignment=value end
        function child.Slot:SetVerticalAlignment(value) self.VerticalAlignment=value end
        return child.Slot
    end
    function w:RemoveChild(child)
        for index,item in ipairs(self.children) do
            if item==child then
                table.remove(self.children,index)
                child.parent=nil
                return true
            end
        end
        return false
    end
    function w:GetActiveWidgetIndex() return self.active end
    function w:SetActiveWidgetIndex(index) self.active=index end
    function w:SetActiveWidget(child)
        for index,item in ipairs(self.children) do
            if item==child then self.active=index-1; return end
        end
        error('active widget is not a child')
    end
    function w:SetRenderTranslation(value) self.RenderTransform.Translation=value end
    function w:SetRenderScale(value) self.RenderTransform.Scale=value end
    function w:GetRenderOpacity() return self.opacity end
    function w:SetRenderOpacity(value) self.opacity=value end
    return w
end

local owner,switcher=widget('Owner'),widget('Switcher')
local layoutPasses=0
function switcher:ForceLayoutPrepass() layoutPasses=layoutPasses+1 end
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
local function canvasAddChild(self,child)
    assert(child.parent==nil)
    self.children[#self.children+1]=child
    child.parent=self
    child.Slot={LayoutData={Offsets={Left=0,Top=0,Right=0,Bottom=0},
        Anchors={Minimum={X=0,Y=0},Maximum={X=0,Y=0}},Alignment={X=0,Y=0}},
        ZOrder=0,bAutoSize=false}
    function child.Slot:IsValid() return true end
    function child.Slot:GetClass() return {GetName=function() return 'CanvasPanelSlot' end} end
    function child.Slot:SetLayout(value)
        self.LayoutData=value
        self.position={X=value.Offsets.Left,Y=value.Offsets.Top}
    end
    function child.Slot:SetAutoSize(value) self.bAutoSize=value end
    function child.Slot:SetPosition(value)
        self.position=value
        self.LayoutData.Offsets.Left=value.X
        self.LayoutData.Offsets.Top=value.Y
    end
    function child.Slot:SetSize(value)
        self.size=value
        self.LayoutData.Offsets.Right=value.X
        self.LayoutData.Offsets.Bottom=value.Y
    end
    function child.Slot:SetZOrder(value) self.ZOrder=value end
    return child.Slot
end
StaticFindObject=function(path)
    if path=='/Script/UMG.Overlay' or path=='/Script/UMG.CanvasPanel' then
        return {path=path}
    end
    error('unexpected class lookup: '..path)
end
FName=function(value) return value end
local createdCount=0
StaticConstructObject=function(class,outer)
    assert(outer==tree)
    createdCount=createdCount+1
    local created=widget(class.path..createdCount)
    function created:SetText(value) self.text=value end
    function created:SetWidthOverride(value) self.WidthOverride=value end
    function created:SetHeightOverride(value) self.HeightOverride=value end
    function created:SetBrushColor(value) self.BrushColor=value end
    if class.path=='/Script/UMG.CanvasPanel' then
        created.AddChild=canvasAddChild
        function created:ForceLayoutPrepass() layoutPasses=layoutPasses+1 end
    end
    return created
end
local objects={switcher=switcher,hud_root=hudRoot,change_prompt=widget('Change prompt'),
    wheels={},panels={},boxes={},buttons={abilitySlots={},consumableSlots={}},
    labels={abilityLabels={},consumableLabels={}},decorations={ability={},consumable={}}}
local nativeBoxes={}
for _,kind in ipairs({'ability','consumable'}) do
    local wheel,box,panel=widget(kind),widget(kind..'Box'),widget(kind..'Panel')
    objects[kind=='ability' and 'abilities' or 'consumables']=wheel
    wheel.RenderTransformPivot={X=0.5,Y=0.5}
    function wheel:GetDesiredSize() return {X=200,Y=160} end
    objects.panels[kind..'_panel']=panel
    nativeBoxes[kind]=box
    objects.boxes[kind..'_box']=box
    switcher:AddChild(wheel);wheel:AddChild(box);box:AddChild(panel)
    -- Like the native UserWidget, the wheel reaches its tree only through
    -- WidgetTree.RootWidget, not as panel children.
    wheel.WidgetTree={RootWidget=box}
    function wheel:GetChildrenCount() error('UserWidget is not a panel') end
    wheel.inner=widget(kind..'.Inner');panel:AddChild(wheel.inner)
    wheel.cross=widget(kind..'.cross');wheel.inner:AddChild(wheel.cross)
    objects.decorations[kind][1]=wheel.cross
    if kind=='ability' then
        wheel.Darken=widget(kind..'.Darken');wheel.Glow=widget(kind..'.Glow')
        panel:AddChild(wheel.Darken);panel:AddChild(wheel.Glow)
        objects.decorations.ability[2]=wheel.Darken
        objects.decorations.ability[3]=wheel.Glow
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
            parent=selector.parent,reparent=selector.reparent,destination=selector.destination,
            reparentLayout=selector.reparentLayout,opacity=selector.opacity,
            layout=selector.layout,prepass=selector.prepass}
    end
end
local sharedTargets={}
local sharedDefinition={attach=function(_,_,original) return original end}
local sharedManager=Manager.new(sharedDefinition,
    State.specs(sharedGraph,category.sharedObjects),sharedGraph.order,sharedCreated)
local function managerFor(template)
    local projected=require('mc.selectors').project(graph,template.objects)
    return Manager.new(template,State.specs(projected,template.objects),projected.order)
end
local managers={}
for id,template in pairs(barsById) do managers[id]=managerFor(template) end
local manager=managers.SingleUnderbar
-- Orientation 7 is an Underbar (bottom/center), 5 a Sidebar (bottom/right);
-- double picks the Double version. Each names its settings after its menu.
-- ModCore Controls has reported abilities (group 1) as focused. Single key
-- indicators default Above (Underbar) and Left (Sidebar).
local function params(size,margin,orientation,state,kh,kv,double,position)
    orientation=orientation or 7
    local id=(double and 'Double' or 'Single')..(orientation==5 and 'Sidebar' or 'Underbar')
    local settings={[id..'S']=size or 100,[id..'M']=margin or 0,focus=bar.settings.focus}
    if not double then settings[id..'K']=(orientation==5 and kv or kh) or 0 end
    if double or orientation~=5 then settings[id..'A']=position or (orientation==5 and 6 or 7) end
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
assert(switcher:GetChildrenCount()==2)
local panelA,panelB=switcher:GetChildAt(0),switcher:GetChildAt(1)
assert(panelA~=actions and panelB~=actions)
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
-- -1 or 1), or the other pair when across. Labels beside their keys keep 4 px
-- clear of them.
local along={ability={nil,-1.5,-0.5,nil},consumable={0.5,1.5,2.5,3.5}}
local function lined(W,H,vertical,dx,dy,side,across)
    side=side or -1
    dx=dx or 0
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
                    near(lx,ex+side*(W/2+4));near(ly,ey)
                else
                    near(lx,ex);near(ly,ey+side*H/2)
                end
                assert(label.RenderTransform.Scale.X>=0,'labels must not mirror')
                assert(label.opacity==1)
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
near(objects.abilities.opacity,1);near(objects.consumables.opacity,bar.settings.focus.dim)
assert(switcher.active==1,'Bar update must not change the native switcher index')
local focusParams=params()
bar.events['controls.group.focus'](focusParams,{name='controls.group.focus',group={from=2,to=1}},
    {wheels={abilities=objects.abilities,consumables=objects.consumables}})
near(objects.abilities.opacity,1);near(objects.consumables.opacity,bar.settings.focus.dim)
-- A rebuild applies the current focus from the state.
assert(layout(params(100,0,7,{controls={group={from=1,to=2}}})))
near(objects.abilities.opacity,bar.settings.focus.dim);near(objects.consumables.opacity,1)
-- Margin steps so -100% leaves 8 px below the bar: at 0% the keys' bottom is
-- at 1000-14+40=1026, so each percent moves (1080-1026-8)/100=0.46 px. 50%
-- raises the keys 23 px; the box stays flush.
assert(layout(params(100,50)))
near(objects.abilities.opacity,1);near(objects.consumables.opacity,bar.settings.focus.dim)
wheelsAt(860,920)
lined(100,80,false,nil,-14-23)
-- -50% lowers them as far, and -100% puts their bottom at 1080-8=1072.
assert(layout(params(100,-50)))
lined(100,80,false,nil,-14+23)
assert(layout(params(100,-100)))
lined(100,80,false,nil,1072-40-1000)
-- Horizontal labels can sit below their keys instead; the keys then center on
-- the line, which sits 41.6 px lower.
assert(layout(params(100,0,7,nil,1)))
lined(100,80,false,nil,-80+41.6,1)
-- Position Bottom/Right (6) puts the box in the corner, at the keys' height
-- as at Bottom/Center. The full row's right edge, 3.5*107.5+50=426.25 right of
-- its center, keeps as far from the right edge as its bottom from the bottom
-- (1080-1026=54): 1920-54-1820-426.25=-380.25.
assert(layout(params(100,0,7,nil,0,nil,nil,6)))
wheelsAt(1720,920)
lined(100,80,false,-380.25,-14)
-- Horizontal Key Indicators also offer Left (2) and Right (3); the line then
-- sits 48 px lower.
assert(layout(params(100,0,7,nil,2)))
lined(100,80,false,nil,-80+48,-1,true)
assert(layout(params(100,0,7,nil,3)))
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
assert(layout(params(100,0,5)))
wheelsAt(1720,920)
lined(100,80,true,-4.9,-336.2)
local _,abilityNearest=offset('ability',3)
local _,consumableNearest=offset('consumable',1)
near(abilityNearest,-336.2-43);near(consumableNearest,-336.2+43)
-- At -100% its right edge and bottom sit 8 px from the corner.
assert(layout(params(100,-100,5)))
lined(100,80,true,1912-50-1820,1072-341-1000)
-- With labels on the right, the keys center on the line instead: -60.
assert(layout(params(100,0,5,nil,0,1)))
lined(100,80,true,-60,-381,1)
-- The Single Sidebar has no Position; a saved one is ignored.
local saved=params(100,0,5)
saved.settings.SingleSidebarA=5
assert(layout(saved))
wheelsAt(1720,920)
lined(100,80,true,-4.9,-336.2)
-- Vertical Key Indicators also offer Above (2) and Below (3); the keys center
-- on the X line, and the bottom label, half a key off its key, stays on the Y
-- line.
assert(layout(params(100,0,5,nil,0,2)))
lined(100,80,true,-60,-341,-1,true)
assert(layout(params(100,0,5,nil,0,3)))
lined(100,80,true,-60,-421,1,true)
-- Double bars give each wheel its own full bar centered on the center, every
-- slot in its own place even when empty, so a key and the one beside it in the
-- other row share a binding: ability T and R sit at -0.5 and 0.5 pitches,
-- consumables at all four. Consumables are one row (or column) further from
-- the edge, by the key plus two spacings: keys overlap each label by half of
-- it. Both rows' labels sit halfway between them, so each pair overlaps.
local placed={ability={nil,-0.5,0.5,nil},consumable={-1.5,-0.5,0.5,1.5}}
local function doubled(vertical,dx,dy,cross)
    for _,kind in ipairs({'ability','consumable'}) do
        local toward=kind=='ability' and -cross/2 or cross/2
        for index=1,4 do
            local label=objects.labels[kind..'Labels'][index]
            local a=placed[kind][index]
            if a then
                local x,y=offset(kind,index)
                local ex,ey=a*100*1.075,0
                if vertical then ex,ey=0,a*80*1.075 end
                ex,ey=ex+dx,ey+dy
                if kind=='consumable' then
                    if vertical then ex=ex-cross else ey=ey-cross end
                end
                near(x,ex);near(y,ey)
                local lx,ly=centerOf(label)
                if vertical then near(lx,ex+toward);near(ly,ey) else near(lx,ex);near(ly,ey+toward) end
                assert(label.opacity==1)
            else
                assert(label.opacity==0,kind..' empty slot label must be hidden')
            end
        end
    end
    -- Labels of the same slot meet: ability T over consumable T.
    local ax,ay=centerOf(objects.labels.abilityLabels[2])
    local cx,cy=centerOf(objects.labels.consumableLabels[2])
    near(ax,cx);near(ay,cy)
end
-- Double Underbar: labels are 20 high, so consumables sit 80+2*6=92 above, and
-- the labels between the rows hang from the line by their top edge:
-- -80+92/2+20/2=-24.
assert(layout(params(100,0,7,nil,nil,nil,true)))
wheelsAt(860,920)
doubled(false,0,-24,92)
assert(objects.change_prompt.opacity==0,'bars always hide the swap prompt')
-- Focus dims the other wheel, as in every bar.
near(objects.abilities.opacity,1);near(objects.consumables.opacity,bar.settings.focus.dim)
barsById.DoubleUnderbar.events['controls.group.focus'](params(100,0,7,nil,nil,nil,true),
    {name='controls.group.focus',group={from=1,to=2}},
    {wheels={abilities=objects.abilities,consumables=objects.consumables}})
near(objects.abilities.opacity,bar.settings.focus.dim);near(objects.consumables.opacity,1)
-- Double Sidebar: labels are 30 wide, so consumables sit 100+2*7.5=115 further
-- left; the labels between the columns center on the X line (-60+115/2=-2.5),
-- and the bottom one on the Y line (-80-1.5*86=-209).
assert(layout(params(100,0,5,nil,nil,nil,true)))
wheelsAt(1720,920)
doubled(true,-2.5,-209,115)
-- At -100% the column's outer edges sit 8 px from the corner: its right edge
-- moves from 1820-2.5+50=1867.5 to 1912 and its bottom (1.5*86+40 below the
-- ability wheel's center) from 960 to 1072.
assert(layout(params(100,-100,5,nil,nil,nil,true)))
doubled(true,-2.5+44.5,-209+112,115)
-- Position Middle/Right (5) moves the box to the right edge's middle,
-- (1080-160)/2=460, and centers the full column on it.
assert(layout(params(100,0,5,nil,nil,nil,true,5)))
wheelsAt(1720,460)
doubled(true,-2.5,0,115)
-- Double Underbar at Bottom/Right (6): the box sits in the corner, and the
-- full row's right edge (1.5*107.5+50 right of its center) keeps as far from
-- the right edge as its bottom (1000-24+40=1016) from the bottom, 64 px:
-- 1920-64-1820-211.25=-175.25.
assert(layout(params(100,0,7,nil,nil,nil,true,6)))
wheelsAt(1720,920)
doubled(false,-175.25,-24,92)
-- An unknown saved Position falls back to the bar's default edge.
assert(layout(params(100,0,7,nil,nil,nil,true,5)))
wheelsAt(860,920)
doubled(false,0,-24,92)
-- Size scales each shown key in place, and the pitch with it.
assert(layout(params(80)))
lined(80,64,false,nil,-80+32+8+16)
for index,button in ipairs(objects.buttons.abilitySlots) do
    near(button.RenderTransform.Scale.X,along.ability[index] and 0.8 or 1)
end
assert(layout(params(120)))
lined(120,96,false,nil,-80+48+12+16)
assert(layout(params()))
local lastKey=objects.buttons.consumableSlots[4]
local setScale=lastKey.SetRenderScale
local fail=true
function lastKey:SetRenderScale(value)
    if fail then fail=false;error('injected Bar key failure') end
    return setScale(self,value)
end
assert(not layout(params(110)))
lastKey.SetRenderScale=setScale
assert(active==manager and manager:detach(switcher))
assert(objects.change_prompt.opacity==1,'detach must restore the native swap prompt')
near(objects.consumables.opacity,1)
assert(switcher:GetChildAt(0)==panelA and switcher:GetChildAt(1)==panelB)
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
-- A shown key without a size must not partially move either group.
objects.buttons.abilitySlots[2].desired.X=0
assert(not manager:attach(switcher,objects,params()))
assert(switcher:GetChildrenCount()==2)
assert(sharedManager:detach(switcher))
assert(switcher:GetChildAt(0)==objects.abilities and switcher:GetChildAt(1)==objects.consumables)
assert(panelA:GetParent()==nil and panelB:GetParent()==nil)
assert(actions:GetParent()==nil and actions:GetChildrenCount()==0)
print('PASS Bar: shared wheel canvas, layout, rollback and restoration')
