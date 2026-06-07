extends Resource
class_name BattleEncounter

@export_group("Audio & Visuals")
@export var background_texture: Texture2D
@export var battle_music: AudioStream

@export_group("Waves & Enemies")

@export var waves: Array[Resource] = []

# Reward item
@export var victory_reward_item: ItemData
