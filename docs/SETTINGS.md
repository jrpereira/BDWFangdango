# Quickslot Fangdango settings

Quickslot Fangdango does not ship a `mod_settings.ini`. Compatibility with `mod_settings.ini` is implemented by ModCore Templates.

Templates are reusable components. A module that uses a template gains the template's settings and shows them as its own. When the game starts, ModCore Templates collects the settings of every installed template and ModCore Settings builds the menu pages from them, so the pages always match what is installed.

Change these settings in the mod menu and press Apply. Each template below names the `config.ini` that keeps its values, in a section of its own named after the module and the template, with the keys and numbers listed. The active template of a category is saved under `[Templates]`. A saved value that is not valid falls back to its default.

## Templates in this module

### Wheels Plenty

Position and size both quickslot wheels on the screen.

- **Category:** Player Quickslots. The settings appear in the Controls page's Visuals section, and on this module's page.
- **Turn on:** choose Wheels Plenty in the Player Quickslots template picker (`[Templates] PlayerQuickslots=Fangdango_Wheels`). Only one template of this category is active at a time.
- **Saved in:** `3_ModCore_Templates/Scripts/cache/config.ini`, section `[Fangdango.Wheels]`.

| Setting | Options | Default | Key |
|---|---|---|---|
| Align to Screen Edge | Middle/Right (`middle_right`), Bottom/Right (`bottom_right`), Bottom/Center (`bottom_center`) | Bottom/Right | `WheelsA` |
| Relative Placement | Overlap (`overlap`), Side by Side (`side_by_side`), Stacked (`stacked`), Perspective (`perspective`) | Side by Side | `WheelsR` |
| Overall Size | Smaller (`smaller`), Small (`small`), Standard (`standard`), Large (`large`), Larger (`larger`) | Standard | `WheelsS` |
| Margin to Screen Edge | 0% to 100%, in steps of 10 | 50% | `WheelsM` |

### Single Underbar

Arrange quickslot keys in one row.

- **Category:** Player Quickslots. The settings appear in the Controls page's Visuals section, and on this module's page.
- **Turn on:** choose Single Underbar in the Player Quickslots template picker (`[Templates] PlayerQuickslots=Fangdango_SingleUnderbar`). Only one template of this category is active at a time.
- **Saved in:** `3_ModCore_Templates/Scripts/cache/config.ini`, section `[Fangdango.SingleUnderbar]`.

| Setting | Options | Default | Key |
|---|---|---|---|
| Position | Bottom/Right (`bottom_right`), Bottom/Center (`bottom_center`) | Bottom/Center | `SingleUnderbarA` |
| Key Indicators | Above (`above`), Below (`below`), Left (`left`), Right (`right`) | Above | `SingleUnderbarK` |
| Size | Smaller (`smaller`), Small (`small`), Standard (`standard`), Large (`large`), Larger (`larger`) | Standard | `SingleUnderbarS` |
| Margin to Screen Edge | -100% to 100%, in steps of 5 | 0% | `SingleUnderbarM` |

### Double Underbar

Arrange quickslot keys in two rows.

- **Category:** Player Quickslots. The settings appear in the Controls page's Visuals section, and on this module's page.
- **Turn on:** choose Double Underbar in the Player Quickslots template picker (`[Templates] PlayerQuickslots=Fangdango_DoubleUnderbar`). Only one template of this category is active at a time.
- **Saved in:** `3_ModCore_Templates/Scripts/cache/config.ini`, section `[Fangdango.DoubleUnderbar]`.

| Setting | Options | Default | Key |
|---|---|---|---|
| Position | Bottom/Right (`bottom_right`), Bottom/Center (`bottom_center`) | Bottom/Center | `DoubleUnderbarA` |
| Key Indicators | Above (`above`), Below (`below`), Left (`left`), Right (`right`) | Above | `DoubleUnderbarK` |
| Merge key indicators when possible | Off (`0`), On (`1`) | On | `DoubleUnderbarJ` |
| Size | Smaller (`smaller`), Small (`small`), Standard (`standard`), Large (`large`), Larger (`larger`) | Standard | `DoubleUnderbarS` |
| Margin to Screen Edge | -100% to 100%, in steps of 5 | 0% | `DoubleUnderbarM` |

### Single Sidebar

Arrange quickslot keys in one column.

- **Category:** Player Quickslots. The settings appear in the Controls page's Visuals section, and on this module's page.
- **Turn on:** choose Single Sidebar in the Player Quickslots template picker (`[Templates] PlayerQuickslots=Fangdango_SingleSidebar`). Only one template of this category is active at a time.
- **Saved in:** `3_ModCore_Templates/Scripts/cache/config.ini`, section `[Fangdango.SingleSidebar]`.

| Setting | Options | Default | Key |
|---|---|---|---|
| Key Indicators | Left (`left`), Right (`right`), Above (`above`), Below (`below`) | Left | `SingleSidebarK` |
| Size | Smaller (`smaller`), Small (`small`), Standard (`standard`), Large (`large`), Larger (`larger`) | Standard | `SingleSidebarS` |
| Margin to Screen Edge | -100% to 100%, in steps of 5 | 0% | `SingleSidebarM` |

### Double Sidebar

Arrange quickslot keys in two columns.

- **Category:** Player Quickslots. The settings appear in the Controls page's Visuals section, and on this module's page.
- **Turn on:** choose Double Sidebar in the Player Quickslots template picker (`[Templates] PlayerQuickslots=Fangdango_DoubleSidebar`). Only one template of this category is active at a time.
- **Saved in:** `3_ModCore_Templates/Scripts/cache/config.ini`, section `[Fangdango.DoubleSidebar]`.

| Setting | Options | Default | Key |
|---|---|---|---|
| Position | Middle/Right (`middle_right`), Bottom/Right (`bottom_right`) | Bottom/Right | `DoubleSidebarA` |
| Key Indicators | Left (`left`), Right (`right`), Above (`above`), Below (`below`) | Left | `DoubleSidebarK` |
| Merge key indicators when possible | Off (`0`), On (`1`) | On | `DoubleSidebarJ` |
| Size | Smaller (`smaller`), Small (`small`), Standard (`standard`), Large (`large`), Larger (`larger`) | Standard | `DoubleSidebarS` |
| Margin to Screen Edge | -100% to 100%, in steps of 5 | 0% | `DoubleSidebarM` |
