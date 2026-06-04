
# How to Create a New Game/Battle Room

This guide provides a step-by-step walkthrough for creating and integrating a new combat arena (`BattleRoom`) or Map Scene into the game ecosystem. Following this standard prevents race conditions, lifecycle synchronization bugs, and memory leaks.

---

## Architecture Overview

The system uses a decoupled, asynchronous flow to separate **Scene Streaming** from **Data Initialization**:
1. **`SceneManager` (Autoload)** handles the stage curtains: it fades the screen out, wipes previous nodes from memory, instantiates the new scene file into the scene tree, and binds the camera.
2. **`BattleRoom` (Active Scene Node)** handles its own layout, spawning the player character (`Milo`) and managing progressive enemy waves only *after* the Godot Engine confirms its internal node hierarchy is completely active (`ready`).
3. **Data Payload Resources (`BattleEncounter` & `BattleWave`)** drive the combat settings dynamically from inspector files without hardcoded script properties.

---

## Step 1: Create the Scene Configuration Resources

Before initializing a scene file, you must build its data payload using custom engine resources.

### 1. Create Enemy Waves (`BattleWave`)
1. In the Godot FileSystem, navigate to `res://resources/`.
2. Right-click -> **New Resource...** -> Select **`BattleWave`**.
3. Name your file (e.g., `wave_slime_easy.tres`).
4. In the Inspector, expand **Wave Composition**. Click on **Enemies** -> **Add Element**.
5. Drag and drop your enemy actor scenes (e.g., `res://scenes/battle_slime.tscn`) into the array fields.

### 2. Create the Master Encounter (`BattleEncounter`)
1. Right-click `res://resources/` -> **New Resource...** -> Select **`BattleEncounter`**.
2. Name your file (e.g., `encounter_forest_01.tres`).
3. Set your background texture and custom background audio files under **Audio & Visuals**.
4. Under **Waves & Enemies**, click **Waves** -> **Add Element**.
5. Drag and drop your previously created `BattleWave` (`.tres`) files into this list in chronological order.

---

## Step 2: Create the Combat Scene Layout

Every new battle screen must inherit or match the structural nodes expected by our lifecycle scripts.

1. Create a new 2D Scene in `res://scenes/` (e.g., `battle_room_forest.tscn`).
2. Attach the `res://scripts/battle_room.gd` script to the root node.
3. Construct the required Node hierarchy exactly as follows:


```

⚙️ BattleRoom (Root Node attached to battle_room.gd)
├── 📹 Camera (Camera2D node automatically grabbed by SceneManager)
├── 🎵 MusicPlayer (AudioStreamPlayer2D node)
├── 📍 hero_spawn (Marker2D - Where Milo will be placed)
└── 📁 EnemyPositions (Node2D container)
├── 📍 enemy_spawn_01 (Marker2D)
├── 📍 enemy_spawn_02 (Marker2D)
└── 📍 enemy_spawn_03 (Marker2D)

```

> ⚠️ **CRITICAL REMINDER:** Ensure your Node names match exactly (case-sensitive) as script fields look for `$EnemyPositions/enemy_spawn_01` and `$hero_spawn`.

---

## Step 3: Triggering Transitions via Overworld Portals

To link an overworld screen (like `overworld.tscn`) to your new battle screen, configure a `DoorPortal` area tracker.

1. Open your overworld map design layout and instantiate a `door_portal.tscn` node.
2. Select the instantiated node and open the **Inspector** tab.
3. Configure the **Target Destination** variables:
   * **`Go Back`**: False.
   * **`To Scene Name`**: Type the file name of your map scene *without* extension (e.g., `battle_room_forest`).
4. Configure the **Battle Configuration** variables:
   * **`Is Battle`**: Check to set as `True`.
   * **`Battle Resource Filename`**: Type the name of your master encounter asset stored in resources (e.g., `encounter_forest_01.tres`).

---
