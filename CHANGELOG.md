# Changelog

- Rename the mod to Quickslot Fangdango.
- Vertical Bars sits in the bottom-right corner instead of middle right.
- Margin to Screen Edge in Wheels and Bars runs from −100% to 100%, placing the
  layout 8 + 24 × (1 + Margin/100) pixels from the edge: 8 at −100%, 32 at 0%
  (default) and 56 at 100%.
- Bars adds Horizontal Key Indicators (Above, Below) and Vertical Key Indicators
  (Left, Right) to place each binding label; vertical labels sit level with
  their keys. Each shows only for its own Orientation (requires ModCoreTemplates
  field conditions).
- Bars runs each wheel's keys Left, Top, Right, Bottom, instead of Left, Top,
  Bottom, Right.
- Dim the wheel without focus to 70% in Wheels (except Overlap) and Bar, following
  ModCore Controls' focus through ModCoreTemplates. The Default wheel set in
  ModCore Controls has focus at the start; without ModCore Controls nothing dims.
- Bars sizes each wheel's frame to its row again, so keys are no longer laid out
  outside the wheel panel after the host buttons were removed.
- Position the quickslot wheels directly in the ModCoreTemplates canvas, which no
  longer wraps them in host buttons. Clicking a wheel no longer fades between them.
- Register Wheels and Bar individually through `mc.registerTemplate`.
- Rename the installed mod folder to `9_ModCore_Fangdango`.

## 0.2.1 — Wheels update

- Replace Wheels++ with **Wheels**. Select the new option after updating.
- Add **Swap**, which shows one wheel at a time in the same position.
- Add **Separate**, which shows abilities and consumables together.
- Add an **Edit controls** link from Visual Layout to ModCore Controls.
- Adjust position and Small/Medium/Large size together in Swap or separately in Separate.
- Keep wheel opacity internal, with Wheel 2 at 85% opacity and 85% of its chosen size.
- Keep each style's appearance settings when switching between them.

- Add a combined player guide and project metadata.

This update is awaiting in-game verification.
