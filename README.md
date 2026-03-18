# EmpowerSquareAddon

`EmpowerSquare` is a World of Warcraft addon that shows a stage-based square indicator for Evoker empower spells.

## Features

- Displays one square for the current empower stage
- Uses configurable stage colors from a fixed palette
- Prevents duplicate color assignments across stages
- Includes size and position controls for the indicator
- Keeps the label above the square to protect the detection area

## Project Structure

- `EmpowerSquare/EmpowerSquare.toc`
- `EmpowerSquare/EmpowerSquare.lua`
- `scripts/sync_to_wow.sh`

## Local Install Target

The sync script copies files to:

`/Applications/World of Warcraft/_retail_/Interface/AddOns/EmpowerSquare`

## Development

Sync the addon into the WoW AddOns directory:

```bash
./scripts/sync_to_wow.sh
```

Reload the UI in game:

```text
/reload
```

Open the addon settings:

```text
/es
```

## Notes

- The addon is intended for empower-stage visibility rather than generic cast tracking.
- Stage colors are edited in the addon settings UI.
- The project keeps only addon source files and the local sync helper script.
