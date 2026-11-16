package.path='Fangdango/Scripts/?.lua;ModCoreTemplates/Scripts/?.lua;ModCoreTemplates/Scripts/vendor/?.lua;'..package.path
-- Fangdango's live preview: every template declares preview over the module's picture,
-- and attaches through ModCore Templates' runtime to the game's wheels, inside MCT's
-- actions canvas lent whole to the preview, with params.preview, hiding and restoring
-- decorations there; on close the canvas returns to its exact place in the HUD and the
-- applied template attaches again on the game's screen.
dofile('ModCoreTemplates/tests/support/lifetimes.lua').install()
local Runtime=require('mc.runtime')
local definitions=dofile('Fangdango/tests/load_templates.lua')()
local category=dofile('ModCoreTemplates/Scripts/categories/player_quickslots.lua')
assert(category.preview and category.preview.lend,'player.quickslots lends its wheels to previews')
local byLocal={}
for _,definition in ipairs(definitions) do
    assert(type(definition.preview)=='table' and definition.preview.background=='images/preview_background.jpg',
        definition.id..' declares the module page preview over Fangdango\'s picture')
    byLocal[definition.localId]=definition
end
local picture=io.open('Fangdango/images/preview_background.jpg','rb')
assert(picture,'the preview picture ships with the module');picture:close()
local manifest=io.open('Fangdango/release-manifest.json'):read('a')
assert(manifest:find('"images/preview_background.jpg": "images/preview_background.jpg"',1,true),
    'and is packaged')

-- The game's HUD, as player.quickslots resolves it: both wheels in the switcher, keys
-- and binding labels as blueprint members, decorations found by name.
local baseWidget=dofile('Fangdango/tests/support/widget.lua')
local placeholder={IsValid=function() return false end}
placeholder.RootWidget=placeholder
local function panelSlot()
    local slot={Padding={Left=0,Top=0,Right=0,Bottom=0},HorizontalAlignment=0,VerticalAlignment=0}
    function slot:IsValid() return true end
    function slot:GetClass() return {GetName=function() return 'OverlaySlot' end} end
    function slot:SetPadding(value) self.Padding=value end
    function slot:SetHorizontalAlignment(value) self.HorizontalAlignment=value end
    function slot:SetVerticalAlignment(value) self.VerticalAlignment=value end
    return slot
end
local function canvasSlot()
    local slot={LayoutData={Offsets={Left=0,Top=0,Right=0,Bottom=0},
        Anchors={Minimum={X=0,Y=0},Maximum={X=0,Y=0}},Alignment={X=0,Y=0}},ZOrder=0,bAutoSize=false}
    function slot:IsValid() return true end
    function slot:GetClass() return {GetName=function() return 'CanvasPanelSlot' end} end
    function slot:SetLayout(value) self.LayoutData=value end
    function slot:SetAutoSize(value) self.bAutoSize=value end
    function slot:SetPosition(value)
        self.position=value
        self.LayoutData.Offsets.Left,self.LayoutData.Offsets.Top=value.X,value.Y
    end
    function slot:SetSize(value)
        self.LayoutData.Offsets.Right,self.LayoutData.Offsets.Bottom=value.X,value.Y
    end
    function slot:SetZOrder(value) self.ZOrder=value end
    return slot
