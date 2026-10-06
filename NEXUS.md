# Quickslot Fangdango

*Control your Actions. Make them dance.*

Arrange your ability and consumable slots as wheels or bars, with sizes and
screen margins to suit your setup. Combat has enough surprises without your HUD
joining in.

## What you can change

- **Wheels:** choose Side by Side, Stacked, Overlap or Perspective placement.
  Anchor them at Right/Center, Bottom/Right or Bottom/Center.
- **Bars:** line up your slots horizontally at the bottom center or vertically
  at the bottom right. Empty slots are omitted.
- **Key indicators:** put them above or below horizontal bars, or to the left
  or right of vertical bars.
- **Size and margin:** choose from five sizes, from Smaller to Larger, and
  adjust the distance from the screen edge.

Pair Fangdango with **ModCore Controls** to change your bindings and keep the
key indicators current. The inactive wheel dims to show which wheel has focus,
except when you choose Overlap placement.

## Requirements

Install these before Fangdango:

- **UE4SS compatible with your game version.** See the loader links in the
  [Dawnwalker Mod Menu requirements](https://www.nexusmods.com/thebloodofdawnwalker/mods/271).
- [Dawnwalker Mod Menu](https://www.nexusmods.com/thebloodofdawnwalker/mods/271).
- [ModCore Settings](https://www.nexusmods.com/thebloodofdawnwalker/mods/590).
- [ModCore Templates](https://www.nexusmods.com/thebloodofdawnwalker/mods/641),
  **1.0.1 or later**.

**Recommended:** [ModCore Controls](https://www.nexusmods.com/thebloodofdawnwalker/mods/640)
for rebinding, updated key indicators and active-wheel dimming. Fangdango can
change the layout without it, but neither wheel dims to show focus.

## Install and dance

1. Close the game and install the requirements using their instructions.
   UE4SS itself does not install inside the Mods folder.
2. Extract this download so `9_ModCore_Fangdango` sits directly inside the game's
   `ue4ss/Mods` folder. Avoid an extra nested
   `9_ModCore_Fangdango/9_ModCore_Fangdango` folder.
3. Enable the mods in your UE4SS setup or mod manager, then restart the game.
4. Open **Mod Settings → Controls → Visuals** if ModCore Controls is installed,
   or open the **Fangdango** page. In **Quickslots**, choose **Wheels Fangdango**
   or **Bars Fangdango**, then select **Apply**.

Start with **Standard** size and **50%** margin, then adjust to taste. Increasing
the margin moves the layout farther from the screen edge; it does not move it
across that percentage of the screen.

Change your controls through ModCore Controls; let Fangdango handle the choreography.

## Troubleshooting

- **The layout has not changed:** select a Fangdango layout in **Quickslots**
  and choose **Apply**. Check that the required mods are installed and enabled,
  then restart the game.
- **The layout is hard to see:** try **Standard** size and **50%** margin.
- **Neither wheel dims:** check that ModCore Controls is installed and enabled.
  Overlap placement does not dim either wheel.
- **Another mod changes the quickslot HUD:** try disabling it to check for a conflict.

## Updating or removing

Close the game before updating and keep your saved settings.

To return to the game's layout, select **None** in **Quickslots** and choose
**Apply**. To uninstall, close the game, disable or remove
`9_ModCore_Fangdango`, and restart. Keep dependencies used by other mods.
