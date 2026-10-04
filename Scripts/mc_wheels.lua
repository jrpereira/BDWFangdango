local MC = require('mc')
local Widget = MC.load('widget')
local Helpers=require('fangdango.helpers')

local template = {
    name='Wheels Fangdango',
    description='Position and size both quickslot wheels on the screen.',

    category='player.quickslots',
    settings={focus={dim=0.7}},
    events={
        ['controls.group.focus']=Helpers.onGroupFocus,
    },
    -- MCT's category lifecycle has already moved both wheels out of the native
    -- switcher into its canvas. This template only owns their layout and the
    -- swap prompt.
    objects={
        wheels={abilities={},consumables={}, properties={'box','slot','position','size','opacity'}},
        change_prompt={properties={'opacity'}}
    },
    menu = {
        {id='Wheels', label='Visual Options', fields={
            {id='.A', label='Align to Screen Edge', values={[5]='Right/Center', [6]='Bottom/Right', [7]='Bottom/Center',}, default=6},
            {id='.R', label='Relative Placement', values={[0]='Overlap',[1]='Side by Side',[2]='Stacked',[3]='Perspective'}, default=1},

            {id='.S', label='Overall Size', values={[80]='Smaller',[90]='Small',[100]='Standard',[110]='Larger'}, default=100},
            {id='.M', label='Margin to Screen Edge',
                values={min=0,max=100,step=10,suffix='%'}, default=0},
        }},
    }
}

template.attach = function(objects, params, original)
    local abilityBox=original.wheels.abilities.box
    local consumableBox=original.wheels.consumables.box

    local positions,scale=Helpers.pair(params.settings,params.screen, abilityBox ,consumableBox)
    local wheels={objects.wheels.abilities,objects.wheels.consumables}
    for w=1,2 do
        local position=positions[w]
        local placed, reason=Widget.canvasPosition(wheels[w], position.box, position.x, position.y, scale)
        assert(placed,reason)
    end
    -- The native prompt describes swapping the switcher's active panel. It is
    -- meaningful only when both wheel layouts deliberately overlap.
    Widget.setOpacity(objects.change_prompt,params.settings.WheelsR==0 and 1 or 0)
    -- A rebuild restores native opacity; apply the current focus.
    template.events['controls.group.focus'](params,
        {name='controls.group.focus',group=params.state.controls.group},objects)
    return original
end

return template