end
local all={}
local function widget(name,class,canvas)
    local w=baseWidget(name,canvas and canvasSlot or panelSlot,{class=class or 'Widget',WidgetTree=placeholder})
    function w:ForceLayoutPrepass() self.prepassed=true end
    function w:AddChildToOverlay(child) return self:AddChild(child) end
    function w:RemoveFromParent() if self.parent then self.parent:RemoveChild(self) end end
    all[#all+1]=w
    return w
end
local hud=widget('HUD','WBP_GameHUD_C')
local tree=widget('HUD.WidgetTree','WidgetTree')
local hudRoot=widget('HUD.Root','CanvasPanel',true)
hud.WidgetTree={RootWidget=hudRoot}
local switcher=widget('HUD.QuickslotsSwitcher','WidgetSwitcher')
switcher.owner=hud
function switcher:GetOuter() return tree end
hudRoot:AddChild(switcher)
hud.WBP_HUD_Quickslots_ChangePrompt=widget('HUD.ChangePrompt')
local wheels={}
for _,kind in ipairs({'ability','consumable'}) do
    local wheel=widget(kind,kind=='ability' and 'WBP_AA_Quickslots_C' or 'WBP_HUD_Quickslots_C')
    wheels[kind]=wheel
    hud[kind=='ability' and 'WBP_AA_Quickslots' or 'WBP_HUD_Quickslots']=wheel
    wheel.RenderTransformPivot={X=0.5,Y=0.5}
    function wheel:GetDesiredSize() return {X=200,Y=160} end
    function wheel:GetChildrenCount() error('UserWidget is not a panel') end
    local box,panel=widget(kind..'Box','SizeBox'),widget(kind..'Panel','Overlay')
    wheel.WidgetTree={RootWidget=box}
    switcher:AddChild(wheel);box:AddChild(panel)
    wheel.cross=widget(kind..'.cross','Image');panel:AddChild(wheel.cross)
    if kind=='ability' then
        wheel.Darken=widget(kind..'.Darken','Image');wheel.Glow=widget(kind..'.Glow','Image')
        panel:AddChild(wheel.Darken);panel:AddChild(wheel.Glow)
    end
    local bindings,bindingsBox,bindingsPanel=widget(kind..'.Bindings','Bindings'),
        widget(kind..'.BindingsBox','SizeBox'),widget(kind..'.BindingsPanel','Overlay')
    function bindings:GetChildrenCount() error('UserWidget is not a panel') end
    bindings.WidgetTree={RootWidget=bindingsBox}
    panel:AddChild(bindings);bindingsBox:AddChild(bindingsPanel)
    wheel[kind=='ability' and 'WBP_AA_Quickslots_Bindings' or 'WBP_HUD_Quickslots_Bindings']=bindings
    wheel.Dpad=widget(kind..'.Dpad','Image');bindingsPanel:AddChild(wheel.Dpad)
    for _,direction in ipairs({'Left','Top','Right','Bottom'}) do
        local button=widget(kind..'.Button'..direction,'QuickslotButton')
        button.RenderTransformPivot={X=0.5,Y=0.5}
        function button:GetDesiredSize() return {X=100,Y=80} end
        if kind=='ability' then button.AbilityWidget={IsValid=function() return true end,IsVisible=function() return true end}
        else button['Displayed Item Asset']={IsValid=function() return true end} end
        panel:AddChild(button);wheel[direction]=button
        local label=widget(kind..'.Label'..direction,'TextBlock')
        label.RenderTransformPivot={X=0.5,Y=0.5}
        function label:GetDesiredSize() return {X=30,Y=20} end
        bindingsPanel:AddChild(label);bindings[direction]=label
    end
end
StaticFindObject=function(path) return {path=path} end
StaticConstructObject=function(class,outer)
    assert(outer==tree,'MCT builds its canvas in the HUD\'s tree')
    return widget('Actions','CanvasPanel',true)
end

local host={}
host.valid=function(value) return value~=nil and value.invalid~=true and value.IsValid~=nil and value:IsValid() end
host.identity=function(value) return value.name end
host.ready=function(value) return host.valid(value) end
host.matches=function(value,selector)
    if selector.object then return value.class=='WidgetSwitcher' end
    return value.class==selector.class:match('([^%.]+)$')
end
host.parent=function() return nil end
host.watch=function() end
host.screen=function() return {width=2560,height=1440,left=0,center=1280,right=2560,bottom=0,middle=720,top=1440,scale=1} end
host.child=function(parent,class)
    for _,candidate in ipairs(parent.children) do if candidate.class==class then return candidate end end
end
host.member=function(parent,path)
    local value=parent
    for key in path:gmatch('[^.]+') do value=value and (key=='@owner' and value.owner or value[key]) end
    return value
end
host.find=function(selector)
    local found={}
    for _,value in ipairs(all) do if host.valid(value) and host.matches(value,selector) then found[#found+1]=value end end
    return found
end
host.subscribe=function() return function() end end
local errors={}
host.onError=function(error) errors[#errors+1]=tostring(error.stage)..': '..tostring(error.message) end

local runtime=Runtime.new(host,{category},definitions,
    {revision=0,controls={group={from=2,to=1},global={{false,false,false,false},{false,false,false,false}}}})
local wheelsId,doubleId=byLocal.Wheels.id,byLocal.DoubleUnderbar.id
runtime:select(category.id,{[wheelsId]={WheelsA='bottom_right',WheelsR='side_by_side',WheelsS='standard',WheelsM=50}})
runtime:start()
local ability,consumable=wheels.ability,wheels.consumable
local actions=ability.parent
assert(actions and actions.name=='Actions' and consumable.parent==actions,table.concat(errors,'; '))
local appliedX=ability.Slot.LayoutData.Offsets.Left
assert(appliedX>1920,'Wheels sits at the right of the game\'s 2560-wide screen')
assert(actions.parent==hudRoot,'the actions canvas sits in the HUD root')
local homeIndex
for index,child in ipairs(hudRoot.children) do if child==actions then homeIndex=index end end
local homeLayout=actions.Slot.LayoutData
local wheelSlots={ability.Slot,consumable.Slot}

-- The page shows a Double Underbar: the actions canvas, wheels inside, moves into the
-- preview panel and the bar lays out there for a 1920x1080 screen.
local stage=widget('PreviewCanvas','CanvasPanel',true)
local screen={width=1920,height=1080,left=0,center=960,right=1920,bottom=0,middle=540,top=1080,scale=1}
local ok,why=runtime:lend(category.id,{destination=stage,template=doubleId,
    overrides={DoubleUnderbarA='bottom_center',DoubleUnderbarK='above',DoubleUnderbarJ=1,
        DoubleUnderbarS='standard',DoubleUnderbarM=0},screen=screen})
assert(ok,tostring(why)..' '..table.concat(errors,'; '))
assert(actions.parent==stage and #stage.children==1,'the actions canvas is lent whole to the preview panel')
assert(ability.parent==actions and consumable.parent==actions and ability.Slot==wheelSlots[1]
    and consumable.Slot==wheelSlots[2],'both wheels stay in their canvas slots')
assert(ability.Slot.LayoutData.Offsets.Left==(1920-200)/2,'the bar centres its wheels on the preview\'s 1920 width')
for _,kind in ipairs({'ability','consumable'}) do
    assert(wheels[kind].cross.opacity==0 and wheels[kind].Dpad.opacity==0,'decorations hide on the lent wheels')
end
assert(ability.Darken.opacity==0 and ability.Glow.opacity==0)
-- A Global key un-merges the Double bar's labels: its far row moves away.
local farRow=consumable.Top.RenderTransform.Translation.Y
assert(runtime:previewEvent(category.id,{name='controls.slots.global',preview=true,
    global={{false,false,false,false},{false,true,false,false}}}))
assert(consumable.Top.RenderTransform.Translation.Y~=farRow,'a preview Global key un-merges the rows')
assert(runtime:previewEvent(category.id,{name='controls.slots.global',preview=true,
    global={{false,false,false,false},{false,false,false,false}}}))
assert(math.abs(consumable.Top.RenderTransform.Translation.Y-farRow)<1e-6,'and clearing it merges them again')
assert(runtime:previewEvent(category.id,{name='controls.group.focus',preview=true,group={from=1,to=2}}))
assert(ability.Top.ColorAndOpacity.A<1 and consumable.Top.ColorAndOpacity.A==1,'focus tints the other wheel')

-- Wheels at another value replaces only the preview attachment.
ok,why=runtime:lend(category.id,{destination=stage,template=wheelsId,
    overrides={WheelsA='bottom_center',WheelsR='overlap',WheelsS='large',WheelsM=0},screen=screen})
assert(ok,why)
assert(actions.parent==stage and ability.parent==actions and ability.cross.opacity==1,'the bar\'s decorations came back with its detach')
assert(ability.RenderTransform.Scale.X==1.1,'Wheels lays out the lent wheels at the page\'s size')

-- Close: the canvas returns and the applied Wheels attaches again on the game's screen.
ok,why=runtime:lend(category.id,nil)
assert(ok,why)
assert(actions.parent==hudRoot and hudRoot.children[homeIndex]==actions and #stage.children==0,
    'the canvas returns to its index in the HUD root')
local layout=actions.Slot.LayoutData
assert(layout.Anchors.Maximum.X==homeLayout.Anchors.Maximum.X and layout.Offsets.Left==homeLayout.Offsets.Left
    and actions.Slot.ZOrder==0,'with its slot')
assert(ability.parent==actions and consumable.parent==actions,'the wheels never left it')
assert(actions.children[1]==ability and actions.children[2]==consumable,'in their order')
assert(ability.Slot.LayoutData.Offsets.Left==appliedX and ability.RenderTransform.Scale.X==1,
    'the applied Wheels is back where it was')
assert(ability.cross.opacity==1 and consumable.Dpad.opacity==1)
assert(#errors==0,table.concat(errors,'; '))
runtime:stop()
assert(ability.parent==switcher and consumable.parent==switcher,'the native switcher gets them back')
print('PASS: Fangdango previews on the wheels in the lent actions canvas with params.preview and returns it')
