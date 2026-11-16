local MC = require('mc')
local Widget = MC.load('widget')
local Helpers=require('fangdango.helpers')

local template = {
    id='Wheels',
    label='Wheels Plenty',
    description='Position and size both quickslot wheels on the screen.',
    category='player.quickslots',
    uniqueBy='category',
    settings=Helpers.SETTINGS,
    preview=Helpers.PREVIEW,
    events={
        ['controls.group.focus']=Helpers.onGroupFocus,
        ['controls.slots.global']=Helpers.onGlobalKeys,
    },
    -- MCT's category lifecycle has already moved both wheels out of the native
    -- switcher into its canvas. This template only owns their layout, the swap
    -- prompt and the focus tint of each key and its label.
    objects={
        wheels={abilities={},consumables={}, properties={'box','slot','position','size','opacity'}},
        change_prompt={properties={'opacity'}},
        buttons={abilitySlots=Helpers.BUTTONS.abilitySlots,consumableSlots=Helpers.BUTTONS.consumableSlots,
            properties={'color'}},
        labels={abilityLabels=Helpers.LABELS.abilityLabels,consumableLabels=Helpers.LABELS.consumableLabels,
            properties={'opacity'}},
    },
    menu = {
        {id='Wheels', label='Visual Options', fields={
            {id='.A', label='Align to Screen Edge',
                values=Helpers.edges({'middle_right','bottom_right','bottom_center'}), default='bottom_right',
                description='The screen edge or corner the wheels sit at.'},
            {id='.R', label='Relative Placement', values=Helpers.PLACEMENTS, default='side_by_side',
                description='How the two wheels sit together: overlapping, side by side along the edge, stacked away from it, or offset in perspective.'},

            {id='.S', label='Overall Size', values=Helpers.SIZES, default='standard',
                description='The size of both wheels.'},
            {id='.M', label='Margin to Screen Edge', values=Helpers.MARGINS, default=50,
                description='How far the wheels sit from the screen edge.'},
        }},
    }
}

template.attach = function(objects, params, original)
    local abilityBox=original.wheels.abilities.box
    local consumableBox=original.wheels.consumables.box

    local settings=params.settings
    local positions,scale=Helpers.pair(settings,params.screen, abilityBox ,consumableBox)
    Helpers.log.debug('Wheels: align ',settings.WheelsA,', placement ',settings.WheelsR,
        ', size ',settings.WheelsS,', margin ',settings.WheelsM,'%')
    local wheels={objects.wheels.abilities,objects.wheels.consumables}
    for w=1,2 do
        local position=positions[w]
        local placed, reason=Widget.canvasPosition(wheels[w], position.box, position.x, position.y, scale)
        assert(placed,reason)
    end
    -- The native prompt describes swapping the switcher's active panel. It is
    -- meaningful only when both wheel layouts deliberately overlap.
    Widget.setOpacity(objects.change_prompt,params.settings.WheelsR=='overlap' and 1 or 0)
    -- A rebuild restores native opacity; apply the current focus.
    Helpers.onGroupFocus(params,{name='controls.group.focus',group=params.state.controls.group},objects)
    return original
end

return template
