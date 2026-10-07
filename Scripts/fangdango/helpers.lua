local Widget=require('mc').load('widget')
local Objects=require('mc').load('objects')

-- Loaded by path: MCT's Scripts come first on package.path, so a require finds MCT's copy.
local source=assert(debug.getinfo(1,'S').source:match('^@(.+)$'))
local scripts=assert(source:match('^(.*)[/\\][^/\\]+[/\\][^/\\]+$'))
local root=scripts:match('^(.*)[/\\][^/\\]+$') or '.'
local Log=assert(loadfile(scripts..'/vendor/mc_log.lua'))()

local M={}

-- Shared by every Fangdango template. The level comes from log_level.txt in the mod
-- folder; WARN without it.
M.log=Log.new({name='Fangdango',path=root..'/log_level.txt'})
local log=M.log

-- Decorations are named children, not members, so MCT cannot target them.
-- Find them by name and restore them through onCleanup.
local function findChild(root,name)
    if not Objects.valid(root) then return nil end
    local full=Objects.call(root,'GetFullName')
    if type(full)=='string' and full:sub(-#name-1)=='.'..name then return root end
    -- A UserWidget is not a panel; its children hang off its WidgetTree's root.
    -- Other widgets answer WidgetTree with an invalid placeholder, not nil.
    local tree=Widget.property(Widget.property(root,'WidgetTree'),'RootWidget')
    if Objects.valid(tree) then return findChild(tree,name) end
    local count=Objects.call(root,'GetChildrenCount')
    if type(count)~='number' then return nil end
    for index=0,count-1 do
        local found=findChild(Objects.call(root,'GetChildAt',index),name)
        if found then return found end
    end
end

function M.hideDecorations(wheel,names,onCleanup)
    for _,name in ipairs(names) do
        local decoration=findChild(wheel,name)
        if decoration then
            local opacity=Widget.opacity(decoration)
            onCleanup(function()
                if Objects.valid(decoration) then Widget.setOpacity(decoration,opacity) end
            end)
            Widget.setOpacity(decoration,0)
        else
            log.debug('decoration ',name,' not found; left as is')
        end
    end
end

-- controls.group.focus: dim the wheel without focus to settings.focus.dim.
function M.onGroupFocus(params,event,objects)
    local focused=event.group and event.group.to
    if focused~=1 and focused~=2 then return end
    local wheels=objects.wheels
    -- Overlapping Wheels keep the native look.
    local overlap=params.settings.WheelsR==0
    log.trace('focus wheel ',focused,overlap and ' (overlap, no dimming)' or '')
    for index,name in ipairs({'abilities','consumables'}) do
        if wheels and wheels[name] then
            Widget.setOpacity(wheels[name],
                (overlap or focused==index) and 1 or params.settings.focus.dim)
        end
    end
end

-- Relative Placement, shared by Wheels and Bars.
M.PLACEMENTS={[0]='Overlap',[1]='Side by Side',[2]='Stacked',[3]='Perspective'}

-- Size and Margin to Screen Edge, shared by Wheels and Bars.
M.SIZES={[80]='Smaller',[90]='Small',[100]='Standard',[110]='Large',[120]='Larger'}
M.MARGINS={min=0,max=100,step=10,suffix='%'}

-- Margin to Screen Edge, in screen pixels: 8+64*Margin/100, so 0% is 8 and
-- 100% is 72. Without a setting the layout is flush with the edge.
local function marginPixels(percent)
    if percent==nil then return 0 end
    return 8+64*percent/100
end

function M.edge(screen,align,marginPercent,width,height)
    local direction=Widget.relative(align)
    local margin=marginPixels(marginPercent)/(screen.scale or 1)
    return (direction.X+1)*(screen.width-width)/2-direction.X*margin,
        (1-direction.Y)*(screen.height-height)/2+direction.Y*margin
end

function M.pair(settings,screen,ability,consumable)
    local scale=settings.WheelsS/100
    local first={width=ability.width*scale,height=ability.height*scale}
    local second={width=consumable.width*scale,height=consumable.height*scale}
    local direction=Widget.relative(settings.WheelsA)
    local x2,y2=0,0
    if settings.WheelsR==1 then
        if direction.X~=0 then y2=first.height else x2=first.width end
    elseif settings.WheelsR==2 then
        y2=first.height
    elseif settings.WheelsR==3 then
        x2,y2=first.width/2,first.height/2
    end
    local width=math.max(first.width,x2+second.width)
    local height=math.max(first.height,y2+second.height)
    local left,top=M.edge(screen,settings.WheelsA,settings.WheelsM,width,height)
    return {{x=left,y=top,box=ability},{x=left+x2,y=top+y2,box=consumable}},scale
end

function M.anchorGroups(groups,screen,align)
    local minX,minY,maxX,maxY
    for _,group in pairs(groups) do
        minX=math.min(minX or group.x,group.x)
        minY=math.min(minY or group.y,group.y)
        maxX=math.max(maxX or group.x+group.width,group.x+group.width)
        maxY=math.max(maxY or group.y+group.height,group.y+group.height)
    end
    local left,top=M.edge(screen,align,nil,maxX-minX,maxY-minY)
    for _,group in pairs(groups) do
        group.x=left+group.x-minX
        group.y=top+group.y-minY
    end
    return groups
end

return M
