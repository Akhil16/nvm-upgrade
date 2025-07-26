#!/bin/bash

PACKAGE_LIST_FILE="nvm-global-packages.txt"

# Validate package list formatting (commas + spacing)
check_package_list_format() {
  local file="$1"
  local bad_lines=0
  while IFS= read -r line; do
    [[ -z "$line" || "$line" =~ ^Node\ Version: || "$line" =~ No\ global\ packages\ installed ]] && continue
    if echo "$line" | grep -qE ',[^[:space:]]'; then
      echo "Warning: Missing space after comma in line:"
      echo "  $line"
      ((bad_lines++))
    fi
    if echo "$line" | grep -qE '[^,][[:space:]]{2,}[^,]'; then
      echo "Warning: Multiple spaces without commas in line:"
      echo "  $line"
      ((bad_lines++))
    fi
    if echo "$line" | grep -qE ',$'; then
      echo "Warning: Line ends with a comma:"
      echo "  $line"
      ((bad_lines++))
    fi
  done < "$file"
  return $bad_lines
}

# Get installed version of global package via node JSON parsing
get_installed_version() {
  local pkg="$1"
  node -e "
    const input = process.argv[1];
    try {
      const data = JSON.parse(input);
      if (data.dependencies && data.dependencies['$pkg'])
        console.log(data.dependencies['$pkg'].version || '');
    } catch {}
  " "$(npm ls -g "$pkg" --json --depth=0 2>/dev/null)" 2>/dev/null
}

if [ ! -f "$PACKAGE_LIST_FILE" ]; then
  echo "Error: Package list file '$PACKAGE_LIST_FILE' not found. Please run extraction script first."
  exit 1
fi

echo "Checking format of package list file: $PACKAGE_LIST_FILE ..."
if check_package_list_format "$PACKAGE_LIST_FILE"; then
  echo "Package list format looks good."
else
  echo "Formatting issues detected above. Please fix before proceeding."
  while true; do
    read -rp "Do you still want to continue? (y/n): " yn_raw
    yn=$(echo "$yn_raw" | tr '[:upper:]' '[:lower:]' | xargs)
    case $yn in
      y ) break ;;
      n ) echo "Aborting per user choice."; exit 1 ;;
      * ) echo "Please answer y or n." ;;
    esac
  done
fi

SAVEIFS=$IFS
IFS=$'\n'
ALL_PACKAGES=($(grep -v '^Node Version:' "$PACKAGE_LIST_FILE" \
  | grep -v '^$' \
  | grep -v 'No global packages installed' \
  | tr ',' '\n' \
  | sed 's/^\s*//;s/\s*$//' \
  | sort -u))
IFS=$SAVEIFS

