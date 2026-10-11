package.path='Fangdango/Scripts/?.lua;ModCoreTemplates/Scripts/?.lua;'..package.path
-- MCT keeps objects as UE4SSLuaEventBridge weak handles; use its test double.
local service=dofile('ModCoreTemplates/tests/support/lifetimes.lua').install(function(object) return object.alive end)
local Helpers=require('fangdango.helpers')

-- A widget answers like UE4SS: once freed, any call on a kept wrapper, IsValid included,
-- reads freed memory. Only the bridge's lifetime check may still ask.
-- A real read would crash the game, which no pcall catches: count them instead.
local freedReads=0
local function widget(path,children)
    local w={path=path,children=children or {},opacity=1,alive=true}
    local function live() if not w.alive then freedReads=freedReads+1 end end
    function w:IsValid() live();return true end
    function w:GetFullName() live();return 'Image '..self.path end
    function w:GetChildrenCount() live();return #self.children end
    function w:GetChildAt(i) live();return self.children[i+1] end
    function w:GetRenderOpacity() live();return self.opacity end
    function w:SetRenderOpacity(v) live();self.opacity=v end
    return w
end
local cross=widget('/Game/HUD.WBP_AA_Quickslots_C_0:WidgetTree.cross')
local glow=widget('/Game/HUD.WBP_AA_Quickslots_C_0:WidgetTree.Glow')
local wheel=widget('/Game/HUD.WBP_AA_Quickslots_C_0:WidgetTree.Overlay_0',{cross,widget('/Game/HUD.X:WidgetTree.Left',{glow})})

local cleanups={}
Helpers.hideDecorations(wheel,{'cross','Glow','Dpad'},function(fn) cleanups[#cleanups+1]=fn end)
assert(cross.opacity==0 and glow.opacity==0 and #cleanups==2,'found decorations hide; a missing one is left as is')

-- Detach restores what still lives, never touches a freed decoration, and releases every handle.
glow.alive=false
for _,fn in ipairs(cleanups) do fn() end
assert(cross.opacity==1,'a live decoration gets its opacity back')
assert(freedReads==0,'a freed decoration is never read')
assert(service.held==0,'every handle is released')
print('PASS decorations hide in one walk and restore through weak handles, skipping freed ones')
