extends Node2D

@onready var label: Label = $Label

func _ready() -> void:
	label.text = "+" + str(randi_range(100,500))
