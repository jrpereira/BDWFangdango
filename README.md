# FANGDANGO

*Control your Actions. Make them dance.*

Arrange your ability and consumable wheels to suit your playstyle. Show both at once or switch between them, with adjustable position, size, and opacity. A little choreography for your combat HUD.

## What you can change

| Setting | What it does |
|---|---|
| **Minima** | Keeps the native one-wheel view. ModCoreControls can show Wheel 2 while its group key is held, then return to Wheel 1 on release. |
| **Swap** | Shows one wheel at a time, with both using the same position and size. This is the default. |
| **Separate** | Shows both wheels, with separate positions and size choices. Wheel 2 displays at 85% of its chosen size and opacity. |
| **X / Y** | Moves the wheel horizontally or vertically from its usual position. |
| **Size** | Choose Small (70%), Medium (90%), or Large (110%). Wheel 2 applies an additional 85% scale. |

In Separate mode, **Wheel 1** contains abilities and **Wheel 2** contains
consumables. Each style remembers its settings when you switch to the other.
The mod rearranges the existing wheels; it does not add skills or change their keys.

## Bar

Select **Bar** to place both wheel containers side by side. Set Size
(−50% to 150%, default 100%) and Margin (−100 to 100, default 0).
Spacing is fixed at 10% of each preceding button's rendered width or height.
Positive Margin separates the groups; negative Margin overlaps them.

**Tightness** runs from
−25% (two staggered diamond rows) to +50% (one straight row of slots 1–8).
At −25%, the upper row is 2, 4 | 5, 8 and the lower row is 1, 3 | 6, 7.
The ability box's right edge and consumable box's left edge meet at screen center.
Margin is split equally across the two sides. Negative Size mirrors the buttons,
and 0% hides them.

The layout keeps both wheel widgets as containers, reparents their existing
buttons into each wheel's Overlay, and sizes its SizeBox to fit. It sets each
wheel's `background` opacity to zero, leaving its other decoration and buttons
alone. It leaves the ability and
consumable panels' opacity alone so access-mode dimming can act on each entire
group. Selecting another layout restores the native containers,
background opacity, button order, transforms and SizeBox overrides.

## Requirements

- **UE4SS for your Dawnwalker game version.** See the loader links in the
  [Dawnwalker Mod Menu requirements](https://www.nexusmods.com/thebloodofdawnwalker/mods/271).
- [Dawnwalker Mod Menu](https://www.nexusmods.com/thebloodofdawnwalker/mods/271).
- [ModCoreSettings](https://www.nexusmods.com/thebloodofdawnwalker/mods/590).
- [ModCoreTemplates](https://www.nexusmods.com/thebloodofdawnwalker/mods/641),
  with managed template attachment and SizeBox override restoration support.

Minima and Wheels in Swap style use ModCoreControls for hold-based group
switching. Bar and Separate display both wheels and do not use the switcher.

## Installation

1. Close the game completely. Extract the mod download so its `_ModCore_Fangdango`
   folder sits directly inside the game's `ue4ss/Mods` folder.
2. Download any missing dependencies above and install them with the game closed.
   Use each download's instructions: some archives already include the full
   game-folder path, and UE4SS itself does not install inside `Mods`.
3. Ensure the mods are enabled in your UE4SS setup or mod manager, then restart
   the game. Avoid an extra nested `_ModCore_Fangdango/_ModCore_Fangdango` folder.

## First use

Open **Mod Settings** and find **Fangdango**. Select **Wheels**, choose
**Swap** or **Separate** under **Visual Layout**, then adjust the visible settings
and choose **Apply**. Use **Edit controls** directly below Visual Layout to open
the **ModCore Controls** page and configure **Control Layout** (Grouped or Flat).
Start with Medium size, then change one setting at a time.
Select **Minima** for the native one-wheel layout; configure the Wheel 2 hold
binding in ModCoreControls to switch wheels while the key is held.

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

`Scripts/templates/mc.lua` loads the Minima, Wheels and Bar definitions. Minima
keeps both wheels in the native switcher and lets ModCoreControls handle the hold
binding. Their menu schemas are separate; Bar does not use Wheels' Swap /
Separate settings or MCC's Grouped / Flat Control Layout. The managed
`attach(objects, params, original)`
callback returns the captured original state. MCT restores declared properties on
updates and detach, and restores the previous layout after a failed update.

ModCoreControls changes the native switcher index (ability 0, consumable 1) on
group hold and release. Fangdango does not subscribe to group-focus events.
Bar's declaration and transform are in `Scripts/templates/mc_bars.lua`.

Offline lifecycle tests do not establish live-game acceptance.
