# Kit Manager for Luanti / Mineclonia

Adds `/kit` for players and `/kitadmin` for admins. Kits are stored persistently in mod storage.

## Install
1. Extract the `kit_manager` folder into the world's `worldmods` directory (or your Luanti mods directory).
2. Enable `kit_manager` for the world.
3. Restart the world/server.

## Commands
- `/kit` — list available kits.
- `/kit <name>` — claim a kit. Kits can be claimed repeatedly.
- `/kitadmin` — open the admin kit manager (requires `server` privilege).
- `/kitcreate <name>` — create a kit from the admin's main inventory (requires `server` privilege).
- `/kitdelete <name>` — delete a kit (requires `server` privilege).

## Make a shulker kit
Mineclonia does not necessarily include vanilla shulker boxes. If your server has a mod that adds a shulker box item, put that item and any other desired items in your main inventory, run `/kitadmin`, enter `shulker`, and click **Save kit from my inventory**. Players can then claim it with `/kit shulker`.

The mod saves the item stacks in the admin's main inventory; it does not capture items stored inside a container item. If no shulker-box item is registered by your game or another mod, add a compatible shulker-box mod first.

If a player's inventory is full, extra kit items are dropped near them. Kit claims are not limited or one-time by default.
