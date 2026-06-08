# Internationalization (I18N) Guide — O Mundo de Milo

This document establishes the architecture, directory standards, and engineering rules for localizing and translating "O Mundo de Milo" into multiple languages (e.g., `pt_br`, `en_us`).

---

## 1. Dialogue Architecture (Cultural Localization Layout)

To allow writers and narrative editors total freedom to adapt jokes, idioms, and cultural contexts, dialogue files are stored in **separate language folders**.

### Directory Structure

All dialogue JSON files must be organized inside `res://dialogues/` following the locale code nomenclature:

```text
res://
└── dialogues/
    ├── en_us/
    │   └── village_guardian.json
    └── pt_br/
        └── village_guardian.json

```

### The Golden Rule for Writers & Editors

While the narrative text strings can change drastically to fit the target language, **structural keys, branch pointers, and reward triggers must remain 100% identical** across all versions of the same file.

* **Allowed to change:** The text inside the `"text"` fields.
* **STRICTLY FORBIDDEN to change/desync:** Node block IDs (e.g., `"intro"`, `"end_nodes"`), choice redirection pointers (`"next_node_id"`), and database reward anchors (`"reward_item_id"`).

#### Correct Snyced Example:

* **`res://dialogues/pt_br/village_guardian.json`**
```json
"give_quest_tips": {
  "speaker_type": "npc",
  "text": "Pegue esta poção para sua segurança, Milo!",
  "reward_item_id": "potion_health",
  "choices": [{"text": "Obrigado!", "next_node_id": "end_nodes"}]
}

```

* **`res://dialogues/en_us/village_guardian.json`**
```json
"give_quest_tips": {
  "speaker_type": "npc",
  "text": "Take this potion for your safety, young boy!",
  "reward_item_id": "potion_health",
  "choices": [{"text": "Thank you!", "next_node_id": "end_nodes"}]
}

```


---

## 2. Dynamic Dialogue Loading Code (`npc_base.gd`)

When internationalization is activated, `NpcBase` will stop using absolute paths and dynamically look for the file inside the active directory provided by `GameManager.current_locale`.

```gdscript
## Target interpolation strategy to adapt inside npc_base.gd in the future:
@export var dialogue_file_name: String = "village_guardian.json"

func _start_conversation() -> void:
	var current_language: String = GameManager.current_locale # e.g., "pt_br" or "en_us"
	var localized_path: String = "res://dialogues/" + current_language + "/" + dialogue_file_name
	
	var is_success = HistoryManager.load_dialogue_file(localized_path)
	if is_success:
		DialogManager.start_dialogue(npc_name, npc_portrait)

```

---

## 3. Static UI and HUD Translation (The `tr()` Engine Strategy)

For user interface components that do not require deep narrative adaptation (such as Inventory windows, Shop headers, Combat logs, and Main Menu buttons), Godot’s native Translation system will be utilized.

### Implementation Workflow

1. **Create a translation spreadsheet** containing all core system IDs and export it as a standard comma-separated file (`.csv`) saved in `res://localization/ui_translations.csv`.

| id | en | pt |
| --- | --- | --- |
| HUD_INVENTORY_TITLE | INVENTORY | INVENTÁRIO |
| HUD_REWARD_ALERT | Item Received! | Item Recebido! |
| MENU_START_GAME | START GAME | INICIAR JOGO |

2. **Import into Godot:** The engine automatically converts this `.csv` into optimized `.translation` binary companion files.
3. **Code Translation Hooks:** In scripts controlling UI labels or rich text, strings must pass through Godot's built-in translation wrapper method:

```gdscript
## Usage example inside inventory components or text headers:
func update_title_ui() -> void:
	# tr() automatically replaces the ID key with the active locale string configuration
	title_label.text = tr("HUD_INVENTORY_TITLE") 

```

---

## 4. Summary Checklist for Implementation Day

* [ ] Add `var current_locale: String = "pt_br"` inside `GameManager`.
* [ ] Migrate `npc_base.gd` from absolute paths to dynamic localized interpolation pathing strings.
* [ ] Create folder splittings under `res://dialogues/pt_br/` and `res://dialogues/en_us/`.
* [ ] Create `ui_translations.csv` for menus and register it in the project localization settings tab (`Project Settings -> Localization`).

---
