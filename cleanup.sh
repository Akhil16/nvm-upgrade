#!/bin/bash

echo "=== Cleanup: Uninstall Node.js versions managed by nvm except latest stable LTS ==="

get_installed_node_versions() {
  nvm ls | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+'
}

get_latest_lts_version() {
  nvm list available | awk 'NR>2 {print $2}' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | head -1
}

LATEST_LTS_VERSION=$(get_latest_lts_version)
if [ -z "$LATEST_LTS_VERSION" ]; then
  echo "Could not detect the latest stable Node.js LTS version."
  exit 1
fi

echo "Latest stable Node.js LTS version (will be preserved): $LATEST_LTS_VERSION"

if nvm use "$LATEST_LTS_VERSION"; then
  echo "Switched to Node.js version $LATEST_LTS_VERSION."
else
  echo "Failed to switch to Node.js version $LATEST_LTS_VERSION."
fi

INSTALLED_VERSIONS=$(get_installed_node_versions)

if [ -z "$INSTALLED_VERSIONS" ]; then
  echo "No Node.js versions found installed with nvm."
  exit 0
fi

TO_UNINSTALL=()
for ver in $INSTALLED_VERSIONS; do
  if [ "$ver" = "$LATEST_LTS_VERSION" ]; then
    echo "Skipping latest stable LTS Node.js version: $ver"
  else
    TO_UNINSTALL+=("$ver")
  fi
done

if [ ${#TO_UNINSTALL[@]} -eq 0 ]; then
  echo "No Node.js versions to uninstall (only latest LTS is installed)."
  exit 0
fi

echo
echo "Node.js versions available for uninstallation:"
printf "  %s\n" "${TO_UNINSTALL[@]}"
echo

SKIP_ALL=false
UNINSTALL_ALL=false

for ver in "${TO_UNINSTALL[@]}"; do
  if [ "$SKIP_ALL" = true ]; then
    echo "Skipping Node.js version $ver (skip all enabled)."
    continue
  fi

  if [ "$UNINSTALL_ALL" = true ]; then
    echo "Uninstalling Node.js version $ver (uninstall all enabled)."
    if nvm uninstall "$ver"; then
      echo "Successfully uninstalled Node.js version $ver."
    else
      echo "Failed to uninstall Node.js version $ver."
    fi
    continue
  fi

  while true; do
    read -rp "Do you want to uninstall Node.js version $ver? (y/n/y-all/skip-all): " confirm_raw
    confirm=$(echo "$confirm_raw" | tr '[:upper:]' '[:lower:]' | xargs)

    case "$confirm" in
      y )
        echo "Uninstalling Node.js version $ver ..."
        if nvm uninstall "$ver"; then
          echo "Successfully uninstalled Node.js version $ver."
        else
          echo "Failed to uninstall Node.js version $ver."
        fi
        break
        ;;
      n | skip )
        echo "Skipping Node.js version $ver."
        break
        ;;
      y-all )
        echo "Uninstalling Node.js version $ver and all remaining versions ..."
        if nvm uninstall "$ver"; then
          echo "Successfully uninstalled Node.js version $ver."
        else
          echo "Failed to uninstall Node.js version $ver."
        fi
        UNINSTALL_ALL=true
        break
        ;;
      skip-all )
        echo "Skipping Node.js version $ver and all remaining versions."
        SKIP_ALL=true
        break
        ;;
      * )
        echo "Please answer y, n/skip, y-all, or skip-all."
        ;;
    esac
  done
done

echo "Cleanup complete. Latest LTS Node.js version $LATEST_LTS_VERSION remains installed and in use."