if [ ${#ALL_PACKAGES[@]} -eq 0 ]; then
  echo "No global packages found in the package list."
  exit 0
fi

LATEST_NODE_VERSION=$(nvm list available | awk 'NR>2 {print $2}' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | head -1)
if [ -z "$LATEST_NODE_VERSION" ]; then
  echo "Error: Could not detect latest stable Node.js version."
  exit 1
fi

INSTALLED_NODES=$(nvm ls | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+')
ALREADY_HAS_LATEST=false
if echo "$INSTALLED_NODES" | grep -qx "$LATEST_NODE_VERSION"; then
  ALREADY_HAS_LATEST=true
fi

MISSING_PACKAGES=()
for pkg in "${ALL_PACKAGES[@]}"; do
  latest_ver=$(npm view "$pkg" version 2>/dev/null)
  installed_ver=$(get_installed_version "$pkg")
  if [ "$installed_ver" != "$latest_ver" ]; then
    MISSING_PACKAGES+=("$pkg")
  fi
done

if $ALREADY_HAS_LATEST && [ "${#MISSING_PACKAGES[@]}" -eq 0 ]; then
  echo "Latest stable Node.js version ($LATEST_NODE_VERSION) and all global packages are up to date."
  echo "Nothing to install. Exiting."
  exit 0
fi

echo "Latest stable Node.js LTS to install/use: $LATEST_NODE_VERSION"
echo "Installed Node.js versions:"
echo "$INSTALLED_NODES"
echo

read -rp "Proceed with installing Node.js $LATEST_NODE_VERSION and missing packages? (y/n): " confirm_raw
confirm=$(echo "$confirm_raw" | tr '[:upper:]' '[:lower:]' | xargs)
case "$confirm" in
  y ) ;;
  * ) echo "Aborted by user."; exit 0 ;;
esac

if ! $ALREADY_HAS_LATEST; then
  echo "Installing Node.js $LATEST_NODE_VERSION ..."
  if ! nvm install "$LATEST_NODE_VERSION"; then
    echo "Error installing Node.js $LATEST_NODE_VERSION."
    exit 1
  fi
fi

if ! nvm use "$LATEST_NODE_VERSION"; then
  echo "Error switching to Node.js $LATEST_NODE_VERSION."
  exit 1
fi

if $ALREADY_HAS_LATEST; then
  PACKAGES=("${MISSING_PACKAGES[@]}")
else
  PACKAGES=("${ALL_PACKAGES[@]}")
fi

if [ ${#PACKAGES[@]} -eq 0 ]; then
  echo "No packages require installation."
  echo "Done."
  exit 0
fi

echo "Global packages to install/update:"
printf '  %s\n' "${PACKAGES[@]}"

SKIP_ALL=false
INSTALL_ALL=false

for pkg in "${PACKAGES[@]}"; do
  if $SKIP_ALL; then
    echo "Skipping package $pkg (skip all enabled)."
    continue
  fi
  if $INSTALL_ALL; then
    echo "Installing package $pkg $latest_ver (install all enabled)."
    if npm install -g "$pkg"; then
      echo "Installed $pkg $latest_ver successfully."
    else
      echo "Error installing $pkg."
    fi
    continue
  fi

  desc=$(npm view "$pkg" description 2>/dev/null)
  [ -z "$desc" ] && desc="No description available."

  latest_ver=$(npm view "$pkg" version 2>/dev/null)
  [ -z "$latest_ver" ] && latest_ver="unknown"

  installed_ver=$(get_installed_version "$pkg")

  if [ "$installed_ver" = "$latest_ver" ]; then
    echo ""
    echo "Package: $pkg (version $latest_ver)"
    echo "Description: $desc"
    echo "Already at latest version. Skipping."
    continue
  fi

  echo ""
  echo "Package: $pkg $installed_ver"
  echo "Description: $desc"
  echo "Latest Version Available: $latest_ver"
  echo "Installed Version: ${installed_ver:-Not installed}"
  echo ""

  while true; do
    read -rp "Install package '$pkg $latest_ver'? (y-all/n-all/y/n): " ans_raw
    ans=$(echo "$ans_raw" | tr '[:upper:]' '[:lower:]' | xargs)
    case "$ans" in
      y-all )
        echo "Installing $pkg $latest_ver and all remaining packages ..."
        if npm install -g "$pkg"; then
          echo "Installed $pkg $latest_ver successfully."
        else
          echo "Error installing $pkg $latest_ver."
        fi
        INSTALL_ALL=true
        break
        ;;
      n-all )
        echo "Skipping $pkg $latest_ver and all remaining packages."
        SKIP_ALL=true
        break
        ;;
      y )
        echo "Installing $pkg $latest_ver ..."
        if npm install -g "$pkg"; then
          echo "Installed $pkg $latest_ver successfully."
        else
          echo "Error installing $pkg $latest_ver."
        fi
        break
        ;;
      n )
        echo "Skipping $pkg $latest_ver."
        break
        ;;
      "" )
        echo "Installing $pkg $latest_ver ..."
        if npm install -g "$pkg"; then
          echo "Installed $pkg $latest_ver successfully."
        else
          echo "Error installing $pkg $latest_ver."
        fi
        break
        ;;
      * )
        echo "Please answer y-all, n-all, y, or n."
        ;;
    esac
  done
done

echo "Installation complete."
echo "All global packages have been processed."
echo "You can now run 'nvm ls' to see the installed Node.js versions."
echo "You can also run 'npm ls -g --depth=0' to see the global packages installed for the current Node.js version."
echo "Done."
exit 0