local MC=require('mc')
local Widget=MC.load('widget')

local styleDescription=table.concat({
    'The origins of Fangdango.',
    'Like many events throughout history, this is also a matter of chance.',
    'Because as lore goes, the makers of this world, enamoured as they were with creating and improving upon their creation, left some nuisances unresolved, and thus, the world adapted.',
    'Fangdango is the result of that strife for more control over your own movements, art and discipline, flow and pure kinetic prowess.',
    'The perfect timing that turns a forgotten scar, into an event that shapes human history.',
    'Here you can choose whether you see both Wheels at a time, or just one. Use Edit controls below to open ModCore Controls for Grouped or Flat keys.',
},' ')
local descriptions={
    Style=styleDescription,
    WheelsX='Move both wheels horizontally from their usual position in Swap mode.',
    WheelsY='Move both wheels vertically from their usual position in Swap mode.',
    WheelsSize='Choose Small, Medium, or Large for the displayed wheel in Swap mode.',
    Wheel1X='Move the ability wheel horizontally in Separate mode.',
    Wheel1Y='Move the ability wheel vertically in Separate mode.',
    Wheel1Size='Choose Small, Medium, or Large for the ability wheel in Separate mode.',
    Wheel2X='Move the consumable wheel horizontally in Separate mode.',
    Wheel2Y='Move the consumable wheel vertically in Separate mode.',
    Wheel2Size='Choose Small, Medium, or Large for the consumable wheel. It displays at 85% of the selected size.',
}
local coord={min=-1000,max=1000,step=10}
local size={[85]='Small',[100]='Medium',[110]='Large'}
local menu = {
    {id='Wheels',label='Wheels',variation={style=0},fields={
        {id='.X',label='X',values=coord,default=0},
        {id='.Y',label='Y',values=coord,default=0},
        {id='.Size',label='Size',values=size,default=100,tab=true},
    }},
    {id='Wheel1',label='Wheel 1',variation={style=1},fields={
        {id='.X',label='X',values=coord,default=0},
        {id='.Y',label='Y',values=coord,default=0},
        {id='.Size',label='Size',values=size,default=100,tab=true},
    }},
    {id='Wheel2',label='Wheel 2',variation={style=1},fields={
        {id='.X',label='X',values=coord,default=0},
        {id='.Y',label='Y',values=coord,default=-360},
        {id='.Size',label='Size',values=size,default=85,tab=true},
    }},
}
for _,group in ipairs(menu) do
    for _,field in ipairs(group.fields) do
        field.description=assert(descriptions[group.id..field.id:sub(2)])
    end
end
local template = {
    name='Wheels',category='player.quickslots',
    objects={'switcher',abilities={properties={'opacity'}},consumables={properties={'opacity'}}},
    description='Swap wheels in place or display both at separate positions.',
    settings={WheelsOpacity=100,Wheel1Opacity=100,Wheel2Opacity=85},
    variations={style={description=styleDescription,
        values={[0]='Swap',[1]='Separate'},default=0}},
    menu=menu,
}

template.attach = function (objects,params,original)
    -- print('[Fangdango] Wheels attach Style=' .. tostring(params.settings.Style))
    local switcher,ability,consumable=objects.switcher,objects.abilities,objects.consumables

    if params.settings.Style==0 then
        Widget.appearance(ability,params.settings,'Wheels',original.abilities.position)
        Widget.appearance(consumable,params.settings,'Wheels',original.consumables.position)
    else
        local owner=MC.parent(switcher)
        assert(switcher:RemoveChild(consumable)~=false, 'could not separate wheel')
        assert(MC.valid(owner:AddChild(consumable)), 'could not attach separate wheel')
        local switcherPosition=Widget.translation(switcher)
        local consumablePosition=original.consumables.position
        Widget.appearance(ability,params.settings,'Wheel1',original.abilities.position)
        switcher:SetActiveWidget(ability)
        Widget.appearance(consumable,params.settings,'Wheel2',{
            X=consumablePosition.X+switcherPosition.X,
            Y=consumablePosition.Y+switcherPosition.Y})
        Widget.setScale(consumable,params.settings.Wheel2Size * 0.85 / 100)
    end
    -- print('[Fangdango] Wheels applied ability '..Widget.readback(ability)
    --     ..'; consumable '..Widget.readback(consumable))
    return original
end

return template
