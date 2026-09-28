local fields = {
    {id='Style', type='picker', group='Style', label='Visual Layout',
        values={0,1}, labels={'Swap','Separate'}, default=0, tab=true, level=2},
    {id='ControlLayoutLink', type='navigation', group='Style', label='Control Layout',
        values={0,1}, labels={'Edit controls','Open'}, default=0, tab=true, level=2,
        linkProvider='ModCoreControls', order=2,
        description='Open ModCore Controls to choose Grouped or Flat and edit its keys.'},

    {id='WheelsX', type='integer', group='Wheels', label='X',
        min=-1000, max=1000, step=10, default=0,
        order=1, visibleWhen='Style', visibleValues={0}},
    {id='WheelsY', type='integer', group='Wheels', label='Y',
        min=-1000, max=1000, step=10, default=0,
        order=2, visibleWhen='Style', visibleValues={0}},
    {id='WheelsSize', type='picker', group='Wheels', label='Size',
        values={70,90,110}, labels={'Small','Medium','Large'}, default=90, tab=true,
        order=3, visibleWhen='Style', visibleValues={0}},

    {id='Wheel1X', type='integer', group='Wheel1', label='X',
        min=-1000, max=1000, step=10, default=0,
        order=1, visibleWhen='Style', visibleValues={1}},
    {id='Wheel1Y', type='integer', group='Wheel1', label='Y',
        min=-1000, max=1000, step=10, default=0,
        order=2, visibleWhen='Style', visibleValues={1}},
    {id='Wheel1Size', type='picker', group='Wheel1', label='Size',
        values={70,90,110}, labels={'Small','Medium','Large'}, default=90, tab=true,
        order=3, visibleWhen='Style', visibleValues={1}},

    {id='Wheel2X', type='integer', group='Wheel2', label='X',
        min=-1000, max=1000, step=10, default=360,
        order=1, visibleWhen='Style', visibleValues={1}},
    {id='Wheel2Y', type='integer', group='Wheel2', label='Y',
        min=-1000, max=1000, step=10, default=0,
        order=2, visibleWhen='Style', visibleValues={1}},
    {id='Wheel2Size', type='picker', group='Wheel2', label='Size',
        values={70,90,110}, labels={'Small','Medium','Large'}, default=90, tab=true,
        order=3, visibleWhen='Style', visibleValues={1}},
}
local styleDescription=table.concat({
    'The origins of Fangdango.',
    'Like many events throughout history, this is also a matter of chance.',
    'Because as lore goes, the makers of this world, enhamoured as they were with creating and improving upon their creation, left some nuisances unresolved, and thus, the world adapted.',
    'Fangdango is the result of that strife for more control over your own movements, art and discipline, flow and pure kinetic prowess.',
    'The perfect timing that turns a forgotten scar, into an event that shapes human history.',
    'Here you can choose whether you see both Wheels at a time, or just one. Use Edit controls below to open ModCore Controls for Grouped or Flat keys.',
},' ')
local descriptions={
    Style=styleDescription,
    ControlLayoutLink='Open ModCore Controls to choose Grouped or Flat and edit its keys.',
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
for _,field in ipairs(fields) do field.description=assert(descriptions[field.id]) end
local template = {
    name='Wheels', version='0.2.1',
    objects={'switcher',abilities={properties={'opacity'}},consumables={properties={'opacity'}}},
    description='Swap wheels in place or display both at separate positions.',
    settings={WheelsOpacity=100,Wheel1Opacity=100,Wheel2Opacity=85},
    menu={ enabled=true,fields=fields,
      groups={
        {id='Style',label='Visual Layout',heading=false,order=1},
        {id='Wheels',label='Wheels',order=2},
        {id='Wheel1',label='Wheel 1',order=3},
        {id='Wheel2',label='Wheel 2',order=4},
    }},
}

return template
