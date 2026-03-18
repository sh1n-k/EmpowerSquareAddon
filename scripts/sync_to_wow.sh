#!/bin/sh
set -eu

PROJECT_ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
SRC_DIR="$PROJECT_ROOT/EmpowerSquare"
DEST_DIR="/Applications/World of Warcraft/_retail_/Interface/AddOns/EmpowerSquare"

mkdir -p "$DEST_DIR"
rsync -av --delete "$SRC_DIR/" "$DEST_DIR/"
echo "Synced EmpowerSquare to $DEST_DIR"

