-- Native quickslot switching is owned by ModCoreControls. This template keeps
-- both wheels in the switcher so its hold binding can show Wheel 2 and restore
-- Wheel 1 on release.
return {
    name='Minima',
    description='Show one native quickslot wheel at a time using ModCoreControls hold switching.',
    targets={'switcher','abilities','consumables'},
    attach=function(_,_,original) return original end,
}
