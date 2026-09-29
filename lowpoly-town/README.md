# Lowpoly Town (Godot 4)

A small low-poly town in the spirit of Schedule I: first-person walking around, townspeople wandering and chatting, a day/night cycle with street lights, and an "[E] to interact" system. Everything you see is a placeholder built from boxes, so it runs right now. The point of this project is to **swap in the models and animations you find**, with the fiddly parts (sizes, facing, animation names, walking) handled for you.

## Open it

1. Download **Godot 4.4 or newer**, the standard version (not ".NET"): https://godotengine.org/download
2. Open Godot, click **Import**, pick `lowpoly-town/project.godot`.
3. Press **F5** (or the play button, top right).

| Key | Action |
| --- | --- |
| WASD | Walk |
| Mouse | Look |
| Shift | Run |
| Space | Jump |
| Ctrl or C | Crouch |
| E | Talk / use what you're looking at |
| V | Switch first person / third person |
| Esc | Pause |

## Where things live

```
assets/characters/   your people (.glb, .gltf or .fbx)
assets/animations/   extra animations (e.g. from Mixamo)
assets/buildings/    houses, shops...
assets/props/        benches, bins, signs...
assets/vehicles/     cars
scenes/main.tscn     the level (town, sun, sky, player, townspeople)
scenes/player/       the player
scenes/npc/          one townsperson
scripts/             the code
```

## Where to get models

Prefer **.glb** files when a pack offers them. They import best in Godot. FBX works too.

- **KayKit**: https://kaylousberg.itch.io (free, CC0). Characters come with lots of animations already inside.
- **Quaternius**: https://quaternius.com (free, CC0). Characters, city kits, cars.
- **Kenney**: https://kenney.nl/assets (free, CC0). City kits, cars, furniture, characters.
- **Poly Pizza**: https://poly.pizza (search engine for free low-poly models; check each license).
- **Synty POLYGON** packs (paid): the closest match to the Schedule I look.
- **Mixamo**: https://www.mixamo.com (free, Adobe account). Hundreds of animations for any humanoid.

## 1. Put your own player character in

1. Drag your character file (say `guy.glb`) into `assets/characters/` in Godot's **FileSystem** panel.
2. Open `scenes/player/player.tscn`, click the **Model** node.
3. In the **Inspector**, drag `guy.glb` onto **Model Scene**.
4. Press F5, then press **V** to see yourself in third person.

The Model node (`scripts/character_model.gd`) sorts out the usual problems:

| Problem | Setting on the Model node |
| --- | --- |
| Wrong size | **Target Height** (meters; 1.75 is an adult). Set 0 to keep the file's size. |
| Walks backwards | Untick **Flip Forward** |
| Picked the wrong animation | Tick **Print Clips**, run once, read the names in the Output panel, then add e.g. `walk` → `Walking_B` to **Clip Overrides** |
| Has swords/hats/shields you don't want | **Hide Nodes**: add `*Sword*`, `*Shield*`, `Hat*`... (wildcards work) |
| Feet slide | Adjust **Walk Clip Speed** / **Run Clip Speed** |

It finds animations by name automatically. Anything containing "idle", "walk", "run", "jump", "fall" and so on is picked, preferring plain versions over "strafe", "backwards", "2H_melee" etc. Tested on the KayKit Knight and Rogue, it picked `Idle`, `Walking_A`, `Running_A`, `Jump_Start`, `Jump_Idle`, `Jump_Land` and `Interact` out of 76 clips.

## 2. Townspeople

Click the **NPCs** node in `scenes/main.tscn`:

- **Character Models**: add as many character files as you like; each townsperson picks one at random.
- **Hide Nodes**: same as above, for all of them.
- **Count**: how many.

Names and chat lines are at the top of `scripts/npc_spawner.gd`. Each townsperson says a random line when you press E on them, and plays a "talk" animation if their model has one.

## 3. Mixamo animations

1. On Mixamo, upload your character (or use theirs), pick an animation, **Download** as FBX. For animation-only files choose **Without Skin**.
2. Put the `.fbx` in `assets/animations/`, and name the file after what it is (`Walking.fbx`, `Idle.fbx`, `Running.fbx`). The name is how the Model node recognizes it.
3. Click the file in FileSystem, open the **Import** tab (next to Scene, top left), set **Import As: Animation Library**, click **Reimport**.
4. On your Model node, add those files to **Extra Libraries**.

**Mixamo animations on a non-Mixamo character** (e.g. a Quaternius or Synty person) need retargeting once per file:

1. Double-click the file to open **Advanced Import Settings**.
2. Select the **Skeleton3D**.
3. Under **Retarget → Bone Map**, create a **New BoneMap** and set its **Profile** to **SkeletonProfileHumanoid**. Godot fills in the bone names for standard rigs; fix any red ones by hand.
4. Click **Reimport**.

Do this for the character **and** each animation file, and they'll share animations.

## 4. Your own buildings and props

1. Drag models into `scenes/main.tscn` as children of **NavigationRegion3D**, so townspeople walk around them.
2. For collision, double-click the model file → **Advanced Import Settings** → click the mesh → turn on **Physics**, **Body Type: Static**. Use **Shape Type: Simple Convex** for props and **Trimesh** for buildings you can walk into.
3. When you've built your own town, click the **Town** node and untick **Enabled** (or delete it), so the placeholder boxes go away.
4. The walkable area is re-baked every time the game starts. To see it in the editor, select **NavigationRegion3D** and click **Bake NavigationMesh** in the toolbar.

## 5. Make something interactable

1. Give the object a collision shape (e.g. a **StaticBody3D** with a **CollisionShape3D**).
2. Add a child node, **Add Child Node → Interactable**.
3. Set **Prompt** ("Open", "Buy", "Talk to"), **Display Name** and optionally **Lines** of dialog.
4. For real behavior, select the Interactable → **Node** tab → double-click **interacted** and connect it to your script.

## Tuning the feel

- Walk/run speed, jump, mouse sensitivity, head bob and FOV: click **Player** → Inspector.
- Day length and start time: click **DayNight** (`Minutes Per Day`, `Hour`).
- Colors, fog and saturation: **WorldEnvironment** → Environment. Most of the Schedule I look is saturated colors, soft fog and flat materials (no shiny textures).

## Checking it works without opening the editor

```
godot --headless --path . -- --smoke-test
godot --headless --path . -- --smoke-test --model=res://assets/characters/guy.glb
```

This walks, runs, jumps, talks to a townsperson and flips day/night, then prints ok/FAIL for each step. With `--model` it also checks that your character's animations were found and its size is right. Screenshots are also possible: `-- --screenshot=shot.png --hour=18 --third-person`.
