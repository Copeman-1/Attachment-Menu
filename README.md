# attachmenu

A weapon attachment menu for **qb-core** and **ox_inventory**, built with **ox_lib** context menus. Written with the Marko Mods weapon pack in mind, but it works with any weapon that has components defined in ox_inventory.

## Features

- Lists only the weapons currently in the player's inventory
- Groups each weapon's attachments by type (magazines, scopes, muzzles, grips, and so on)
- Click an attachment to install it, click it again to remove it
- Installing a part of the same type as one already fitted replaces it
- Shows which attachments are currently installed
- Updates the weapon live if it is in the player's hands
- Compatibility comes from the game itself (`DoesWeaponTakeWeaponComponent`), so there is no per-weapon attachment list to maintain when you add new weapons
- Optional job restriction and optional item consumption

## Requirements

- [qb-core](https://github.com/qbcore-framework/qb-core)
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_inventory](https://github.com/overextended/ox_inventory)

## Installation

1. Place the `attachmenu` folder in your resources directory.
2. Make sure every attachment is defined under `Components` in `ox_inventory/data/weapons.lua`. The menu reads its attachment list from that file.
3. Add this to `server.cfg`, after the three dependencies:

   ensure attachmenu

## Usage

- Command: `/attachments`
- Export (for your own target or zone script): `exports['attachmenu']:openMenu()`

## Configuration (`config.lua`)

| Option | Default | Description |
|---|---|---|
| `Config.Command` | `'attachments'` | Chat command that opens the menu. Set to `false` to disable. |
| `Config.AllowedJobs` | `{}` | Restrict to jobs, e.g. `{ gunsmith = 0 }` (job = minimum grade). Empty allows everyone. |
| `Config.ConsumeItems` | `false` | If `true`, the attachment item must be in the player's inventory. It is used on install and returned on removal. |
| `Config.CategoryOrder` | see file | Order of the attachment categories. |
| `Config.CategoryLabels` / `Config.CategoryIcons` | see file | Menu titles and Font Awesome icons per attachment type. |

## How it works

Attachments are stored in the weapon's `metadata.components`, the same place ox_inventory uses. The client works out which attachments fit the selected weapon. The server validates every request (job check, ownership, attachment exists) before changing anything.

## Troubleshooting

- **A weapon shows no attachments:** its attachments are probably missing from `Components` in `data/weapons.lua`.
- **Server console error on start:** `attachmenu` reads `ox_inventory/data/weapons.lua` when it starts, so check that the file exists and has no syntax errors.
