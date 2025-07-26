#!/bin/bash

echo "=== Cleanup: Fix phantom Node.js versions showing in nvm list ==="

# Get all installed Node.js versions managed by nvm
get_installed_node_versions() {
  nvm ls | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+'
}

# Get the latest stable LTS Node.js version (nvm-windows style)
get_latest_lts_version() {
  nvm list available | awk 'NR>2 {print $2}' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | head -1
}

# Determine nvm directory for manual deletion (adjust if needed)
get_nvm_dir() {
  # Typically set via environment variable NVM_HOME on Windows
  # Modify path below if different on your system
  echo "$NVM_HOME"
}

LATEST_LTS_VERSION=$(get_latest_lts_version)
if [ -z "$LATEST_LTS_VERSION" ]; then
  echo "Error: Could not detect the latest stable LTS Node.js version."
  exit 1
fi

echo "Latest stable Node.js LTS version (will be preserved): $LATEST_LTS_VERSION"

NVM_DIR=$(get_nvm_dir)
if [ -z "$NVM_DIR" ] || [ ! -d "$NVM_DIR" ]; then
  echo "Error: Could not determine your NVM directory. Please set NVM_HOME environment variable or update this script."
  exit 1
fi

echo "Detected NVM directory: $NVM_DIR"

INSTALLED_VERSIONS=$(get_installed_node_versions)

if [ -z "$INSTALLED_VERSIONS" ]; then
  echo "No Node.js versions found installed with nvm."
  exit 0
fi

echo
echo "Attempting to uninstall phantom Node.js versions..."

for ver in $INSTALLED_VERSIONS; do
  if [ "$ver" = "$LATEST_LTS_VERSION" ]; then
    echo "Skipping latest stable LTS version: $ver"
    continue
  fi

  echo
  echo "Attempting to uninstall Node.js version $ver ..."
  nvm uninstall "$ver"
  uninstall_exit_code=$?

  # Check if version still listed after uninstall
  still_listed=false
  if nvm list | grep -q -w "$ver"; then
    still_listed=true
  fi

  if [ $uninstall_exit_code -eq 0 ] && [ "$still_listed" = false ]; then
    echo "Uninstalled Node.js version $ver successfully."
    continue
  else
    echo "Uninstall either failed or the version $ver still appears in 'nvm list'."
    echo "Attempt manual folder deletion if you want."
  fi

  while true; do
    read -rp "Do you want to manually delete the folder for Node.js version $ver? (y/n): " yn_raw
    yn=$(echo "$yn_raw" | tr '[:upper:]' '[:lower:]' | xargs)
    case "$yn" in
      y )
        NODE_VER_PATH="$NVM_DIR/v$ver"
        if [ -d "$NODE_VER_PATH" ]; then
          echo "Deleting folder $NODE_VER_PATH ..."
          rm -rf "$NODE_VER_PATH"
          if [ $? -eq 0 ]; then
            echo "Successfully deleted folder $NODE_VER_PATH."
            # Verify if version still appears in nvm list
            if nvm list | grep -q -w "$ver"; then
              echo "Warning: Version $ver still appears in 'nvm list'. You may need to check settings.txt or restart your shell."
            else
              echo "Version $ver no longer appears in 'nvm list'."
            fi
          else
            echo "Failed to delete folder $NODE_VER_PATH. Please check permissions."
          fi
        else
          echo "Folder $NODE_VER_PATH does not exist. Skipping manual deletion."
        fi
        break
        ;;
      n )
        echo "Skipped manual deletion for version $ver."
        break
        ;;
      * )
        echo "Please enter 'y' or 'n'."
        ;;
    esac
  done
done

echo
echo "Cleanup of phantom Node.js versions complete."
echo "Latest stable LTS version $LATEST_LTS_VERSION remains installed."
