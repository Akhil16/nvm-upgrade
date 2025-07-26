Certainly! Here's a comprehensive **README.md** file for your Node.js version and package management scripts repository, covering extraction, cleanup, and installation tasks with nvm and npm on Windows/macOS/Linux.

```markdown
# Node.js Version and Global Package Management Scripts

This repository contains a set of **Bash scripts** to manage multiple Node.js versions and their global packages in environments using **nvm** (Node Version Manager), including `nvm-windows`. These scripts help you:

- **Extract** installed global npm packages from all Node.js versions managed by nvm.
- **Clean up** unwanted or phantom Node.js versions safely.
- **Install** the latest stable Node.js LTS and associated global packages with interactive prompts.

---

## Contents

### 1. `get-nvm-global-packages.sh`  
Extracts global npm packages from each installed Node.js version and saves a consolidated list to `nvm-global-packages.txt`.  
- Uses Node.js for JSON parsing (no external tools like `jq` needed).  
- Helps backup or migrate your global packages before upgrades or cleanup.

### 2. `cleanup-nvm-node-versions.sh`  
Interactively uninstalls **all Node.js versions except the latest stable LTS**, with per-version prompts and options to:

- Uninstall individual versions (`y`),
- Skip versions (`n` or `skip`),
- Uninstall all remaining (`y-all`),
- Skip all remaining (`skip-all`).

Preserves your latest stable LTS and switches to it before cleanup.

### 3. `install-latest-node-and-packages.sh`  
Ensures you have the latest stable Node.js LTS installed and reinstalls **missing or outdated global npm packages** listed in `nvm-global-packages.txt`.  
- Shows package descriptions from the npm registry.  
- Supports interactive per-package confirmation with `y-all` and `n-all` options.  
- Skips packages that are already installed at the latest version.

### 4. `cleanup-failed.sh`  
Fixes phantom Node.js versions that remain listed by `nvm ls` but cannot be uninstalled normally.  
- Attempts uninstall, and if failing, prompts for manual folder deletion (correctly handling folder naming conventions with `v` prefix).  
- Also advises on steps if phantom entries remain due to config files.

---

## Features and Benefits

- **Cross-platform compatible**: Works on Windows with `nvm-windows`, Linux, and macOS with native `nvm`.
- **No external dependencies**: Uses Node.js built-in JSON parsing, avoiding the need for utilities like `jq`.
- **Detailed logging**: Clear, step-by-step feedback throughout script execution.
- **Robust input handling**: Normalizes user input for interactive prompts, supporting batch operations (`y-all`, `n-all`, `skip-all`).
- **Safe and idempotent**: Can safely be run multiple times; skips up-to-date Node.js versions and packages.
- **Interactive prompts**: Choose which package/version to uninstall or install, or select all/skip all with ease.

---

## Prerequisites

- **nvm** or **nvm-windows** installed and configured.
- **Node.js** (any version) and **npm** available in your shell environment.
- Ability to run **Bash scripts** (Git Bash or WSL on Windows, terminal on Linux/macOS).
- **`NVM_HOME` environment variable set on Windows** for folder detection (used in cleanup scripts).

---

## Usage

### 1. Extract global packages

```
chmod +x get-nvm-global-packages.sh
./get-nvm-global-packages.sh
```

- Outputs a formatted `nvm-global-packages.txt` file listing global npm packages across installed Node versions.

### 2. Cleanup unwanted Node.js versions

```
chmod +x cleanup-nvm-node-versions.sh
./cleanup-nvm-node-versions.sh
```

- Uninstalls all Node versions except latest LTS with interactive prompts.
- Use `y`, `n`, `y-all`, or `skip-all` as answers.

### 3. Install latest Node and global packages

```
chmod +x install-latest-node-and-packages.sh
./install-latest-node-and-packages.sh
```

- Installs latest stable Node.js LTS version if not present.
- Installs missing or outdated global npm packages interactively.

### 4. Cleanup phantom versions (failed uninstalls)

```
chmod +x cleanup-failed.sh
./cleanup-failed.sh
```

- Fixes versions that appear in `nvm list` but cannot be uninstalled.
- Offers manual folder deletion and guidance.

---

## Notes

- Scripts use Node.js one-liners for JSON parsing to avoid extra dependencies.
- The cleanup scripts preserve your latest stable LTS Node.js version.
- Manual correction of `settings.txt` in your nvm directory may be necessary if phantom versions persist — see the cleanup-failed script for details.
- Always backup important data before running cleanup scripts.
- Scripts are idempotent and can be rerun safely.

---

## Troubleshooting

- If versions remain visible after uninstall, check your nvm settings file (Windows: `%NVM_HOME%\settings.txt`) and remove phantom entries manually.
- Ensure no processes are using Node.js versions you want to uninstall.
- Restart shells after making changes to nvm installation.
- Confirm `NVM_HOME` env var is set properly on Windows to enable script folder lookups.

---

## License

MIT License — Feel free to use, modify, and distribute.

---

## Contributions & Feedback

Issues, suggestions, or improvements welcome!  
Open a GitHub issue or fork and submit a pull request.

---

## Author

Akhil chaturvedi + AI (perplexity)
---

*Happy Node.js version management!* 🚀
```
