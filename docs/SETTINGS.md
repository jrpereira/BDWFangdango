# Quickslot Fangdango settings

Quickslot Fangdango does not ship a `mod_settings.ini`. Compatibility with `mod_settings.ini` is implemented by ModCore Templates.

Templates are reusable components. A module that uses a template gains the template's settings and shows them as its own. When the game starts, ModCore Templates collects the settings of every installed template and ModCore Settings builds the menu pages from them, so the pages always match what is installed.

Change these settings in the mod menu and press Apply. Each template below names the `config.ini` that keeps its values, in the `[Templates]` section, with the keys and numbers listed. A saved value that is not valid falls back to its default.

## Templates in this module

### Wheels Plenty

Position and size both quickslot wheels on the screen.

- **Category:** Player Quickslots. The settings appear in the Controls page's Visuals section, and on this module's page.
- **Turn on:** choose Wheels Plenty in the Player Quickslots template picker (`MCT_Template=Fangdango_Wheels`). Only one template of this category is active at a time.
- **Saved in:** `3_ModCore_Templates/Scripts/cache/config.ini`, section `[Templates]`.

#### Visual Options

| Setting | Options | Default | Key |
|---|---|---|---|
| Align to Screen Edge | Middle/Right (`middle_right`), Bottom/Right (`bottom_right`), Bottom/Center (`bottom_center`) | Bottom/Right | `MCT_Fangdango_Wheels_WheelsA` |
| Relative Placement | Overlap (`overlap`), Side by Side (`side_by_side`), Stacked (`stacked`), Perspective (`perspective`) | Side by Side | `MCT_Fangdango_Wheels_WheelsR` |
| Overall Size | Smaller (`smaller`), Small (`small`), Standard (`standard`), Large (`large`), Larger (`larger`) | Standard | `MCT_Fangdango_Wheels_WheelsS` |
| Margin to Screen Edge | 0% to 100%, in steps of 10 | 50% | `MCT_Fangdango_Wheels_WheelsM` |

### Single Underbar

Arrange quickslot keys in one row.

- **Category:** Player Quickslots. The settings appear in the Controls page's Visuals section, and on this module's page.
- **Turn on:** choose Single Underbar in the Player Quickslots template picker (`MCT_Template=Fangdango_SingleUnderbar`). Only one template of this category is active at a time.
- **Saved in:** `3_ModCore_Templates/Scripts/cache/config.ini`, section `[Templates]`.

| Setting | Options | Default | Key |
|---|---|---|---|
| Position | Bottom/Right (`bottom_right`), Bottom/Center (`bottom_center`) | Bottom/Center | `MCT_Fangdango_SingleUnderbar_SingleUnderbarA` |
| Key Indicators | Above (`above`), Below (`below`), Left (`left`), Right (`right`) | Above | `MCT_Fangdango_SingleUnderbar_SingleUnderbarK` |
| Size | Smaller (`smaller`), Small (`small`), Standard (`standard`), Large (`large`), Larger (`larger`) | Standard | `MCT_Fangdango_SingleUnderbar_SingleUnderbarS` |
| Margin to Screen Edge | -100% to 100%, in steps of 5 | 0% | `MCT_Fangdango_SingleUnderbar_SingleUnderbarM` |

### Double Underbar

Arrange quickslot keys in two rows.

- **Category:** Player Quickslots. The settings appear in the Controls page's Visuals section, and on this module's page.
- **Turn on:** choose Double Underbar in the Player Quickslots template picker (`MCT_Template=Fangdango_DoubleUnderbar`). Only one template of this category is active at a time.
- **Saved in:** `3_ModCore_Templates/Scripts/cache/config.ini`, section `[Templates]`.

| Setting | Options | Default | Key |
|---|---|---|---|
| Position | Bottom/Right (`bottom_right`), Bottom/Center (`bottom_center`) | Bottom/Center | `MCT_Fangdango_DoubleUnderbar_DoubleUnderbarA` |
| Size | Smaller (`smaller`), Small (`small`), Standard (`standard`), Large (`large`), Larger (`larger`) | Standard | `MCT_Fangdango_DoubleUnderbar_DoubleUnderbarS` |
| Margin to Screen Edge | -100% to 100%, in steps of 5 | 0% | `MCT_Fangdango_DoubleUnderbar_DoubleUnderbarM` |

### Single Sidebar

Arrange quickslot keys in one column.

- **Category:** Player Quickslots. The settings appear in the Controls page's Visuals section, and on this module's page.
- **Turn on:** choose Single Sidebar in the Player Quickslots template picker (`MCT_Template=Fangdango_SingleSidebar`). Only one template of this category is active at a time.
- **Saved in:** `3_ModCore_Templates/Scripts/cache/config.ini`, section `[Templates]`.

| Setting | Options | Default | Key |
|---|---|---|---|
| Key Indicators | Left (`left`), Right (`right`), Above (`above`), Below (`below`) | Left | `MCT_Fangdango_SingleSidebar_SingleSidebarK` |
| Size | Smaller (`smaller`), Small (`small`), Standard (`standard`), Large (`large`), Larger (`larger`) | Standard | `MCT_Fangdango_SingleSidebar_SingleSidebarS` |
| Margin to Screen Edge | -100% to 100%, in steps of 5 | 0% | `MCT_Fangdango_SingleSidebar_SingleSidebarM` |

### Double Sidebar

Arrange quickslot keys in two columns.

- **Category:** Player Quickslots. The settings appear in the Controls page's Visuals section, and on this module's page.
- **Turn on:** choose Double Sidebar in the Player Quickslots template picker (`MCT_Template=Fangdango_DoubleSidebar`). Only one template of this category is active at a time.
- **Saved in:** `3_ModCore_Templates/Scripts/cache/config.ini`, section `[Templates]`.

| Setting | Options | Default | Key |
|---|---|---|---|
| Position | Middle/Right (`middle_right`), Bottom/Right (`bottom_right`) | Bottom/Right | `MCT_Fangdango_DoubleSidebar_DoubleSidebarA` |
| Size | Smaller (`smaller`), Small (`small`), Standard (`standard`), Large (`large`), Larger (`larger`) | Standard | `MCT_Fangdango_DoubleSidebar_DoubleSidebarS` |
| Margin to Screen Edge | -100% to 100%, in steps of 5 | 0% | `MCT_Fangdango_DoubleSidebar_DoubleSidebarM` |
