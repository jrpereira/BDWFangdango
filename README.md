# FANGDANGO

*Control your Actions. Make them dance.*

Arrange your ability and consumable wheels to suit your playstyle. Show both at once or switch between them, with adjustable position, size, and opacity. A little choreography for your combat HUD.

## What you can change

| Setting | What it does |
|---|---|
| **Swap** | Shows one wheel at a time, with both using the same position and size. This is the default. |
| **Separate** | Shows both wheels, with separate positions and size choices. Wheel 2 displays at 85% of its chosen size and opacity. |
| **X / Y** | Moves the wheel horizontally or vertically from its usual position. |
| **Size** | Choose Small (70%), Medium (90%), or Large (110%). Wheel 2 applies an additional 85% scale. |

In Separate mode, **Wheel 1** contains abilities and **Wheel 2** contains
consumables. Each style remembers its settings when you switch to the other.
The mod rearranges the existing wheels; it does not add skills or change their keys.

## Bar

Select **Bar** to arrange each wheel's keys horizontally or vertically. Set Size
(−50% to 150%, default 100%) and Margin to Screen Edge, as in Wheels.

Margin to Screen Edge runs from −100% to 100% in steps of 10%. The distance from
the edge is 8 + 24 × (1 + Margin/100) pixels: 8 at −100%, 32 at 0% (default), and
56 at 100%.
Spacing is fixed at 10% of each preceding button's rendered width or height.
Horizontal places the ability group left of center and the consumable group right
of center. Vertical stacks one column in the bottom-right corner, abilities above
consumables. Horizontal Key Indicators places each key's binding Above (default)
or Below it; Vertical Key Indicators places it Left (default) or Right.
Positive Margin separates the groups; negative Margin overlaps them.

**Tightness** runs from
−25% (half-width pitch) to +50% (full-width pitch). Each wheel's keys run
Left, Top, Right, Bottom. Vertical transposes the same pattern. The two group edges meet at screen center.
Margin is split equally across the two sides. Negative Size mirrors the buttons,
and 0% hides them.

The layout keeps both wheel widgets as containers, reparents their existing
buttons into each wheel's Overlay, and sizes its SizeBox to fit. It sets each
wheel's `background` opacity to zero, leaving its other decoration and buttons
alone. Selecting another layout restores the native containers,
background opacity, button order, transforms and SizeBox overrides.

## Focus

With ModCore Controls installed, Wheels (except Overlap) and Bar dim the wheel
that does not have focus to 70% opacity, so you can see which wheel your slot
keys use. The Default wheel set in ModCore Controls has focus at the start.

## Requirements

- **UE4SS for your Dawnwalker game version.** See the loader links in the
  [Dawnwalker Mod Menu requirements](https://www.nexusmods.com/thebloodofdawnwalker/mods/271).
- [Dawnwalker Mod Menu](https://www.nexusmods.com/thebloodofdawnwalker/mods/271).
- [ModCoreSettings](https://www.nexusmods.com/thebloodofdawnwalker/mods/590).
- [ModCoreTemplates](https://www.nexusmods.com/thebloodofdawnwalker/mods/641),
  with managed template attachment and SizeBox override restoration support.

Wheels in Swap style uses ModCoreControls for hold-based group switching.
Bar and Separate display both wheels and do not use the switcher.

## Installation

1. Close the game completely. Extract the mod download so its `9_ModCore_Fangdango`
   folder sits directly inside the game's `ue4ss/Mods` folder.
2. Download any missing dependencies above and install them with the game closed.
   Use each download's instructions: some archives already include the full
   game-folder path, and UE4SS itself does not install inside `Mods`.
3. Ensure the mods are enabled in your UE4SS setup or mod manager, then restart
   the game. Avoid an extra nested `9_ModCore_Fangdango/9_ModCore_Fangdango` folder.

## First use

Open **Mod Settings** and find **Fangdango**. Select **Wheels**, choose
**Swap** or **Separate** under **Visual Layout**, then adjust the visible settings
and choose **Apply**. Use **Edit controls** directly below Visual Layout to open
the **ModCore Controls** page and configure **Control Layout** (Grouped or Global).
Start with Medium size, then change one setting at a time.
Updating from **Wheels++**? Select **Wheels** again; the older option has been
removed. This Wheels update is awaiting in-game verification.

## If something looks wrong

- **No Fangdango page or Wheels option:** check that the required mods are
  enabled and that your ModCoreTemplates version supports Wheels, then restart.
- **A wheel disappeared:** restore its size to Medium and X/Y to 0.
  In Separate mode, give Wheel 2 a different X value so the wheels do not overlap.
- **A key behaves differently than expected:** Fangdango changes appearance.
  Check the game's controls or your input mod's settings.

## Updating or removing

Close the game before replacing or removing the mod folder. Preserve your saved
settings and any dependency settings when updating. To remove Fangdango,
disable or remove its folder and restart; keep dependencies used by other mods.

See the [changelog](CHANGELOG.md) for changes.

## Template integration

UE4SS loads `Scripts/main.lua`, which calls `M.registerTemplate(...)` for Wheels and
Bar; no template-folder scan or aggregate `mc.lua` is required. Their menu schemas
are separate; Bar does not use Wheels' Swap /
Separate settings or MCC's Grouped / Global Control Layout. The managed
`attach(objects, params, original)`
callback returns the captured original state. MCT restores declared properties on
updates and detach, and restores the previous layout after a failed update.

ModCoreControls changes focus between abilities (group 1) and consumables
(group 2) on group hold and release. Wheels and Bar declare `controls.group.focus`
in their `events` table with `onGroupFocus` from `Scripts/fangdango/helpers.lua`.
MCT calls it as `onGroupFocus(params, event, objects)` once per live attachment,
with the same `params` as `attach`; the dimmed opacity is the template setting
`settings.focus.dim` (0.7). A rebuild restores native opacity, so `attach` invokes
the same handler with the current focus from `params.state`. That focus is empty,
so nothing dims, until ModCore Controls activates its Default wheel.
Bar's declaration and transform are in `Scripts/mc_bars.lua`.

Offline lifecycle tests do not establish live-game acceptance.
