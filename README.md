# Jumper
Lightweight World of Warcraft addon that counts your jumps per character, lets you print the totals to chat, and manage saved entries via a small AceGUI window.

## Features
- Per-character jump counter stored in SavedVariables (`JumperDB`) keyed by realm and character.
- Ignores jumps while on taxi, flying, swimming, or without full control (avoids false positives).
- Slash command to print your jump total locally or to a chat channel / whisper.
- GUI list with per-character counts, print-to-channel button, and a remove action that deletes a character entry from saved data.

## Slash Commands
- `/jump` or `/jumper` — print your jump count to yourself.
- `/jump <channel>` — send to `say`, `yell`, `party`, `raid`, `guild`, or `officer`.
- `/jump tell <name>` or `/jump whisper <name>` — whisper your count to another player.
- `/jumpgui` or `/jumpergui` — open the AceGUI window showing all characters.

## GUI
- Shows a total row plus per-character rows sorted by highest jumps.
- Buttons per row: **Print** (to currently selected channel) and **Remove** (deletes that character’s saved entry; empty realms are pruned).
- Channel dropdown: choose the chat channel used by the Print buttons.

## Installation
1. Download the Jumper addon.
2. Extract the contents into your World of Warcraft `Interface/AddOns` directory.

## Saved Variables
- Stored in `WTF/Account/<AccountName>/SavedVariables/Jumper.lua` under `JumperDB[realm][character]`.