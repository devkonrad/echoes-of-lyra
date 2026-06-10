extends Resource
class_name BattleEncounter

@export_group("Audio & Visuals")
@export var background_texture: Texture2D
@export var battle_music: AudioStream

@export_group("Waves & Enemies")
@export var waves: Array[Resource] = []

@export_group("Rewards")
## The ID from the JSON database to award upon winning (e.g., 'potion_health', 'iron_sword'). Leave empty for no reward.
@export var victory_reward_id: String = ""
