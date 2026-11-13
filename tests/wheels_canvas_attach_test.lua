package.path='Fangdango/Scripts/?.lua;ModCoreTemplates/Scripts/?.lua;ModCoreTemplates/Scripts/vendor/?.lua;'..package.path
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
    w.ColorAndOpacity={R=1,G=1,B=1,A=1}
    function w:SetColorAndOpacity(value) self.ColorAndOpacity=value end
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
local buttons,labels={abilitySlots={},consumableSlots={}},{abilityLabels={},consumableLabels={}}
for index=1,4 do
    buttons.abilitySlots[index]=widget('Ability key '..index)
    buttons.consumableSlots[index]=widget('Consumable key '..index)
    labels.abilityLabels[index]=widget('Ability label '..index)
    labels.consumableLabels[index]=widget('Consumable label '..index)
end
local objects={actions=actions,
    wheels={abilities=abilities,consumables=consumables},change_prompt=prompt,
    buttons=buttons,labels=labels}
local tint=template.settings.focus.tint
local dim=tint.A
local function alpha(w) return w.ColorAndOpacity.A end
-- A wheel reads as dimmed when each of its keys is tinted and each label faded;
-- the wheel itself is never tinted. lit[index] marks a key with a Global key.
local function wheelAlpha(w,lit)
    assert(alpha(w==1 and abilities or consumables)==1,'the wheel itself stays untinted')
    local keys=w==1 and buttons.abilitySlots or buttons.consumableSlots
    local names=w==1 and labels.abilityLabels or labels.consumableLabels
    local value
    for index=1,4 do
        local expected=alpha(keys[index])
        assert(names[index].opacity==expected,'a label follows its key')
        if not (lit and lit[index]) then
            assert(value==nil or value==expected,'every key of a wheel dims alike')
            value=expected
        else
            assert(expected==1,'a key with a Global key keeps the native look')
        end
    end
    return value
end
-- ModCore Controls has reported abilities (group 1) as focused.
local function attach(align,placement,to,margin,size)
    return template.attach(objects,
        {settings={WheelsA=align,WheelsM=margin or 0,WheelsR=placement or 1,WheelsS=size or 100,focus={tint=tint}},
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
    assert(wheelAlpha(1)==1 and wheelAlpha(2)==dim and prompt.opacity==0,
        'attach must apply the initial focus')
end
-- The margin is 8+64*Margin/100 px: 0% is 8 px and 100% is 72 px.
check(5,1712,380,1712,540) -- Right/Center: vertical edge
check(6,1712,752,1712,912) -- Bottom/Right: includes vertical edge
check(7,760,912,960,912) -- Bottom/Center: horizontal edge
check(6,1648,688,1648,848,100)
-- The margin is in 1080p pixels, scaled to the screen: on a 3840x2160 screen at
-- scale 1 the 100% margin is 144 px, and at scale 2 (1920x1080 units) 72.
for _,case in ipairs({{3840,2160,1,144},{1920,1080,2,72}}) do
    local width,height,scale,margin=table.unpack(case)
    template.attach(objects,{settings={WheelsA=6,WheelsM=100,WheelsR=1,WheelsS=100,focus={tint=tint}},
        screen={width=width,height=height,scale=scale},
        state={controls={group={from=1,to=1}}}},original)
    assert(math.abs(abilitySlot.position.X-(width-200-margin))<1e-6
        and math.abs(abilitySlot.position.Y-(height-320-margin))<1e-6,'the margin keeps its share of the screen')
end
attach(6,0)
assert(prompt.opacity==1,'overlap must retain the native swap prompt')
assert(wheelAlpha(1)==1 and wheelAlpha(2)==1,'overlapping wheels keep the native look')
local function focus(placement,global)
    template.events['controls.group.focus'](
        {settings={WheelsA=6,WheelsM=20,WheelsR=placement,WheelsS=100,focus={tint=tint}},
            screen={width=1920,height=1080,scale=1},state={controls={global=global}}},
        {name='controls.group.focus',group={from=1,to=2}},objects)
end
attach(6,1)
focus(1)
assert(wheelAlpha(1)==dim and wheelAlpha(2)==1,'the unfocused wheel\'s keys must dim')
-- Keys with a ModCore Controls Global key fire whatever the focus.
focus(1,{[1]={false,true,false,false},[2]={true,true,true,true}})
assert(wheelAlpha(1,{false,true})==dim and wheelAlpha(2)==1,'a Global key keeps its key undimmed')
focus(1)
assert(wheelAlpha(1)==dim,'a key dims again once its Global key is gone')
-- The Global keys event reapplies the current focus from the state.
template.events['controls.slots.global'](
    {settings={WheelsA=6,WheelsM=20,WheelsR=1,WheelsS=100,focus={tint=tint}},
        state={controls={group={from=2,to=1}}}},
    {name='controls.slots.global',global={[1]={false,false,false,false},[2]={false,false,true,false}}},objects)
assert(wheelAlpha(1)==1 and wheelAlpha(2,{false,false,true})==dim,'the Global keys event must reapply focus')
focus(0)
assert(wheelAlpha(1)==1 and wheelAlpha(2)==1,'overlapping wheels keep the native look')
attach(6,1,2)
assert(wheelAlpha(1)==dim and wheelAlpha(2)==1,'attach must apply the current focus')
local key=buttons.abilitySlots[1]
assert(key.ColorAndOpacity.B>key.ColorAndOpacity.R,'the tint leans blue')
print('PASS: Wheels positions prepared output-canvas children at supported edges')
