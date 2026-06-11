class_name ItemData
extends Resource

enum ItemType { CONSUMABLE, EQUIPMENT, QUEST }
enum EffectType { NONE, HEAL, EQUIP_ATK, KEY_VERIFY }

@export var id: String = ""
@export var item_name: String = "Item"
@export_multiline var description: String = ""
@export var texture: Texture2D

@export_group("Categorization & Effects")
@export var item_type: ItemType = ItemType.CONSUMABLE
@export var effect_type: EffectType = EffectType.NONE
@export var effect_value: int = 0
@export var is_unique: bool = false
