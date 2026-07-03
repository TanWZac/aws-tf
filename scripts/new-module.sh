#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <module_name>"
  exit 1
fi

MODULE_NAME="$1"
MODULE_DIR="modules/${MODULE_NAME}"

if [[ -d "$MODULE_DIR" ]]; then
  echo "Module already exists: $MODULE_DIR"
  exit 1
fi

mkdir -p "$MODULE_DIR"
cp scripts/template/main.tf "$MODULE_DIR/main.tf"
cp scripts/template/variables.tf "$MODULE_DIR/variables.tf"
cp scripts/template/outputs.tf "$MODULE_DIR/outputs.tf"

# Replace placeholder with actual module name in generated files.
sed -i "s/template_module/${MODULE_NAME}/g" "$MODULE_DIR"/*.tf

echo "Created module scaffold at $MODULE_DIR"
echo "Next steps:"
echo "1) Implement resources in $MODULE_DIR/main.tf"
echo "2) Add module call in root main.tf"
echo "3) Add/extend root variables.tf and outputs.tf if needed"
