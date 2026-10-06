package.path='Fangdango/Scripts/?.lua;ModCoreTemplates/Scripts/?.lua;'..package.path
local Objects=require('mc.objects')
local Widget=require('mc.widget')
package.loaded.mc={valid=Objects.valid,same=Objects.same,parent=Objects.parent,
    call=Objects.call,load=function(name) return require('mc.'..name) end}
local function widget(name)
    local w={name=name,children={},RenderTransform={Translation={X=0,Y=0},Scale={X=1,Y=1}},
        RenderTransformPivot={X=0.5,Y=0.5},opacity=1}
    function w:IsValid() return true end
    function w:GetFullName() return self.name end
    function w:GetAddress() return self.name..'-address' end
    function w:GetParent() return self.parent end
    function w:GetChildrenCount() return #self.children end
    function w:GetChildAt(index) return self.children[index+1] end
    function w:GetOuter() return self.outer end
    function w:GetDesiredSize() return {X=200,Y=160} end
    function w:ForceLayoutPrepass() end
    function w:GetRenderOpacity() return self.opacity end
    function w:SetRenderOpacity(value) self.opacity=value end
    function w:SetRenderTranslation(value) self.RenderTransform.Translation=value end
    function w:SetRenderScale(value) self.RenderTransform.Scale=value end
    function w:SetActiveWidgetIndex(index) self.active=index end
    function w:AddChild(child)
        assert(not child.parent)
        self.children[#self.children+1]=child
        child.parent=self
        local kind=(self.name=='HUD root' or self.name=='Actions')
            and 'CanvasPanelSlot' or 'WidgetSwitcherSlot'
        local slot={kind=kind}
        function slot:IsValid() return true end
        function slot:GetClass()
            if self.kind=='CanvasPanelSlot' then return nil end
            return {GetName=function() return self.kind end}
        end
        function slot:SetLayout(value) assert(self.kind=='CanvasPanelSlot');self.layout=value end
        function slot:SetAutoSize(value) assert(self.kind=='CanvasPanelSlot');self.autoSize=value end
        function slot:SetPosition(value) assert(self.kind=='CanvasPanelSlot');self.position=value end
        function slot:SetSize(value) assert(self.kind=='CanvasPanelSlot');self.size=value end
        function slot:SetPadding(value) assert(self.kind~='CanvasPanelSlot');self.padding=value end
        function slot:SetHorizontalAlignment(value) assert(self.kind~='CanvasPanelSlot');self.horizontal=value end
        function slot:SetVerticalAlignment(value) assert(self.kind~='CanvasPanelSlot');self.vertical=value end
        child.Slot=slot
        return slot
    end
    function w:RemoveChild(child)
        for index,item in ipairs(self.children) do
            if item==child then table.remove(self.children,index);child.parent=nil;return true end
        end
        return false
    end
    return w
end

local tree=widget('WidgetTree')
local hud=widget('HUD root')
local switcher=widget('Switcher');switcher.outer=tree
local actions=widget('Actions')
local bait1=widget('Bait 1')
local bait2=widget('Bait 2')
local abilities=widget('Abilities')
local consumables=widget('Consumables')
local prompt=widget('Change prompt')
abilities.GetDesiredSize=function() return {X=0,Y=0} end
abilities.DesiredSize={X=0,Y=0}
abilities.WidgetTree={RootWidget={WidthOverride=200,HeightOverride=160}}
hud:AddChild(switcher)
hud:AddChild(actions)
switcher:AddChild(abilities)
switcher:AddChild(consumables)
switcher:AddChild(bait1)
switcher:AddChild(bait2)
switcher:RemoveChild(abilities)
switcher:RemoveChild(consumables)
local abilitySlot=actions:AddChild(abilities)
local consumableSlot=actions:AddChild(consumables)
Widget.rememberSlot(abilities,abilitySlot)
Widget.rememberSlot(consumables,consumableSlot)
local definitions={dofile('Fangdango/Scripts/mc_wheels.lua'),
    dofile('Fangdango/Scripts/mc_bars.lua')}
local template=definitions[1]
assert(template.loaded==nil and definitions[2].loaded==nil,
    'quickslot layouts must not install a click-transition runtime')
local original={wheels={abilities={box=assert(Widget.box(abilities))},
    consumables={box=assert(Widget.box(consumables))}}}
local objects={actions=actions,
    wheels={abilities=abilities,consumables=consumables},change_prompt=prompt}
local dim=template.settings.focus.dim
-- ModCore Controls has reported abilities (group 1) as focused.
local function attach(align,placement,to,margin)
    return template.attach(objects,
        {settings={WheelsA=align,WheelsM=margin or 0,WheelsR=placement or 1,WheelsS=100,focus={dim=dim}},
            screen={width=1920,height=1080,scale=1},
            state={controls={group={from=1,to=to or 1}}}},original)
end
local function check(align,x,y,x2,y2,margin)
    assert(attach(align,nil,nil,margin)==original)
    assert(abilities.parent==actions and consumables.parent==actions)
    assert(abilitySlot.position.X==x and abilitySlot.position.Y==y)
    assert(consumableSlot.position.X==x2 and consumableSlot.position.Y==y2)
    assert(abilities.RenderTransform.Translation.X==0
        and abilities.RenderTransform.Translation.Y==0)
    assert(consumables.RenderTransform.Translation.X==0
        and consumables.RenderTransform.Translation.Y==0)
    assert(abilities.opacity==1 and consumables.opacity==dim and prompt.opacity==0,
        'attach must apply the initial focus')
end
-- Margin 0% keeps the wheels 32 px from the edge.
check(5,1688,380,1688,540) -- Right/Center: vertical edge
check(6,1688,728,1688,888) -- Bottom/Right: includes vertical edge
check(7,760,888,960,888) -- Bottom/Center: horizontal edge
-- The margin is 8+24*(1+Margin/100) px: -100% is 8 px and 100% is 56 px.
check(6,1712,752,1712,912,-100)
check(6,1664,704,1664,864,100)
attach(6,0)
assert(prompt.opacity==1,'overlap must retain the native swap prompt')
assert(abilities.opacity==1 and consumables.opacity==1,'overlapping wheels keep the native look')
local function focus(placement)
    template.events['controls.group.focus'](
        {settings={WheelsA=6,WheelsM=20,WheelsR=placement,WheelsS=100,focus={dim=dim}},
            screen={width=1920,height=1080,scale=1},state={}},
        {name='controls.group.focus',group={from=1,to=2}},
        {wheels={abilities=abilities,consumables=consumables}})
end
attach(6,1)
focus(1)
assert(abilities.opacity==dim and consumables.opacity==1,'the unfocused wheel must dim')
focus(0)
assert(abilities.opacity==1 and consumables.opacity==1,'overlapping wheels keep the native look')
attach(6,1,2)
assert(abilities.opacity==dim and consumables.opacity==1,'attach must apply the current focus')
print('PASS: Wheels positions prepared output-canvas children at supported edges')
