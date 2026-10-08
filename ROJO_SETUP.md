# Connecting this repo to your Roblox game with Rojo

Rojo keeps the scripts in this repo and the scripts in Roblox Studio in sync.
This is a one-time setup. It takes about 20 minutes.

**Before you start:** in Roblox Studio, open your game and save a backup copy
(File → Save to File As → name it something like `MyGame-backup.rbxl`).
Keep that file somewhere safe. Nothing below should damage your game, but a
backup means you can always go back.

---

## Step 1: Get this repo onto your computer

1. Install **GitHub Desktop** from https://desktop.github.com and sign in with
   your GitHub account.
2. In GitHub Desktop: **File → Clone repository**, pick `selard73/Create-repository`,
   choose where to put it (for example `Documents\Create-repository`), click **Clone**.
3. At the top of GitHub Desktop, click **Current branch** and choose
   `claude/epic-hawking-188q4l`. That is the branch Claude is working on.

You now have a folder on your computer that mirrors this repo.

## Step 2: Install Rojo

1. Go to https://github.com/rojo-rbx/rojo/releases/latest
2. Download the zip for your computer:
   - Windows: `rojo-7.x.x-windows-x86_64.zip`
   - Mac (Apple Silicon, M1/M2/M3/M4): `rojo-7.x.x-macos-aarch64.zip`
   - Mac (Intel): `rojo-7.x.x-macos-x86_64.zip`
3. Unzip it. You get one file: `rojo.exe` (Windows) or `rojo` (Mac).
4. Move that file into the repo folder from Step 1 (next to `default.project.json`).

## Step 3: Open a terminal in the repo folder

- **Windows:** open the repo folder in File Explorer, click the address bar,
  type `powershell` and press Enter.
- **Mac:** open Terminal, type `cd ` (with a space), drag the repo folder into
  the Terminal window, press Enter.

Check it works:

```
# Windows
.\rojo.exe --version

# Mac (first time only, the second line lets macOS run it)
chmod +x ./rojo
./rojo --version
```

You should see something like `Rojo 7.7.0`.

## Step 4: Install the Rojo plugin into Studio

In the same terminal:

```
# Windows
.\rojo.exe plugin install

# Mac
./rojo plugin install
```

Restart Roblox Studio if it was open. You should see a **Rojo** button in the
**Plugins** tab.

## Step 5: Export your scripts out of Studio (one time)

1. In Studio, open your game and **File → Save to File As**. Save it as
   `game.rbxl` inside the repo folder.
2. In the terminal:

```
# Windows
.\rojo.exe syncback default.project.json --input game.rbxl

# Mac
./rojo syncback default.project.json --input game.rbxl
```

3. It lists what it is about to write and asks you to confirm. Type `y`.

You should now have a `src` folder with your scripts in it, organized by where
they live in Studio (`src/ServerScriptService`, `src/ReplicatedStorage`, and so on).

## Step 6: Push the scripts to GitHub

1. Open GitHub Desktop. It lists all the new files on the left.
2. In the bottom-left box, type a summary like `Export scripts from Studio`
   and click **Commit to claude/epic-hawking-188q4l**.
3. Click **Push origin** at the top.

Tell Claude it is done. Claude can now see every script.

## Step 7: Live sync (every time you work on the game)

1. In the terminal:

```
# Windows
.\rojo.exe serve

# Mac
./rojo serve
```

   Leave this running. It says it is listening on `localhost:34872`.

2. In Studio, click the **Rojo** button in the Plugins tab, then **Connect**.

Now whenever Claude pushes a change and you click **Fetch origin** then
**Pull** in GitHub Desktop, the change appears in Studio instantly. Hit Play
to test it.

---

## The rules once Rojo is set up

- **Scripts live in the repo.** Edit them in files (Claude does this, or you
  can in a text editor like VS Code). If you edit a synced script inside
  Studio, Rojo will overwrite your edit the next time it connects.
- **Everything else lives in Studio.** Your map, parts, models, and UI are not
  synced. Keep building them in Studio like you do now. Save the place in
  Studio as usual (File → Publish to Roblox).
- **Added a new script inside Studio?** That is fine, Rojo leaves it alone.
  To get it into the repo, repeat Step 5 and Step 6.

## What is synced

| Studio location                        | Repo folder                      |
|----------------------------------------|----------------------------------|
| ReplicatedFirst                        | `src/ReplicatedFirst`            |
| ReplicatedStorage                      | `src/ReplicatedStorage`          |
| ServerScriptService                    | `src/ServerScriptService`        |
| ServerStorage                          | `src/ServerStorage`              |
| StarterPlayer → StarterPlayerScripts   | `src/StarterPlayerScripts`       |
| StarterPlayer → StarterCharacterScripts| `src/StarterCharacterScripts`    |

Not synced (stays in Studio): Workspace, StarterGui, Lighting, and everything
else. This list lives in `default.project.json` and can be changed later.

## If something goes wrong

- `rojo` is not recognized: make sure the terminal is open *in the repo folder*
  and that `rojo.exe` / `rojo` is in that folder.
- Studio says it cannot connect: make sure `rojo serve` is still running in
  the terminal.
- Something looks wrong in Studio after connecting: click **Disconnect** in the
  Rojo plugin, do not save, and tell Claude what happened. Your backup from the
  top of this guide is untouched.
