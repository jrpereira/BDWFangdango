local root = 'Fangdango'
package.path = root .. '/../ModCoreTemplates/Scripts/?.lua;' .. package.path
local definitions=dofile(root .. '/Scripts/templates/mc.lua')
local wheels,template=definitions[2],definitions[2]
local category=dofile('ModCoreTemplates/Scripts/categories/player_quickslots.lua')
category.objects.switcher.object='switcher'
local graph=require('mc.selectors').compile(category.objects)
local State=require('mc.target_state')
local Manager=require('mc.managed_template')
local manager=Manager.new(template,State.specs(graph,template.objects),graph.order)
local screen={width=1920,height=1080,left=0,center=960,right=1920,
    bottom=0,middle=540,top=1080}
local function params(settings)
    local effective={}
    for key,value in pairs(wheels.settings) do effective[key]=value end
    for _,field in ipairs(wheels.menu.fields) do
        if field.type~='navigation' then
            local value=settings[field.id]
            if value==nil then value=field.default end
            effective[field.id]=value
        end
    end
    return {settings=effective,screen=screen}
end
local function attach(root,settings,targets) return manager:attach(root,targets,params(settings)) end
local function update(root,settings,targets) return manager:update(root,targets,params(settings)) end
local function detach(root) return manager:detach(root) end

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

local service={}
function service:valid(value) return type(value)=='table' and value.IsValid and value:IsValid() end
function service:identity(value) return value:GetFullName() end
function service:same(a,b) return self:valid(a) and self:valid(b) and self:identity(a)==self:identity(b) end
function service:parent(value) return value:GetParent() end

local hud=widget('WBP_GameHUD_C /Engine/Transient.GameHUD')
local owner=widget('Panel /Engine/Transient.Panel')
local switcher=widget('Switcher /Engine/Transient.Switcher')
StaticFindObject=function(path)assert(path=='/Engine/Transient.Switcher');return switcher end
local ability=widget('WBP_AA_Quickslots_C /Engine/Transient.Abilities')
local consumable=widget('WBP_HUD_Quickslots_C /Engine/Transient.Consumables')
local prompt=widget('Prompt /Engine/Transient.Prompt')
local buttonNames={
    'ability_left','ability_top','ability_right','ability_bottom',
    'consumable_left','consumable_top','consumable_right','consumable_bottom',
}
local buttons={}
local abilityBindings=widget('Ability bindings')
local consumableBindings=widget('Consumable bindings')
ability:AddChild(abilityBindings)
consumable:AddChild(consumableBindings)
ability.WBP_AA_Quickslots_Bindings=abilityBindings
consumable.WBP_HUD_Quickslots_Bindings=consumableBindings
for _,name in ipairs(buttonNames) do
    local bindings=name:match('^ability') and abilityBindings or consumableBindings
    local button=widget(name)
    bindings:AddChild(button)
    bindings[name:match('_(%w+)$'):gsub('^%l',string.upper)]=button
    buttons[name]={widget=button,parent=bindings}
end
hud:AddChild(owner)
hud:AddChild(prompt)
owner:AddChild(switcher)
switcher:AddChild(ability)
switcher:AddChild(consumable)
switcher:SetActiveWidgetIndex(1)
hud.WBP_AA_Quickslots=ability
hud.WBP_HUD_Quickslots=consumable
hud.WBP_HUD_Quickslots_ChangePrompt=prompt
hud.QuickslotsSwitcher=switcher
switcher.owner=hud
FindAllOf=function(class) return class=='WBP_GameHUD_C' and {hud} or {} end
local controls=dofile('ModCoreControls/Scripts/mcc/player_actions/quickslot_service.lua').new()
local Delivery=dofile('ModCoreControls/Scripts/mcc/player_actions/delivery.lua')
local groupState={selectedGroup=2,defaultGroup=2,
    groupTypes={[1]='ability',[2]='consumable'}}
local groupKey={binding={mode=2},groupIndex=1}


