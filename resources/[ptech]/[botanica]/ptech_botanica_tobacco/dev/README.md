# Botanica Tobacco

FiveM resource for the first two Botanica cigarette brands: HOKUTO and ARCHIMEDES.

## Implemented behavior

- Each carton opens into five separate, non-stackable cigarette boxes.
- Each box has ten cigarettes. One cigarette is spent when a smoke starts.
- A disposable lighter has twenty ignitions and is shared by both brands.
- The inherited tobacco shop location sells both brands by the box and carton, plus lighters. Prices are editable defaults copied from the previous tobacco shop setup.
- A cigarette cannot be started without a lighter with a remaining ignition.
- Stress falls by 5 points per second for the first ten minutes of a smoke. It then rises by 1 point per second while the player keeps smoking. Changes go through `nova-stress`, which applies its character modifiers and syncs the HUD.
- Smoking has no progress gauge. Common movement/action controls, death, or resource shutdown interrupt it; interruption does not refund the cigarette or lighter ignition.
- Remaining cigarettes and lighter ignitions are stored on each inventory item's metadata.

## Install

1. Copy this resource to `resources/[p-tech]/[botanica]/ptech_botanica_tobacco`.
2. Merge `install/ox_inventory_items.lua` into the existing `ox_inventory/data/items.lua` table.
3. Start `ox_lib`, `ox_inventory`, `qbx_core`, and `nova-stress` before this resource.
4. Add `ensure ptech_botanica_tobacco` to the server configuration.
5. Give cartons and lighters metadata-free; their contents/charges initialize on use.
6. Add final town-approved item icons to `ox_inventory/web/images/` when available. Concept art is intentionally not included as production inventory art.

## Configuration

Edit `config.lua` to tune shop location/prices, stress values, inventory item IDs, item quantities, animation, and controls that interrupt smoking.

## Notes

- Requires ox_inventory, ox_lib, Qbox (`qbx_core`), and `nova-stress`.
- Stress is changed through `nova-stress` exports so its type modifiers and HUD update are retained.
- Shop prices and inventory entry weights are starter values and should be aligned with the town's item economy.
- The target FiveM server still needs an in-game integration pass for controls, animation, inventory behavior, and stress HUD refresh.
