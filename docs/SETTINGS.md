# Quickslot Fangdango settings

Quickslot Fangdango does not ship a `mod_settings.ini`. Compatibility with `mod_settings.ini` is implemented by ModCore Templates.

Templates are reusable components. A module that uses a template gains the template's settings and shows them as its own. When the game starts, ModCore Templates collects the settings of every installed template and ModCore Settings builds the menu pages from them, so the pages always match what is installed.

Change these settings in the mod menu and press Apply. Each template below names the `config.ini` that keeps its values, in the `[Templates]` section, with the keys and numbers listed. A saved value that is not valid falls back to its default.

## Templates in this module

### Wheels Plenty

Position and size both quickslot wheels on the screen.

- **Category:** Player Quickslots. The settings appear in the Controls page's Visuals section, and on this module's page.
- **Turn on:** choose Wheels Plenty in the Player Quickslots template picker (`MCT_Template`). Only one template of this category is active at a time. The picker's numbers depend on which templates are installed, so choose it in the menu.
- **Saved in:** `3_ModCore_Templates/Scripts/cache/config.ini`, section `[Templates]`.

#### Visual Options

| Setting | Options | Default | Key |
|---|---|---|---|
| Align to Screen Edge | Right/Center (`5`), Bottom/Right (`6`), Bottom/Center (`7`) | Bottom/Right | `MCT_Fangdango_Wheels_WheelsA` |
| Relative Placement | Overlap (`0`), Side by Side (`1`), Stacked (`2`), Perspective (`3`) | Side by Side | `MCT_Fangdango_Wheels_WheelsR` |
| Overall Size | Smaller (`80`), Small (`90`), Standard (`100`), Large (`110`), Larger (`120`) | Standard | `MCT_Fangdango_Wheels_WheelsS` |
| Margin to Screen Edge | 0% to 100%, in steps of 10 | 50% | `MCT_Fangdango_Wheels_WheelsM` |

### Single Underbar

Arrange quickslot keys in one row.

- **Category:** Player Quickslots. The settings appear in the Controls page's Visuals section, and on this module's page.
- **Turn on:** choose Single Underbar in the Player Quickslots template picker (`MCT_Template`). Only one template of this category is active at a time. The picker's numbers depend on which templates are installed, so choose it in the menu.
- **Saved in:** `3_ModCore_Templates/Scripts/cache/config.ini`, section `[Templates]`.

| Setting | Options | Default | Key |
|---|---|---|---|
| Position | Bottom/Right (`6`), Bottom/Center (`7`) | Bottom/Center | `MCT_Fangdango_SingleUnderbar_SingleUnderbarA` |
| Key Indicators | Above (`0`), Below (`1`), Left (`2`), Right (`3`) | Above | `MCT_Fangdango_SingleUnderbar_SingleUnderbarK` |
| Size | Smaller (`80`), Small (`90`), Standard (`100`), Large (`110`), Larger (`120`) | Standard | `MCT_Fangdango_SingleUnderbar_SingleUnderbarS` |
| Margin to Screen Edge | -100% to 100%, in steps of 5 | 0% | `MCT_Fangdango_SingleUnderbar_SingleUnderbarM` |

### Double Underbar

Arrange quickslot keys in two rows.

- **Category:** Player Quickslots. The settings appear in the Controls page's Visuals section, and on this module's page.
- **Turn on:** choose Double Underbar in the Player Quickslots template picker (`MCT_Template`). Only one template of this category is active at a time. The picker's numbers depend on which templates are installed, so choose it in the menu.
- **Saved in:** `3_ModCore_Templates/Scripts/cache/config.ini`, section `[Templates]`.

| Setting | Options | Default | Key |
|---|---|---|---|
| Position | Bottom/Right (`6`), Bottom/Center (`7`) | Bottom/Center | `MCT_Fangdango_DoubleUnderbar_DoubleUnderbarA` |
| Size | Smaller (`80`), Small (`90`), Standard (`100`), Large (`110`), Larger (`120`) | Standard | `MCT_Fangdango_DoubleUnderbar_DoubleUnderbarS` |
| Margin to Screen Edge | -100% to 100%, in steps of 5 | 0% | `MCT_Fangdango_DoubleUnderbar_DoubleUnderbarM` |

### Single Sidebar

Arrange quickslot keys in one column.

- **Category:** Player Quickslots. The settings appear in the Controls page's Visuals section, and on this module's page.
- **Turn on:** choose Single Sidebar in the Player Quickslots template picker (`MCT_Template`). Only one template of this category is active at a time. The picker's numbers depend on which templates are installed, so choose it in the menu.
- **Saved in:** `3_ModCore_Templates/Scripts/cache/config.ini`, section `[Templates]`.

| Setting | Options | Default | Key |
|---|---|---|---|
| Key Indicators | Left (`0`), Right (`1`), Above (`2`), Below (`3`) | Left | `MCT_Fangdango_SingleSidebar_SingleSidebarK` |
| Size | Smaller (`80`), Small (`90`), Standard (`100`), Large (`110`), Larger (`120`) | Standard | `MCT_Fangdango_SingleSidebar_SingleSidebarS` |
| Margin to Screen Edge | -100% to 100%, in steps of 5 | 0% | `MCT_Fangdango_SingleSidebar_SingleSidebarM` |

### Double Sidebar

Arrange quickslot keys in two columns.

- **Category:** Player Quickslots. The settings appear in the Controls page's Visuals section, and on this module's page.
- **Turn on:** choose Double Sidebar in the Player Quickslots template picker (`MCT_Template`). Only one template of this category is active at a time. The picker's numbers depend on which templates are installed, so choose it in the menu.
- **Saved in:** `3_ModCore_Templates/Scripts/cache/config.ini`, section `[Templates]`.

| Setting | Options | Default | Key |
|---|---|---|---|
| Position | Middle/Right (`5`), Bottom/Right (`6`) | Bottom/Right | `MCT_Fangdango_DoubleSidebar_DoubleSidebarA` |
| Size | Smaller (`80`), Small (`90`), Standard (`100`), Large (`110`), Larger (`120`) | Standard | `MCT_Fangdango_DoubleSidebar_DoubleSidebarS` |
| Margin to Screen Edge | -100% to 100%, in steps of 5 | 0% | `MCT_Fangdango_DoubleSidebar_DoubleSidebarM` |