local swap={Style=0,WheelsX=20,WheelsY=40,WheelsSize=90}
local targets={switcher=switcher,abilities=ability,consumables=consumable,buttons={}}
for _,name in ipairs(buttonNames) do targets.buttons[#targets.buttons+1]=buttons[name].widget end
local minima=definitions[1]
local minimaManager=Manager.new(minima,State.specs(graph,minima.objects),graph.order)
local minimaState={selectedGroup=1,defaultGroup=1,
    groupTypes={[1]='ability',[2]='consumable'}}
local secondWheelHold={binding={mode=2},groupIndex=2}
switcher:SetActiveWidgetIndex(0)
assert(minimaManager:attach(switcher,targets,params({})))
assert(switcher:GetChildrenCount()==2 and switcher:GetActiveWidgetIndex()==0)
assert(Delivery.deliver({},minimaState,secondWheelHold,'Started',controls))
assert(switcher:GetActiveWidgetIndex()==1)
assert(Delivery.deliver({},minimaState,secondWheelHold,'Completed',controls))
assert(switcher:GetActiveWidgetIndex()==0)
assert(minimaManager:detach(switcher))
assert(switcher:GetChildrenCount()==2 and switcher:GetActiveWidgetIndex()==0)
switcher:SetActiveWidgetIndex(1)
local wheelsManager=Manager.new(wheels,
    State.specs(graph,wheels.objects),graph.order)
assert(wheelsManager:attach(switcher,targets,params({Style=1,Wheel1X=-100,Wheel2X=200})))
assert(consumable:GetParent()==owner and ability:GetParent()==switcher
    and switcher:GetChildrenCount()==1 and switcher:GetActiveWidgetIndex()==0)
assert(ability.RenderTransform.Translation.X==-100
    and consumable.RenderTransform.Translation.X==200)
for _,record in pairs(buttons) do assert(record.widget:GetParent()==record.parent) end
assert(wheelsManager:detach(switcher))
assert(switcher:GetChildAt(0)==ability and switcher:GetChildAt(1)==consumable)
assert(switcher:GetActiveWidgetIndex()==1)
assert(attach(switcher,swap,targets))
for _,record in pairs(buttons) do assert(record.widget:GetParent()==record.parent) end
assert(Delivery.deliver({},groupState,groupKey,'Started',controls))
assert(switcher:GetActiveWidgetIndex()==0)
assert(Delivery.deliver({},groupState,groupKey,'Completed',controls))
assert(switcher:GetActiveWidgetIndex()==1)
assert(switcher:GetChildrenCount()==2 and switcher:GetActiveWidgetIndex()==1)
assert(ability.RenderTransform.Translation.X==20 and consumable.RenderTransform.Translation.X==20)
assert(ability.RenderTransform.Scale.X==0.9 and consumable.opacity==1)
assert(require('mc.widget').readback(ability):find('opacity=1 scale=0.9 x=20 y=40',1,true))
local distant={Style=1,Wheel1X=-100,Wheel1Y=10,Wheel2X=200,Wheel2Y=30}
assert(update(switcher,distant,targets))
assert(math.abs(consumable.RenderTransform.Scale.X-0.765)<0.00001
    and consumable.opacity==0.85)
assert(switcher:GetActiveWidgetIndex()==0)
assert(Delivery.deliver({},groupState,groupKey,'Started',controls)
    and switcher:GetActiveWidgetIndex()==0,
    'detached wheels stay visible while MCC changes control groups')
assert(Delivery.deliver({},groupState,groupKey,'Completed',controls))
for _,record in pairs(buttons) do assert(record.widget:GetParent()==record.parent) end
assert(ability:GetParent()==switcher and consumable:GetParent()==owner)
assert(ability.RenderTransform.Translation.X==-100 and consumable.RenderTransform.Translation.X==200)
assert(update(switcher,distant,targets))
assert(ability.RenderTransform.Translation.X==-100)
assert(update(switcher,swap,targets))
assert(switcher:GetChildrenCount()==2 and switcher:GetActiveWidgetIndex()==1)
assert(detach(switcher,swap))
for _,record in pairs(buttons) do
    assert(record.widget:GetParent()==record.parent)
    assert(record.widget.RenderTransform.Translation.X==0)
end
assert(ability.RenderTransform.Translation.X==0 and consumable.RenderTransform.Translation.X==0)
assert(ability.opacity==1 and consumable.opacity==1)
local originalAdd=owner.AddChild
function owner:AddChild() error('injected attachment failure') end
local failed,why=attach(switcher,distant,targets)
assert(not failed and why:find('injected attachment failure',1,true))
assert(switcher:GetChildrenCount()==2 and ability:GetParent()==switcher)
owner.AddChild=originalAdd
local originalSwitcherAdd=switcher.AddChild
owner.AddChild=function() error('injected attachment failure') end
switcher.AddChild=function() error('injected restoration failure') end
failed,why=attach(switcher,distant,targets)
assert(not failed and why:find('restoration failed',1,true))
owner.AddChild,switcher.AddChild=originalAdd,originalSwitcherAdd
assert(detach(switcher,{}))
assert(switcher:GetChildrenCount()==2 and ability:GetParent()==switcher
    and consumable:GetParent()==switcher,
    'failed initial attach must retain a restoration record')
assert(attach(switcher,distant,targets))
assert(detach(switcher,{}))
-- Exercise the actual new runtime's selection, update and detach dispatch.
local errors={}
local host={
    valid=function(o) return service:valid(o) end,
    identity=function(o) return service:identity(o) end,
    ready=function() return true end,
    matches=function(o,s) return s.object=='switcher' and o==switcher
        or s.class=='WBP_AA_Quickslots_C' and o==ability
        or s.class=='WBP_HUD_Quickslots_C' and o==consumable end,
    parent=function(o) return service:parent(o) end,
    watch=function() end,
    screen=function() return screen end,
    find=function(s) return s.object=='switcher' and {switcher} or {} end,
    child=function(parent,class)
        for _,child in ipairs(parent.children) do
            if child:GetFullName():match('^(%S+)')==class then return child end
        end
    end,
    member=function(parent,path)
        local current=parent
        for name in path:gmatch('[^.]+') do
            current=current and (name=='@owner' and current.owner or current[name])
        end
        return current
    end,
    subscribe=function() return function() end end,
    onError=function(e) errors[#errors+1]=e end,
}
local Runtime=require('mc.runtime')
local originalWheelsAttach=template.attach
local runtimeAttachCalls=0
template.attach=function(...)
    runtimeAttachCalls=runtimeAttachCalls+1
    return originalWheelsAttach(...)
end
local model=require('mc.menu_model').build(
    {category},
    {template},{root..'/Scripts/templates/mc_wheels.lua'})
local runtime=Runtime.new(host,model.categories,model.templates)
runtime:start()
runtime:select('player.quickslots',{[template.id]=swap})
assert(switcher:GetChildrenCount()==2)
assert(next(runtime:attachments(template.id)), 'runtime did not attach')
runtime:select('player.quickslots',{[template.id]=distant})
assert(switcher:GetChildrenCount()==1 and consumable:GetParent()==owner)
assert(next(runtime:attachments(template.id)), 'runtime lost distant attachment')
local attachedDistant=runtimeAttachCalls
runtime:event({kind='changed',object=switcher,epoch=runtime.epoch})
assert(runtimeAttachCalls==attachedDistant,
    'lifecycle reconciliation must not reattach an intentionally moved wheel')
assert(next(runtime:attachments(template.id)),
    'lifecycle reconciliation must retain the distant attachment')
assert(consumable:GetParent()==owner and switcher:GetChildrenCount()==1,
    'reconciliation must not restore the intentionally moved wheel')
runtime:select('player.quickslots',{[template.id]=swap})
assert(switcher:GetChildrenCount()==2)
assert(next(runtime:attachments(template.id)),
    'runtime lost swap attachment: '..tostring(errors[#errors] and errors[#errors].message))
-- Failed update must report failure and restore the previous successful layout.
function owner:AddChild(child)
    if child==consumable then error('injected update failure') end
    return originalAdd(self,child)
end
runtime:select('player.quickslots',{[template.id]=distant})
assert(#errors==1 and errors[1].stage=='update',
    'errors='..#errors..' first='..tostring(errors[1] and errors[1].stage)
        ..' message='..tostring(errors[1] and errors[1].message))
assert(switcher:GetChildrenCount()==2 and ability.RenderTransform.Translation.X==20)
assert(consumable.opacity==1)
owner.AddChild=originalAdd
runtime:select('player.quickslots',{})
assert(switcher:GetChildrenCount()==2 and switcher:GetActiveWidgetIndex()==1)
assert(ability.RenderTransform.Translation.X==0 and ability.opacity==1)
for _,record in pairs(buttons) do assert(record.widget:GetParent()==record.parent) end
-- Readiness failure must be false, not nil (nil means success in MCT).
local missing=widget('Switcher missing')
local ready,reason=attach(missing,swap,{})
assert(ready==false and reason:match('^not_ready'))
assert(detach(missing,swap))
runtime:stop()
print('Fangdango new-runtime attach/update/detach, rollback and readiness passed')
