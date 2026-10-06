# QUICKSLOT FANGDANGO

*Control your Actions. Make them dance.*

I made Fangdango because updating your controls should also update what you see.
Your abilities, consumables and key indicators should follow your setup—and sit
where you want them. Combat has enough surprises without your HUD joining in.

Fangdango arranges your four ability slots and four consumable slots in
**The Blood of Dawnwalker**. Pair it with **ModCore Controls** to change their
bindings, keep the key indicators current, and highlight the active wheel.

- **Wheels:** choose Side by Side, Stacked, Overlap or Perspective placement,
  anchored at Right/Center, Bottom/Right or Bottom/Center.
- **Bars:** Underbar, a horizontal bar at the bottom center, or Sidebar, a
  vertical bar at the bottom right. A Single bar lines up both wheels in one
  row or column, omits empty slots and puts key indicators on any side of the
  keys. A Double bar gives each wheel its own row or column, with one key
  indicator per slot between them; a Double Underbar can also sit at the
  bottom right, and a Double Sidebar at the middle of the right edge.
- Choose from five sizes, from Smaller to Larger, and adjust the screen margin.
  With ModCore Controls, the inactive wheel dims, except in Overlap placement.

## Requirements

Install all of these:

- **UE4SS compatible with your game version** and
  [Dawnwalker Mod Menu](https://www.nexusmods.com/thebloodofdawnwalker/mods/271).
- [ModCore Settings](https://www.nexusmods.com/thebloodofdawnwalker/mods/590).
- [ModCore Templates](https://www.nexusmods.com/thebloodofdawnwalker/mods/641)
  **1.0.1 or later**.

Also install [ModCore Controls](https://www.nexusmods.com/thebloodofdawnwalker/mods/640)
for rebinding, updated key indicators and active-wheel dimming. Without it,
Fangdango still changes the layout, but neither wheel dims to show focus.

## Install and dance

1. Close the game and install the requirements using their instructions.
2. Extract Fangdango so `9_ModCore_Fangdango` sits directly inside
   the game's `ue4ss/Mods` folder. Avoid an extra nested
   `9_ModCore_Fangdango/9_ModCore_Fangdango` folder. Enable the mods in your
   UE4SS setup or mod manager and restart the game.
3. Open **Mod Settings › Controls › Visuals** (with ModCore Controls installed)
   or the **Fangdango** page. In the **Quickslots** picker, choose
   **Wheels**, a **Single** or **Double Underbar**, or a **Single** or **Double
   Sidebar**, adjust to taste and select **Apply**.

Change your controls through ModCore Controls; let Fangdango handle the choreography.
Start with **Standard** size and **50%** margin. A larger margin moves the layout
farther from the screen edge; the percentage adjusts the margin, not the layout's
position across the whole screen.

## If the layout does not appear

- Check that a Fangdango layout is selected in **Quickslots**, then select **Apply**.
- Confirm the required mods are installed and enabled, then restart the game.
- If the layout is hard to see, try **Standard** size and **50%** margin.
- If another mod rearranges the quickslot HUD, try disabling it to check for a conflict.

## Updating or removing

Close the game before updating or removing the mod, and keep your saved settings
when updating. To return to the game's layout, select **None** in **Quickslots**
and choose **Apply**. To uninstall, close the game and disable or remove
`9_ModCore_Fangdango`. Keep dependencies used by other mods.

See the [changelog](CHANGELOG.md) for what's new.
