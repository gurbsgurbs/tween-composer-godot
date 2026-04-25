@tool
class_name TweenConfigCollection
extends Resource

## TweenConfigCollection is a simple resource that bundles all the [TweenConfigItem]
## resources that will be tweened.

## Variable used for identifying steps in the inspector list.
@export var tween_name: String:
	set(value):
		tween_name = value
		resource_name = value
		emit_changed()
	get:
		return tween_name

# Making sure the resources in the array are not linked
@export var tween_collection: Array[TweenConfigItem]= []:
	set(value):
		tween_collection = value
		for item in tween_collection:
			if item:
				item = item.duplicate()

# Making sure the resource and it's sub-resources are unique
func _init() -> void:
	resource_local_to_scene = true
