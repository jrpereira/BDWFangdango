# Changelog

## v1.3.0

- Requires UE4SS Lua Extensions 1.4.0, ModCore Settings 1.10.0, ModCore Templates 1.10.0
  and ModCore Controls 1.4.0 or newer. UE4SS Lua Extensions replaces the separate
  UE4SS Lua Event Bridge requirement.
- Wheels Plenty's options show directly under the Quickslots picker, like the bars',
  without a "Visual Options" heading.
- Log levels are set with the Log Bridge in UE4SS Lua Extensions: in the Logs section
  of the Extensions tab of the ModCore Settings page, or under `[Levels]` in its `config.ini`.
  Without it, Fangdango logs WARN and above. `log_level.txt` is no longer read.

## v1.2.1

- Requires ModCore Settings 1.9.0, ModCore Templates 1.9.1, ModCore Controls 1.3.0 and
  UE4SS Lua Event Bridge 1.3.0 or newer. ModCore Controls was only recommended before;
  it reports Global keys and drives the inactive-wheel dimming.
- The Quickslot Fangdango page has a live preview: while it is open, the game's own
  wheels move into the preview, over a picture of the game, laid out by the page's
  template at its current values, applied or not. Focus moves between the wheels every
  2 s, and once a loop a Global key shows on one consumable slot. On close the wheels
  return to the HUD with the applied layout. The preview needs a loaded game; from the
  main menu it shows "Load a game to preview your Quickslots" over the picture.
- The inactive wheel dims key by key: each of its keys takes the blue tint and its
  binding label fades to the tint's 50% opacity. The wheel itself is no longer tinted.
  A binding label a layout hides stays hidden.
- Keys with a ModCore Controls Global key stay lit on the inactive wheel, since they
  fire whichever wheel has focus.
- Double bars choose the side of their keys for Key Indicators, as Single bars do.
- Double bars add Merge key indicators when possible, On by default: one key indicator
  per slot sits between the rows while no quickslot has a ModCore Controls Global key.
  Otherwise every key shows its own key indicator on the Key Indicators side, and the
  layout switches as Global keys are assigned or cleared. With key indicators on a side
  facing the other row or column, the far one moves out to leave them room; the one
  nearest the screen edge stays in place.
- Every Wheels and Bars setting has a description in the menu.
- Choices in Align to Screen Edge, Relative Placement, Overall Size, Position, Key
  Indicators and Size stay as you saved them when later versions add choices. Choices
  saved before this version for these pickers reset to their defaults once.

## v1.0.11

- The inactive wheel now also takes a blue tint as it fades to 50% opacity, so it
  reads as inactive over any background. ModCore Templates restores the wheel's
  colour when the layout is removed.
- Requires ModCore Settings 1.6.0 or later and ModCore Templates 1.7.0 or later.

## v1.0.10

- Requires ModCore Settings 1.5.0 or later and ModCore Templates 1.6.0 or later. No change to
  bars, wheels or settings.

## v1.0.9

- Requires ModCore Settings 1.4.0 or later and ModCore Templates 1.5.0 or later.
  Only one of Wheels and the bars is active at a time, as before. No change to bars,
  wheels or settings.

## v1.0.8

- Requires UE4SS Lua Event Bridge 1.2.0 or later, ModCore Settings 1.3.0 or later and
  ModCore Templates 1.4.0 or later. No change to bars, wheels or settings.

## v1.0.7

- Requires ModCore Settings 1.3.1 or later and ModCore Templates 1.4.1 or later. No change to bars, wheels or settings.

## v1.0.6

- Requires ModCore Templates 1.4.0 or later and UE4SS Lua Event Bridge 1.1.0 or later.
  No change to bars, wheels or settings.

## v1.0.5

- Requires ModCore Settings 1.3.0 or later. No change to bars, wheels or settings.

## v1.0.4

- The bars and wheels, including Margin to Screen Edge, keep their place at any
  resolution and UI scale.
- `SETTINGS.md` lists every setting, its options and the `config.ini` key it is saved
  under; it installs beside the README, with a `MOD_SETTINGS.txt` that points to it.

## v1.0.3

- Requires ModCore Settings 1.2.0 or later. ModCore Templates 1.1.0 or later still works.
- No change to bars, wheels or settings.

## v1.0.2

- Bars line up with the game's own HUD. Margin to Screen Edge in the bars now runs
  from -100% to 100% in 5% steps: at 0% (default) a bar lines up with the game's own
  HUD, -100% brings its keys and indicators to the screen edge, and 100% moves it as
  far again the other way. An Underbar at Bottom/Right keeps as far
  from the right edge as from the bottom. Wheels keep their 0% to 100% margin.
- Underbars choose a Position of Bottom/Center or Bottom/Right. Double bars sit
  closer to their shared key indicators, and indicators beside a key keep clear of it.
- The mod is listed in the ModCore collection with its own icon and categories.
- Fix a possible crash after loading a save.
- Requires ModCore Templates 1.1.0 or later and UE4SS Lua Event Bridge 1.0.12 or
  later.
- The UE4SS log shows only warnings and errors by default. Put `DEBUG` or `TRACE` in
  a `log_level.txt` in the mod folder to see layout details.

## v1.0.1

- Rename the mod from Action Fandango to Quickslot Fangdango. The installed
  folder is now `9_ModCore_Fangdango`. Remove the old
  `ActionFandango` folder when updating.
- Rework **Wheels**. The Swap and Distant styles and their X, Y, Size and
  Opacity settings are replaced by:
  - **Align to Screen Edge**: Right/Center, Bottom/Right (default) or
    Bottom/Center.
  - **Relative Placement**: Overlap, Side by Side (default), Stacked or
    Perspective. Overlap shows one wheel at a time in the same place, as Swap
    did, and is the only placement that shows the swap prompt.
  - **Overall Size** and **Margin to Screen Edge**, described below.
  Select Wheels again after updating; earlier Wheels settings are not carried over.
- Add four bar templates that line up the keys of both quickslot wheels and hide
  the wheel decorations around them:
  - **Single Underbar** (bottom center) and **Single Sidebar** (bottom right)
    put both wheels in one row or column, omit empty slots and place Key
    Indicators on any side of the keys.
  - **Double Underbar** and **Double Sidebar** give each wheel its own row or
    column, keep every slot's place and share one key indicator per slot in
    the gap between them. Their Position is Bottom/Center or Bottom/Right for
    the Underbar, Middle/Right or Bottom/Right for the Sidebar.
  - Each wheel's keys run Left, Top, Right, Bottom.
- Size in Wheels and the bars is a picker: Smaller (80%), Small (90%), Standard
  (100%, default), Large (110%) or Larger (120%).
- Margin to Screen Edge in Wheels and the bars runs from 0% (closest to the edge) to
  100%, with 50% as the default.
- Dim the wheel without focus to 70% in Wheels (except Overlap) and the bars,
  following ModCore Controls' focus. The Default wheel
  set in ModCore Controls has focus at the start; without ModCore Controls
  nothing dims.
- Selecting another template restores the game's own layout.
- Template names drop the module suffix (Wheels, Single Underbar, ...); ModCore
  Templates shows the module on the picker's second line.
- Dawnwalker Mod Menu is no longer a direct requirement; ModCore Settings brings
  it in.

## v0.2.1 — Wheels update

- Replace Wheels++ with **Wheels**. Select the new option after updating.
- Add **Swap**, which shows one wheel at a time in the same position.
- Add **Distant**, which shows abilities and consumables together.
- Adjust position, size, and opacity together in Swap or separately in Distant.
- Keep each style's appearance settings when switching between them.
- Add a player guide.

