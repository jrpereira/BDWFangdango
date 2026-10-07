# Changelog

## v1.0.1

- Rename the mod from Action Fandango to Quickslot Fangdango. The installed
  folder is now `9_ModCore_Fangdango` and the source moves to
  [BDWFangdango](https://github.com/jrpereira/BDWFangdango). Remove the old
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
- Margin to Screen Edge in Wheels and the bars runs from 0% to 100%, placing the
  layout 8 + 64 × Margin/100 pixels from the edge: 8 at 0%, 40 at 50%
  (default) and 72 at 100%.
- Dim the wheel without focus to 70% in Wheels (except Overlap) and the bars,
  following ModCore Controls' focus through ModCoreTemplates. The Default wheel
  set in ModCore Controls has focus at the start; without ModCore Controls
  nothing dims.
- The wheels are placed directly in the ModCoreTemplates canvas, and selecting
  another template restores the game's own layout.
- Template names drop the module suffix (Wheels, Single Underbar, ...); ModCore
  Templates shows the module on the picker's second line.
- Register each template individually through `mc.registerTemplate`.
- Dawnwalker Mod Menu is no longer a direct requirement; ModCoreSettings brings
  it in.
- Log through the shared ModCore leveled logger, quiet below warnings by
  default. Put `DEBUG` or `TRACE` in a `log_level.txt` in the mod folder to see
  layout details in the UE4SS log.

## 0.2.1 — Wheels update

- Replace Wheels++ with **Wheels**. Select the new option after updating.
- Add **Swap**, which shows one wheel at a time in the same position.
- Add **Distant**, which shows abilities and consumables together.
- Adjust position, size, and opacity together in Swap or separately in Distant.
- Keep each style's appearance settings when switching between them.

- Add a combined player guide and project metadata.

This update is awaiting in-game verification.
