# launchers

Two menu bar icons that are one-click launchers. Everything they show comes from files in this folder, so a new laptop gets the whole setup from a clone plus one script.

- **Tab groups** (stacked-rectangles icon): each `tabs/*.txt` file is a group, one URL per line, `#` for comments. Clicking a group opens its URLs in Chrome. The menu also has "Close all tabs", "Save open tabs as group…", and "Edit groups". Only `tabs/example.txt` is tracked; your own groups are gitignored and get copied to a new machine by hand.
- **Routines** (hammer icon): each executable script in `routines/` is a menu item named after the file. A routine that exits nonzero shows an alert with its stderr.

`TabGroups.app` draws both icons. It reads `~/tabs` and `~/routines`, which `install.sh` makes symlinks into this folder, and it shells out to `~/tools/tabs` for tab actions. Menus rebuild on every click, so adding or deleting a file updates them with no restart.

## Setting up a new laptop

1. Clone this repo and put it on `$PATH` as `~/tools`:

   ```sh
   git clone https://github.com/joelshet/tools.git ~/repos/tools
   ln -s ~/repos/tools ~/tools
   ```

2. Install Xcode Command Line Tools if `swiftc --version` fails:

   ```sh
   xcode-select --install
   ```

3. Run the installer. It links `~/tabs` and `~/routines` here, compiles `TabGroups.swift` into `TabGroups.app`, and launches it. The app registers itself as a login item on first launch.

   ```sh
   ~/tools/launchers/install.sh
   ```

4. Copy your tab group files from the old machine into `~/tools/launchers/tabs/` (they are not in git). `example.txt` shows the format.

5. macOS asks once for TabGroups to control Chrome, on the first "Close all tabs" or "Save open tabs as group…". Allow it.

6. Add the ctrl-shift-space binding to `~/.config/zed/keymap.json` so the routines' "Go" pattern works (see below):

   ```json
   [
     { "context": "Workspace", "bindings": { "ctrl-shift-space": ["task::Spawn", { "task_name": "Go" }] } },
     { "context": "Editor",    "bindings": { "ctrl-shift-space": ["task::Spawn", { "task_name": "Go" }] } },
     { "context": "Terminal",  "bindings": { "ctrl-shift-space": ["task::Spawn", { "task_name": "Go" }] } }
   ]
   ```

The routines expect Zed at `/Applications/Zed.app`, and the current ones point at `~/hq`, `~/repos/hq_video`, and `~/repos/recording-rig`. A routine whose target folder is missing fails with an alert; that's the signal to clone or copy that folder.

## The Go pattern

Every "start working on X" routine has the same shape:

1. The routine opens Zed at the project with its README focused: `zed FOLDER FOLDER/README.md`.
2. The README's top line states the next command and its shortcut.
3. ctrl-shift-space spawns the project's Zed task labeled "Go" (in its `.zed/tasks.json`), which runs that command in a new terminal tab.

Wiring a new project takes three pieces: a routine script here, a "Go" task in the project's `.zed/tasks.json`, and the next-step line atop its README.

## Editing

- New tab group: add `tabs/NAME.txt`, or use "Save open tabs as group…" in the menu, or `tabs save NAME`.
- New routine: add an executable script to `routines/` (shebang + `chmod +x`).
- App change: edit `TabGroups.swift`, then rerun `install.sh` (it rebuilds and relaunches).

The `tabs` CLI (in the repo root) is the same one the menu uses: `tabs` lists groups, `tabs NAME` opens one, `tabs clear` closes every Chrome window, `tabs save NAME` writes the open tabs to a new group.

## State outside this folder

- `~/tabs` and `~/routines`: symlinks into this folder. Remove: `rm ~/tabs ~/routines`.
- `TabGroups.app`: built here by `build.sh`, gitignored. Remove: delete it.
- Login item: registered by the app at its path in this folder. Remove: `./TabGroups.app/Contents/MacOS/TabGroups --unregister`, or System Settings > General > Login Items & Extensions.
- Automation permission (TabGroups to Google Chrome): System Settings > Privacy & Security > Automation.
- The Zed keymap binding above, and each project's "Go" task and README top line.

Full removal: unregister the login item, quit the app from its menu, remove the two symlinks, and delete this folder. If the checkout moves, rerun `install.sh` so the login item points at the new path.
