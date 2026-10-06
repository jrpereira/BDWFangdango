local Widget=require('mc').load('widget')

local M={}

-- controls.group.focus: dim the wheel without focus to settings.focus.dim.
function M.onGroupFocus(params,event,objects)
    local focused=event.group and event.group.to
    if focused~=1 and focused~=2 then return end
    local wheels=objects.wheels
    -- Overlapping Wheels keep the native look.
    local overlap=params.settings.WheelsR==0
    for index,name in ipairs({'abilities','consumables'}) do
        if wheels and wheels[name] then
            Widget.setOpacity(wheels[name],
                (overlap or focused==index) and 1 or params.settings.focus.dim)
        end
    end
end

-- Margin to Screen Edge, in screen pixels: a fixed 8 plus 24 scaled by the
-- setting, so -100% is 8, 0% is 32 and 100% is 56. Without a setting the
-- layout is flush with the edge.
local function marginPixels(percent)
    if percent==nil then return 0 end
    return 8+24*(1+percent/100)
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
