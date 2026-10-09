# Fast Black Market Reload

## Overview

Speeds up the weapon customization UI reloading. A lot. [WeaponFactoryManager Overrides/Forbids Caching](https://modworkshop.net/mod/55051) is compatible and will further boost performance. Just install them both and enjoy better performance. Or keep reading if you are interested in how the mod works.

## Black Market UI Reloading

The weapon customization UI gets reloaded every time you change your weapon. For weapons with a lot of attachments, this becomes extremely slow because:

1. The game evaluates every attachment to determine whether it can be equipped and calculates the resulting weapon stats ~~to display the stat comparison~~.
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

### Avoiding Unnecessary Weapon Stat Calculations

The vanilla game calls `BlackMarketManager:get_weapon_stats_with_mod` for every possible attachment when loading/reloading the weapon customization UI. This function puts the attachment on your gun and calculates the resulting weapon stats. You would think that the result is used for displaying the weapon stats comparison, but no. PAYDAY re-calculates the displayed stat comparison separately whenever an attachment is selected and the original result is basically unused.

As of v1.1, FBMR skips evaluating `BlackMarketManager:get_weapon_stats_with_mod` during a reload. This substantially improves performance when applying or removing attachments and also the initial loading when entering weapon customization.

### Benchmarks (v1.1)

Some benchmarks when modifying a CAR-4 with 14 attachments equipped. Measurements are averaged over 10 runs. The base game times are all roughly the same because the entire weapon customization UI is reloaded after every action.

FBMR significantly reduces reload times when applying or previewing weapon attachments. Actions that do not change the weapon's attachments are even faster because FBMR can reuse the cached results from the previous reload.

The WeaponFactoryManager Overrides/Forbids Caching (WFMOFC) mod speeds up the underlying WeaponFactoryManager function calls themselves. The two mods work well together. FBMR avoids making function calls if the results can be reused while WFMOFC makes the necessary calls faster.

| Action                | Base  | FBMR  | WFMOFC | Both  |
|-----------------------|-------|-------|--------|-------|
| Apply Attachment      | 0.495 | 0.283 | 0.316  | 0.203 |
| Preview Attachment    | 0.523 | 0.228 | 0.316  | 0.202 |
| Apply Skin\*          | 0.491 | 0.056 | 0.276  | 0.047 |
| Preview Skin\*        | 0.514 | 0.065 | 0.280  | 0.047 |
| Change Weapon Color\* | 0.545 | 0.064 | 0.349  | 0.064 |
| Change Reticle\*      | 0.575 | 0.084 | 0.109  | 0.064 |

\* No attachment changes.

## Installation

This mod requires [SuperBLT](https://superblt.znix.xyz).

Download `Fast-Black-Market-Reload_<ver>.zip` from the [latest release page](https://github.com/ncakes/PD2-Fast-Black-Market-Reload/releases/latest) and extract the entire contents to your `mods` folder.

```
C:\Program Files (x86)\Steam\steamapps\common\PAYDAY 2\mods
```
