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
