@tool
class_name TweenStepCollection
extends Resource
## TweenStepCollection is a simple resource that bundles all the [TweenStepItem]
## resources into a single, saveable file.

## Sets the name of the tween. Not used in the code.
@export var tween_name: String:
	set(value):
		tween_name = value
		resource_name = value
		emit_changed()
	get:
		return tween_name

# Making sure the resources in the array are not linked
@export var step_collection: Array[TweenStepItem]= []

# Making sure the resource and it's sub-resources are unique
func _init() -> void:
	resource_local_to_scene = true
