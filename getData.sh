#!/bin/bash

OUTPUT_FILE="nvm-global-packages.txt"
echo "" > "$OUTPUT_FILE"

echo "Gathering global npm packages for each installed Node version..."

NODE_VERSIONS=$(nvm ls | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+')

if [ -z "$NODE_VERSIONS" ]; then
  echo "No Node.js versions found."
  exit 1
fi
echo "Found Node.js versions: $NODE_VERSIONS"

for version in $NODE_VERSIONS; do
  echo "Switching to Node version $version..."
  nvm use "$version" >/dev/null || { echo "Failed to switch to Node version $version"; continue; }

  echo "Node Version: $version" >> "$OUTPUT_FILE"

  PACKAGES=$(npm ls -g --depth=0 --json 2>/dev/null | node -e "
    let data='';
    process.stdin.setEncoding('utf8');
    process.stdin.on('data', chunk => data+=chunk);
    process.stdin.on('end', () => {
      try {
        let obj = JSON.parse(data);
        if(obj.dependencies) {
          Object.keys(obj.dependencies)
            .filter(key => key !== 'npm')
            .forEach(pkg => console.log(pkg));
        }
      } catch (e) {
        process.exit(0);
      }
    });
  ")

  if [ -z "$PACKAGES" ]; then
    echo "(No global packages installed)" >> "$OUTPUT_FILE"
  else
    mapfile -t package_array <<< "$PACKAGES"
    joined_packages=$(IFS=', '; echo "${package_array[*]}")
    echo "$joined_packages" >> "$OUTPUT_FILE"
  fi

  echo "" >> "$OUTPUT_FILE"
  echo "Recorded global packages for Node version $version"
done


# Normalize output to ensure comma+space consistency (extra safety)
sed -i.bak 's/, */, /g' "$OUTPUT_FILE" && rm "$OUTPUT_FILE.bak"

echo "Global packages saved to $OUTPUT_FILE"
echo "Step 1 complete: Extraction done."
