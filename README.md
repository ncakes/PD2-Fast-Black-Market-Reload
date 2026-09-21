# Fast Black Market Reload

## Overview

Speeds up the weapon customization UI reloading. A lot. [WeaponFactoryManager Overrides/Forbids Caching](https://modworkshop.net/mod/55051) is compatible and will further boost performance. Just install them both and enjoy better performance. Or keep reading if you are interested in how the mod works.

## Black Market UI Reloading

The weapon customization UI gets reloaded every time you change your weapon. For weapons with a lot of attachments, this becomes extremely slow because:

1. The game evaluates every attachment to determine whether it can be equipped and calculates the resulting weapon stats to display the stat comparison.
2. The game evaluates every attachment to determine whether it can be previewed.

Fast Black Market Reload (FBMR) works by caching the results of function calls made during a reload. The cache is divided into data related to your actual weapon and data related to the preview. When you modify your weapon, the preview does not change, so FBMR reuses all cached data related to the preview. Similarly, when you preview an attachment, your actual weapon does not change, so FBMR reuses all cached data related to the actual weapon.

### Detecting Attachment Changes When Applying/Removing Skins

FBMR efficiently detects whether weapon attachments have been modified when applying or removing a skin based on the vanilla game behavior of the `BlackMarketManager:_set_weapon_cosmetics` and `BlackMarketManager:on_remove_weapon_cosmetics` functions. The current weapon attachments are contained in the `crafted.blueprint` table. If the old skin and new skin are the same (wear/bonus doesn't matter), then the `crafted.blueprint` table is not touched. If the old skin and new skin are different, there are three possible situations:

1. The new skin contains attachments. The `crafted.blueprint` table is replaced with a clone of the new skin attachments.
2. The new skin does not contain attachments, the old skin contains attachments. The `crafted.blueprint` is replaced with a clone of the default weapon attachments.
3. There are no attachments in either skin. The `crafted.blueprint` table is not touched.

When removing a skin, the new skin does not exist and therefore has no attachments. Likewise, when applying a skin to a gun that does not have a skin, there are no old skin attachments.

FBMR will not validate individual attachments in `crafted.blueprint`. If the table reference of `crafted.blueprint` changes, FBMR assumes that the attachments have been modified. Vice versa, if the table reference of `crafted.blueprint` does not change, FBMR assumes that the attachments have not been modified. Optional Skin Attachments v5.0.1 has been updated to comply with this contract.

### Detecting Attachment Changes When Previewing Skins

FBMR detects whether weapon attachments have been modified when previewing a skin based on the vanilla game behavior of the `BlackMarketManager:view_weapon_with_cosmetics` function. The current preview attachments are stored in the `_preview_blueprint.blueprint` table. Two situations can occur when previewing a skin:

1. The new skin contains attachments. The `_preview_blueprint.blueprint` table is replaced with a clone of the new skin attachments.
2. The new skin does not contain attachments. The `_preview_blueprint.blueprint` table is replaced with a clone of the `crafted.blueprint` table (i.e. the current weapon attachments).

Because the table reference of `_preview_blueprint.blueprint` always changes during a preview in the vanilla game, FBMR needs to validate the table to see if the attachments were modified. However, if the table reference of `_preview_blueprint.blueprint` does not change, this indicates that another mod explicitly chose not to replace the `_preview_blueprint.blueprint` table. In this case, FBMR assumes that no attachments were modified. Optional Skin Attachments v5.0.1 complies with this contract.

### Benchmarks

Some benchmarks when modifying a CAR-4 with 14 attachments equipped. Measurements are averaged over 10 runs. The base game times are all roughly the same because the entire weapon customization UI is reloaded after every action.

FBMR provides a moderate improvement when applying weapon attachments, while previewing attachments is more than twice as fast. Actions that do not change the weapon's attachments are substantially faster because FBMR can reuse the cached results from the previous reload.

The WeaponFactoryManager Overrides/Forbids Caching (WFMOFC) mod speeds up the underlying WeaponFactoryManager function calls themselves. The two mods work well together. FBMR avoids making function calls if the results can be reused while WFMOFC makes the necessary calls faster.

| Action                | Base  | FBMR  | WFMOFC | Both  |
|-----------------------|-------|-------|--------|-------|
| Apply Attachment      | 0.461 | 0.369 | 0.307  | 0.264 |
| Preview Attachment    | 0.485 | 0.203 | 0.292  | 0.193 |
| Apply Skin\*          | 0.431 | 0.051 | 0.257  | 0.036 |
| Preview Skin\*        | 0.487 | 0.054 | 0.257  | 0.040 |
| Change Weapon Color\* | 0.479 | 0.066 | 0.319  | 0.060 |
| Change Reticle\*      | 0.525 | 0.082 | 0.102  | 0.064 |

\* No attachment changes.

## Installation

This mod requires [SuperBLT](https://superblt.znix.xyz).

Download `Fast-Black-Market-Reload_<ver>.zip` from the [latest release page](https://github.com/ncakes/PD2-Fast-Black-Market-Reload/releases/latest) and extract the entire contents to your `mods` folder.

```
C:\Program Files (x86)\Steam\steamapps\common\PAYDAY 2\mods
```
