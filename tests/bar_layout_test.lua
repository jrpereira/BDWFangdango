package.path='ModCoreTemplates/Scripts/?.lua;'..package.path
local bar=dofile('Fangdango/Scripts/templates/mc.lua')[3]
local category=dofile('ModCoreTemplates/Scripts/categories/player_quickslots.lua')
local graph=require('mc.selectors').compile(category.targets)
local State=require('mc.target_state')
local Manager=require('mc.managed_template')
local function widget(name)
    local w = {
        name=name, children={}, RenderTransform={Translation={X=0,Y=0},Scale={X=1,Y=1}},
        opacity=1, active=0,
    }
    function w:IsValid() return self.invalid ~= true end
    function w:GetFullName() return self.name end
    function w:GetParent() return self.parent end
    function w:GetChildrenCount() return #self.children end
    function w:GetChildAt(index) return self.children[index+1] end
    function w:AddChild(child)
        assert(child.parent==nil)
        self.children[#self.children+1]=child
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
owner:AddChild(switcher)
function owner:GetCachedGeometry() return 'owner geometry' end
StaticFindObject=function(path)
    assert(path=='/Script/UMG.Default__SlateBlueprintLibrary')
    return {ScreenToWidgetLocal=function(_,context,geometry,screen,result,window)
        assert(context==owner and geometry=='owner geometry' and window)
        result.X=(screen.X-160)/2;result.Y=(screen.Y-100)/2
    end}
end
local objects={switcher=switcher,buttons={abilitySlots={},consumableSlots={}}}
for _,kind in ipairs({'ability','consumable'}) do
    local wheel,box,panel=widget(kind),widget(kind..'Box'),widget(kind..'Panel')
    objects[kind=='ability' and 'abilities' or 'consumables'],
        objects[kind..'_box'],objects[kind..'_panel']=wheel,box,panel
    switcher:AddChild(wheel);wheel:AddChild(box);box:AddChild(panel)
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
        function button:ForceLayoutPrepass()end
        function button:GetDesiredSize()return self.desired end
        panel:AddChild(button)
        objects.buttons[kind..'Slots'][index]=button
    end
end
switcher.active=1
local manager=Manager.new(bar,State.specs(graph,bar.targets),graph.order)
local function params(size,margin,tightness)
    return {settings={Size=size or 100,Margin=margin or 0,
        Spacing=10,Tightness=tightness or -25},
        screen={center=960,middle=540}}
end
local function near(a,b) assert(math.abs(a-b)<0.00001,tostring(a)..' ~= '..tostring(b)) end
local function bounds(button)
    local size,pivot,transform=button.desired,button.RenderTransformPivot,button.RenderTransform
    local scale=transform.Scale.X
    return transform.Translation.X+pivot.X*size.X*(1-scale)+math.min(0,scale*size.X),
        transform.Translation.Y+pivot.Y*size.Y*(1-scale)+math.min(0,scale*size.Y)
end
assert(manager:attach(switcher,objects,params()))
assert(switcher:GetChildrenCount()==0)
near(objects.ability_box.WidthOverride,265)
near(objects.consumable_box.WidthOverride,265)
near(objects.abilities.RenderTransform.Translation.X+265,400)
near(objects.consumables.RenderTransform.Translation.X,400)
local function point(kind,index)
    local button=objects.buttons[kind..'Slots'][index]
    assert(button:GetParent()==objects[kind..'_panel'])
    local x,y=bounds(button)
    local wheel=objects[kind=='ability' and 'abilities' or 'consumables']
    return x+wheel.RenderTransform.Translation.X,y+wheel.RenderTransform.Translation.Y
end
local x1,y1=point('ability',1)
local x2,y2=point('ability',2)
local x3,y3=point('ability',3)
local x4,y4=point('ability',4)
local x5,y5=point('consumable',1)
local x6,y6=point('consumable',2)
local x7,y7=point('consumable',3)
local x8,y8=point('consumable',4)
assert(x1<x2 and x2<x3 and x3<x4 and x4<x5 and x5<x6 and x6<x8 and x8<x7)
near(y1,y3);near(y1,y6);near(y1,y7)
near(y2,y4);near(y2,y5);near(y2,y8)
assert(y1>y2)
for _,kind in ipairs({'ability','consumable'}) do
    local wheel=objects[kind=='ability' and 'abilities' or 'consumables']
    assert(wheel:GetParent()==owner and wheel.opacity==1)
    assert(wheel.cross.opacity==0)
end
assert(objects.abilities.Darken.opacity==0 and objects.abilities.Glow.opacity==0)
-- Group/Flat access owns wheel panel opacity while Bar owns only decoration opacity.
objects.consumables:SetRenderOpacity(0.3)
assert(manager:update(switcher,objects,params(100,0,0)))
local _,middleTop=point('ability',2)
local _,middleBottom=point('ability',1)
assert(middleBottom-middleTop>0 and middleBottom-middleTop<y1-y2)
assert(manager:update(switcher,objects,params(100,0,50)))
near(objects.consumables.opacity,0.3)
near(objects.ability_box.WidthOverride,430)
local row={}
for index=1,4 do
    local x,y=point('ability',index);row[index]={x=x,y=y}
    x,y=point('consumable',index);row[index+4]={x=x,y=y}
end
for index=2,8 do
    assert(row[index-1].x<row[index].x)
    near(row[1].y,row[index].y)
end
assert(manager:update(switcher,objects,params(150,20)))
near(objects.ability_box.WidthOverride,397.5)
near(objects.ability_box.HeightOverride,252)
near(objects.abilities.RenderTransform.Translation.X+397.5,390)
near(objects.consumables.RenderTransform.Translation.X,410)
near(objects.abilities.RenderTransform.Translation.Y,
    objects.consumables.RenderTransform.Translation.Y)
assert(manager:update(switcher,objects,params(-50,-100)))
near(objects.ability_box.WidthOverride,132.5)
near(objects.abilities.RenderTransform.Translation.X+132.5,450)
near(objects.consumables.RenderTransform.Translation.X,350)
for index,button in ipairs(objects.buttons.abilitySlots)do
    near(button.RenderTransform.Scale.X,-0.5)
end
assert(manager:update(switcher,objects,params(0)))
near(objects.ability_box.WidthOverride,0)
assert(manager:update(switcher,objects,params()))
near(objects.ability_box.WidthOverride,265)
local add=objects.consumable_panel.AddChild
local fail=true
function objects.consumable_panel:AddChild(child)
    if fail then fail=false;error('injected Bar reparent failure') end
    return add(self,child)
end
assert(not manager:update(switcher,objects,params(150)))
objects.consumable_panel.AddChild=add
assert(manager:detach(switcher))
near(objects.consumables.opacity,0.3)
assert(switcher:GetChildAt(0)==objects.abilities and switcher:GetChildAt(1)==objects.consumables)
assert(switcher.active==1)
assert(objects.abilities.cross.opacity==1 and objects.consumables.cross.opacity==1)
assert(objects.abilities.Darken.opacity==1 and objects.abilities.Glow.opacity==1)
for _,kind in ipairs({'ability','consumable'}) do
    local box=objects[kind..'_box']
    assert(box.WidthOverride==321 and not box.bOverride_WidthOverride)
    assert(box.HeightOverride==234 and box.bOverride_HeightOverride)
    for index,button in ipairs(objects.buttons[kind..'Slots'])do
        assert(objects[kind..'_panel']:GetChildAt(index+(kind=='ability' and 2 or 0))==button)
        near(button.RenderTransform.Translation.X,0);near(button.RenderTransform.Scale.X,1)
    end
end
-- An unavailable desired size must not partially move either group.
objects.buttons.abilitySlots[1].desired.X=0
assert(not manager:attach(switcher,objects,params()))
assert(switcher:GetChildrenCount()==2)
print('PASS Bar: two staggered/flat wheels, transparent backgrounds, rollback and restoration')
