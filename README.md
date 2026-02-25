# Jumper

## Overview
Lightweight addon for World of Warcraft that implements a jump counter with persistent tracking per character and a simple AceGUI window for overview and management.

## Features
- Per-character jump counter that persists across sessions.
- Filters jumps while on taxi, flying, swimming, or without full control.
- Slash command to print locally, to a chat channel, or via whisper.
- GUI with per-character rows: print-to-channel and remove (deletes the saved entry; empty realms are pruned).
- Class-colored names in the GUI with a toggle (on by default).
- Scroll position is preserved when refreshing after removals.

## Slash Commands
- `/jump` or `/jumper` — print your jump count to yourself.
- `/jump <channel>` — send to `say`, `yell`, `party`, `raid`, `guild`, or `officer`.
- `/jump tell <name>` or `/jump whisper <name>` — whisper your count to another player.
- `/jumpgui` or `/jumpergui` — open the AceGUI window listing all characters.

## GUI
- Sorted list showing total and per-character counts.
- Buttons: **Print** uses the selected channel; **Remove** deletes that character’s saved entry.
- Controls: channel dropdown plus a “Show class colors” checkbox (enabled by default).

## Installation
1. Download the Jumper addon.
2. Extract the contents into your World of Warcraft `Interface/AddOns` directory.

## Saved Variables
- File: `WTF/Account/<AccountName>/SavedVariables/Jumper.lua`
- Structure: `JumperDB[realm][character] = { count = number, class = classToken }` (older numeric entries are migrated automatically).