extends Node2D

const DAMAGE_NUMBER_UP = preload("uid://doi63xjp1hjv5")

@onready var sprite_2d: Sprite2D = $Sprite2D

func _on_button_pressed() -> void:
	damage_ui()

func damage_ui() -> void:
	var dmg_ui = DAMAGE_NUMBER_UP.instantiate()
	dmg_ui.position = sprite_2d.position
	add_child(dmg_ui)
