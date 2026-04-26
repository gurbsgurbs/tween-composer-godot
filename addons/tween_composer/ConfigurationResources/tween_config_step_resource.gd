@tool
class_name TweenConfigStep
extends Resource
## TweenConfigStep is the resource that houses all the configuration of each tween instruction 
## for the Tween Composer to work on the tween.

#region Property options to be added to the inspector UI

## The different properties that are added to the "Property Name" dropdown in the inspector. 
## It's a list of popular options, that can grow over time as needed.
enum TweenOptions { POSITION, ROTATION, SCALE, MODULATE, OTHER }

## The dictionary that contains the peculiarities of each of the options on [TweenOptions].
const PROPERTY_RULES: Dictionary = {
	TweenOptions.POSITION: {"path": "position", "default": Vector3.ZERO, "type": TYPE_VECTOR3},
	TweenOptions.ROTATION: {"path": "rotation_degrees", "default": Vector3.ZERO, "type": TYPE_VECTOR3},
	TweenOptions.SCALE: {"path": "scale", "default": Vector3.ONE, "type": TYPE_VECTOR3},
	TweenOptions.MODULATE: {"path": "modulate", "default": Color.WHITE, "type": TYPE_COLOR},
	TweenOptions.OTHER: {"path": "", "default": 0.0, "type": TYPE_FLOAT}
}

## Sets the name of the tween step. [br]
## Useful for identifying steps in the inspector list, and for easier manipulation of the resource 
## in the array.
@export var nickname: String:
	set(value):
		nickname = value
		resource_name = value
		#notify_property_list_changed() # BUG: Can't use this or Godot's text field will bug!
	get:
		return nickname

## If false, disables this step when composing the tween in the [TweenComposer]. [br]
## Useful for creating the animation and testing things out without having to delete a step.
@export var active: bool = true

@export_group("Tween parameters")
@export var transition: Tween.TransitionType = Tween.TransitionType.TRANS_QUAD ## What transition will be used for this step.
@export var easing: Tween.EaseType = Tween.EaseType.EASE_IN ## What easing will be used for this step.
@export var parallel: bool = false ## Is this a step that will run in parallel with the previous one?
@export var duration_ratio: float = 1.0 ## How faster will this tween run, compared to others in the [TweenConfigCollection]. If this is a parallel tween, its duration_ratio shouldn't be higher than its non-parallel tween partner.
@export var duration_delay: float = 0.0 ## How long this step should wait before firing. Also uses the ratio value (e.g. 0.5 for half-time). Also works with parallel steps.

@export_subgroup("Triggers")
@export var send_triggers:Array[String] ## Sends each string in this array as signals via the [signal TweenComposer.signal_fired]

@export_group("Tween Property")
@export var relative_value: bool = true ## Is the property's value change absolute ("move to position 100 on X") or relative ("move by 100 pixels to the right")

var property_name: String
var target_value: Variant = 0.0

## What property will be changed in this tween step.
@export var tween_property: TweenOptions:
	set(value):
		tween_property = value
		var rule: Dictionary = PROPERTY_RULES[value]
		
		# Define property_name if using OTHER as option
		if value == TweenOptions.OTHER:
			property_name = custom_property
			target_value = type_convert(target_value, custom_property_type)
		else:
			property_name = rule.path
			target_value = type_convert(rule.default, rule.type)
		notify_property_list_changed() # Update the inspector UI


var custom_property: String = "position:x":
	set(value):
		custom_property = value
		# Update the property name with the custom property field
		if tween_property == TweenOptions.OTHER: 
			property_name = value


var custom_property_type: int = TYPE_FLOAT:
	set(value):
		custom_property_type = value
		target_value = type_convert(target_value, value)
		notify_property_list_changed() # Update the inspector UI


func _init() -> void:
	# Make every item in the collection unique
	resource_local_to_scene = true
	# Set the default value to ensure target_value variant is set so it doesn't return null
	tween_property = TweenOptions.POSITION


# Draws the dynamic variables in the inspector
func _get_property_list() -> Array:
	var properties = []
	
	# Must add property_name to storage so it isn't lost, because it's not an @export variable.
	properties.append({
		"name": "property_name",
		"type": TYPE_STRING,
		"usage": PROPERTY_USAGE_STORAGE # Save to file but don't show in Inspector
	})
	
	if tween_property == TweenOptions.OTHER:
		properties.append({
			"name": "custom_property",
			"type": TYPE_STRING,
			"usage": PROPERTY_USAGE_DEFAULT
		})
		properties.append({
			"name": "custom_property_type",
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_ENUM, #Using the 
			"hint_string": "Float:3,Int:2,Vector2:5,Vector3:9,Color:20,Bool:1",
			"usage": PROPERTY_USAGE_DEFAULT
		})
		
	# Set the proper type depending on option picked
	var property_type: int
	if tween_property == TweenOptions.OTHER:
		property_type = custom_property_type
	else:
		property_type = PROPERTY_RULES[tween_property].type
	
	properties.append({
		"name": "target_value",
		"type": property_type,
		"usage": PROPERTY_USAGE_DEFAULT
	})
	
	return properties
