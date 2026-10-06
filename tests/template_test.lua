package.path='Fangdango/Scripts/?.lua;ModCoreTemplates/Scripts/?.lua;'..package.path
-- MCT keeps objects as UE4SSLuaEventBridge weak handles; use its test double.
dofile('ModCoreTemplates/tests/support/lifetimes.lua').install()
local definitions=dofile('Fangdango/tests/load_templates.lua')()
local template=definitions[1]
local category=dofile('ModCoreTemplates/Scripts/categories/player_quickslots.lua')
local Objects=require('mc.objects')
local Runtime=require('mc.runtime')

local function widget(name,class)
    local w={name=name,class=class,children={},opacity=1,
        RenderTransform={Translation={X=0,Y=0},Scale={X=1,Y=1}},
        RenderTransformPivot={X=0,Y=0}}
    function w:IsValid() return true end
    function w:GetFullName() return self.name end
    function w:GetAddress() return self.name end
    function w:GetOuter() return self.outer end
    function w:GetParent() return self.parent end
    function w:GetChildrenCount() return #self.children end
    function w:GetChildAt(index) return self.children[index+1] end
    function w:GetDesiredSize() return {X=200,Y=160} end
    function w:ForceLayoutPrepass() end
    function w:GetRenderOpacity() return self.opacity end
    function w:SetRenderOpacity(value) self.opacity=value end
    function w:SetRenderTranslation(value) self.RenderTransform.Translation=value end
    function w:SetRenderScale(value) self.RenderTransform.Scale=value end
    function w:AddChild(child)
        assert(not child.parent)
        self.children[#self.children+1]=child
        child.parent=self
        local canvas=self.class=='CanvasPanel'
        local slot={Padding={Left=0,Top=0,Right=0,Bottom=0},
            HorizontalAlignment=0,VerticalAlignment=0,
            LayoutData={Offsets={Left=0,Top=0,Right=0,Bottom=0},
                Anchors={Minimum={X=0,Y=0},Maximum={X=0,Y=0}},Alignment={X=0,Y=0}},
            ZOrder=0,bAutoSize=false}
        function slot:IsValid() return true end
        function slot:GetClass() return {GetName=function()
            return canvas and 'CanvasPanelSlot' or 'WidgetSwitcherSlot'
        end} end
        function slot:SetLayout(value) assert(canvas);self.LayoutData=value end
        function slot:SetAutoSize(value) assert(canvas);self.bAutoSize=value end
        function slot:SetZOrder(value) self.ZOrder=value end
        function slot:SetPosition(value)
            assert(canvas)
            if self.failPosition then self.failPosition=false;error('injected position failure') end
            self.LayoutData.Offsets.Left,self.LayoutData.Offsets.Top=value.X,value.Y
        end
        function slot:SetSize(value)
            assert(canvas)
            self.LayoutData.Offsets.Right,self.LayoutData.Offsets.Bottom=value.X,value.Y
        end
        function slot:SetPadding(value) self.Padding=value end
        function slot:SetHorizontalAlignment(value) self.HorizontalAlignment=value end
        function slot:SetVerticalAlignment(value) self.VerticalAlignment=value end
        child.Slot=slot
        return slot
    end
    function w:RemoveChild(child)
        for index,value in ipairs(self.children) do
            if value==child then table.remove(self.children,index);child.parent=nil;return true end
        end
        return false
    end
    return w
end

local hud=widget('HUD','UserWidget')
local tree=widget('Tree','WidgetTree')
local root=widget('HUD root','Overlay')
local switcher=widget('Switcher','WidgetSwitcher')
local ability=widget('Abilities','WBP_AA_Quickslots_C')
local consumable=widget('Consumables','WBP_HUD_Quickslots_C')
local prompt=widget('Prompt','Widget')
hud.WidgetTree={RootWidget=root}
hud.WBP_AA_Quickslots,hud.WBP_HUD_Quickslots=ability,consumable
hud.WBP_HUD_Quickslots_ChangePrompt=prompt
switcher.owner,switcher.outer=hud,tree
root:AddChild(switcher)
switcher:AddChild(consumable)
switcher:AddChild(ability)
ability.Slot:SetPadding({Left=17,Top=18,Right=19,Bottom=20})
StaticFindObject=function(path) return {path=path} end
local made=0
StaticConstructObject=function(class,outer)
    assert(outer==tree)
    made=made+1
    return widget('Created '..made,class.path:match('([^%.]+)$'))
end
FName=function(value) return value end
local errors={}
local host={valid=Objects.valid,identity=function(value) return value.name end,
    ready=function() return true end,parent=Objects.parent,watch=function() end,
    screen=function() return {width=1920,height=1080,scale=1} end,
    matches=function(value,selector)
        return selector.object==category.objects.switcher.object and value==switcher
            or selector.class==value.class
    end,
    find=function() return {switcher} end,
    member=function(value,path)
        for name in path:gmatch('[^.]+') do
            value=value and (name=='@owner' and value.owner or value[name])
        end
        return value
    end,
    child=function(value,class)
        for _,child in ipairs(value.children) do if child.class==class then return child end end
    end,
    subscribe=function() return function() end end,
    onError=function(value) errors[#errors+1]=value end}
local model=require('mc.menu_model').build({category},{template},
    {'Fangdango/Scripts/mc_wheels.lua'})
template=model.templates[1]
local state={revision=0,controls={group={}}}
local runtime=Runtime.new(host,model.categories,model.templates,state)
local function select(margin)
    runtime:select(category.name,{[template.id]={WheelsA=7,WheelsM=margin,WheelsR=1,WheelsS=100}})
end
runtime:start()
assert(made==0,'unselected category must leave the native hierarchy intact')
select(0)
assert(next(runtime:attachments(template.id)),'current Wheels must attach through the runtime')
local actions=ability:GetParent()
assert(actions.class=='CanvasPanel' and actions:GetParent()==root
    and consumable:GetParent()==actions and made==3,
    'MCT must place both wheels directly in its canvas without host buttons')
assert(switcher:GetChildrenCount()==2 and prompt.opacity==0)
local firstY=ability.Slot.LayoutData.Offsets.Top
select(20)
local updatedY=ability.Slot.LayoutData.Offsets.Top
assert(updatedY~=firstY and made==3 and ability:GetParent()==actions,
    'settings update must reposition the existing wheels')
runtime:event({kind='changed',object=switcher,epoch=runtime.epoch})
assert(made==3 and ability.Slot.LayoutData.Offsets.Top==updatedY,
    'reconciliation must retain the current wheel layout')
ability.Slot.failPosition=true
select(40)
assert(#errors==1 and errors[1].stage=='update'
    and errors[1].message:find('injected position failure',1,true))
assert(ability.Slot.LayoutData.Offsets.Top==updatedY
    and next(runtime:attachments(template.id)),
    'failed settings update must recover the previous successful layout')
local dim=template.settings.focus.dim
assert(ability.opacity==1 and consumable.opacity==1,'no focus reported: both wheels stay opaque')
-- The MCT event hub records ModCore Controls' focus, then notifies the runtime.
state.events={['controls.group.focus']={revision=1}}
state.revision=1;state.controls.group.from=1;state.controls.group.to=2
runtime:stateChanged({name='controls.group.focus',revision=1,group={from=1,to=2}})
assert(ability.opacity==dim and consumable.opacity==1,'focus event must dim the unfocused wheel')
ability.Slot.failPosition=nil
select(0)
assert(ability.opacity==dim and consumable.opacity==1,'a rebuild must keep the current focus')
state.revision=2;state.controls.group.from=2;state.controls.group.to=1
runtime:stateChanged({name='controls.group.focus',revision=2,group={from=2,to=1}})
assert(ability.opacity==1 and consumable.opacity==dim,'focus must follow each event')
runtime:select(category.name,{})
assert(ability.opacity==1 and consumable.opacity==1,'leaving the layout restores wheel opacity')
assert(ability:GetParent()==switcher and consumable:GetParent()==switcher)
assert(switcher:GetChildAt(0)==consumable and switcher:GetChildAt(1)==ability)
assert(ability.Slot.Padding.Left==17 and ability.Slot.Padding.Bottom==20)
assert(actions:GetParent()==nil and root:GetChildrenCount()==1 and prompt.opacity==1)
runtime:stop()
print('PASS: current Wheels runtime attach, update, reconciliation, rollback and native restoration')
