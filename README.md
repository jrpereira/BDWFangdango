# QUICKSLOT FANGDANGO

*Control your Actions. Make them dance.*

I made Fangdango because updating your controls should also update what you see.
Your abilities, consumables and key indicators should follow your setup—and sit
where you want them. Combat has enough surprises without your HUD joining in.

Fangdango arranges your four ability slots and four consumable slots in
**The Blood of Dawnwalker**. Together with **ModCore Controls**, which changes their
bindings and keeps the key indicators current, it highlights the active wheel.

- **Wheels:** choose Side by Side, Stacked, Overlap or Perspective placement,
  anchored at Middle/Right, Bottom/Right or Bottom/Center. Side by Side runs
  along the screen edge and Stacked away from it.
- **Bars:** Underbar, a horizontal bar at the bottom center, or Sidebar, a
  vertical bar at the bottom right. A Single bar lines up both wheels in one
  row or column and omits empty slots. A Double bar gives each wheel its own
  row or column. Every bar puts key indicators on the side of the keys you
  choose. A Double bar can instead merge them into one key indicator per slot
  between its rows or columns, while no quickslot has a ModCore Controls Global
  key.
  Underbars can also sit at the bottom right,
  and a Double Sidebar at the middle of the right edge.
- Choose from five sizes, from Smaller to Larger, and adjust the screen margin.
  At 0% a bar lines up with the game's own HUD.
- The inactive wheel's keys dim with a blue tint and their binding labels fade,
  except in Overlap placement. Keys with a ModCore Controls Global key stay lit.
- The Quickslot Fangdango page previews your layout live on the game's own wheels
  as you change it, before you apply it.

## Requirements

Install all of these:

- **UE4SS compatible with your game version** and
  [Dawnwalker Mod Menu](https://www.nexusmods.com/thebloodofdawnwalker/mods/271).
- [ModCore Settings](https://www.nexusmods.com/thebloodofdawnwalker/mods/590)
  **1.9.0 or later**.
- [ModCore Templates](https://www.nexusmods.com/thebloodofdawnwalker/mods/641)
  **1.9.1 or later**.
- [UE4SS Lua Event Bridge](https://www.nexusmods.com/thebloodofdawnwalker/mods/526)
  **1.3.0 or later**, which ModCore Templates also requires.
- [ModCore Controls](https://www.nexusmods.com/thebloodofdawnwalker/mods/640)
  **1.3.0 or later**, for rebinding, updated key indicators and active-wheel dimming.

## Install and dance

1. Close the game and install the requirements using their instructions.
2. Extract Fangdango so `9_ModCore_Fangdango` sits directly inside
   the game's `ue4ss/Mods` folder. Avoid an extra nested
   `9_ModCore_Fangdango/9_ModCore_Fangdango` folder. Enable the mods in your
   UE4SS setup or mod manager and restart the game.
3. Open **Mod Settings › Controls › Visuals** or the **Quickslot Fangdango**
   page. In the **Quickslots** picker, choose
   **Wheels Plenty**, a **Single** or **Double Underbar**, or a **Single** or
   **Double Sidebar**, adjust to taste and select **Apply**.

Every setting, its options and the `config.ini` key it is saved under are listed
in `SETTINGS.md`, next to this file in the installed mod.

Change your controls through ModCore Controls; let Fangdango handle the choreography.
Start with **Standard** size and the default margin: **50%** for Wheels, **0%**
for bars. A larger margin moves the layout farther from the screen edge; a bar's
-100% brings it to the edge.

## If the layout does not appear

- Check that a Fangdango layout is selected in **Quickslots**, then select **Apply**.
- Confirm the required mods, including UE4SS Lua Event Bridge, are installed and
  enabled, then restart the game.
- If the layout is hard to see, try **Standard** size and the default margin.
- If another mod rearranges the quickslot HUD, try disabling it to check for a conflict.
- To see what the layout decided, install the UE4SS Lua Log Bridge, set Fangdango to
  Debug on its Logs page and check `UE4SS.log`.

## Updating or removing

Close the game before updating or removing the mod, and keep your saved settings
when updating. To return to the game's layout, select **None** in **Quickslots**
and choose **Apply**. To uninstall, close the game and disable or remove
`9_ModCore_Fangdango`. Keep dependencies used by other mods.

See the [changelog](CHANGELOG.md) for what's new.
