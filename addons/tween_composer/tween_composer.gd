@icon("uid://dwgblxlt6mirn")
class_name TweenComposer
extends Node
## Attach this node to any other node to tween its properties it.
## It can be used in 2D, 3D and Control nodes. [br]
## The Tweener uses a [TweenConfigCollection] resource to compose a tween and launch it. [br]
## You can save your [TweenConfigCollection] to reuse it. [br]
## [br]
## TweenComposer features: [br]
## * Dropdown for basic properties (position, rotation, scale, color/opacity). [br]
## * An "Other" field for changing a custom property (or paths, like "position:x".  [br]
## * Sending triggers as a signal so other nodes can be connected and interact with the tween.
## * "Hide before" and "Delete after" tweens.
##
## TODO: Known issue: Fix bug of parallel and delayed tween property if it is a relative as well (currently throws an error to warn the developer)
## TODO: Improvement: set_loops() is said to be buggy (or at least less sync-reliable). Investigate further.
##

#region Variables

@warning_ignore("unused_signal")
signal trigger_fired(trigger_name)


## The [TweenConfigCollection] to use in the animation.
@export var tween_configuration: TweenConfigCollection

@export_group("Tween settings")

## Total duration of tween, in seconds. [br]
## Tip: Change the duration_ratio in each [TweenConfigStep] to adjust the time of their individual tween.
@export var tween_duration: float = 1.0:
	set(value):
		tween_duration = max(0.0, value) # Blocks negative numbers

## Triggers the tween as it enters the scene.
@export var autostart: bool = true

## Adds a delay (in seconds) before the start of the tween.
@export var autostart_delay: float = 0.0:
	set(value):
		autostart_delay = max(0.0, value) # Blocks negative numbers

## Sets if the tween will be looped, or one-shot.
@export var loop: bool = true

## How many times the tween will loop before it stops. Use zero for infinite.
@export var loop_repetitions: int = 0

## Tween information is usually deleted after the tween is finished.
## Set this to true if you intend to play this tween again after it stops.
@export var persist_tween_information: bool = false

@export_subgroup("Parent settings")

## Sets if the parent entity will be hidden before the tween animatio begins. [br]
## Useful if the tween has an intro animation (fade-in, scale from zero, etc.).
@export var hide_parent_before_tween_start: bool = false

## Sets if the parent entity will be removed when the tween is ends. [br]
## The tween is considered "finished" after all loops have played (therefore if [loop_repetitions] 
## is set to zero, the animation will never end.
@export var delete_parent_after_tween_end:bool = false


@export_subgroup("Other settings")
@export var ignore_time_scale: bool = false
@export var set_pause_mode: Tween.TweenPauseMode = Tween.TweenPauseMode.TWEEN_PAUSE_BOUND

## Sets which process will be used for the tween.
## Use "Physics" if the tween requires frame-independent precision, better synchrony.
@export_enum("Idle", "Physics") var process_callback: int = 0


var parent_object: Node

var tween: Tween

## A Dictionary that stores all the initial property values, to be restored if [method reset_tween] is called.
var _initial_values: Dictionary

#endregion


func _ready() -> void:
	# Get parent
	parent_object = get_parent()
	
	if hide_parent_before_tween_start:
		_hide_parent()
	
	# Start the tween loop
	compose_tween()
	if autostart:
		if autostart_delay > 0.0:
			await get_tree().create_timer(autostart_delay).timeout
		_show_parent()
		play_tween()


func compose_tween() -> void:
	# Safety checks and warnings
	if tween_configuration == null:
		push_error("TweenComposer must have a TweenConfigCollection file!")
		return
	elif tween_configuration.tween_collection.size() == 0:
		push_error(tween_configuration.resource_name + "Configuration is empty (no tween steps set)!")
		return
	
	var tween_steps = tween_configuration.tween_collection

	# Calculate the duration of tween(s)
	
	## The sum of all duration ratios of non-parallel steps. Used to calculate the different timing of each step in the tween animation.
	var duration_ratio_total: float = 0.0
		
	for tw_step in tween_steps:
		
		# Warning
		if tw_step == null:
			push_error(tween_configuration.resource_name + ": Collection contains empty steps.")
			return
		
		if tw_step.parallel == false:
			duration_ratio_total += tw_step.duration_ratio
	
	# Crash prevention if all steps are parallel (or all their ratios are 0)
	if duration_ratio_total <= 0:
		push_warning(tween_configuration.resource_name + ": Total duration ratio = 0. Using 1.0 to avoid division by zero. It's likely that all steps are set to parallel.")
		duration_ratio_total = 1.0
	
	
	# Resestting the tween creation
	if tween:
		tween.kill()
	_initial_values = {}
	
	# Initial setup of tween parameters
	tween = create_tween()
	
	if loop:
		tween.set_loops(loop_repetitions)
	
	if process_callback == 1:
		tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	else:
		tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	
	tween.set_pause_mode(set_pause_mode)
	tween.set_ignore_time_scale(ignore_time_scale)
	
	
	# Creating the tweens by getting values from tween array.
	# (The big FOR loop starts here)
	for tw_step in tween_steps:
		
		if !tw_step.active:
			continue
		
		# Saving initial value of property to _initial_values dictionary
		if _initial_values.has(tw_step.property_name) == false: # Avoid duplicates, only get first value
			_initial_values[tw_step.property_name] = parent_object.get_indexed(tw_step.property_name)
		
		# Warnings:
		if parent_object is Node3D and tw_step.tween_property == tw_step.TweenOptions.MODULATE:
			push_error(tween_configuration.resource_name + "Node3D does not support 'modulate'. Use 'Other' to target a material property.")
			continue
		elif (parent_object is CollisionObject2D or parent_object is CollisionObject3D) and tw_step.tween_property == tw_step.TweenOptions.SCALE:
			push_error(tween_configuration.resource_name + "Changes to the Scale property in PhysicsBody objects may lead to unexpected results or even be overridden")
		
		
		# Basic tween setup
		tween.set_trans(tw_step.transition)
		tween.set_ease(tw_step.easing)
		tween.set_parallel(tw_step.parallel)
		
		var is_relative: bool = false
		if tw_step.relative_value == true:
			is_relative = true
		
		
		# Formatting the values depending on parent Node type and property tweened
		var target_value_formatted = tw_step.target_value
		
		if parent_object is Node2D or parent_object is Control:
			# Only get 1 rotation axis if 2D
			if tw_step.tween_property == tw_step.TweenOptions.ROTATION:
				target_value_formatted = target_value_formatted.x
			# Transform  Vector3 to Vector2 if 2D
			elif tw_step.tween_property == tw_step.TweenOptions.POSITION or tw_step.tween_property == tw_step.TweenOptions.SCALE and target_value_formatted is Vector3: 
				target_value_formatted = Vector2(target_value_formatted.x, target_value_formatted.y)
		
		
		# Constructing the tween property
		var tw_property = tween.tween_property(parent_object, tw_step.property_name, target_value_formatted, tween_duration * (tw_step.duration_ratio / duration_ratio_total))
		
		if is_relative:
			tw_property.as_relative()
		if tw_step.duration_delay > 0.0:
			if is_relative:
				push_error(tween_configuration.resource_name + ": TweenComposer currently doesn't support the combo of relative + parallel + delay")
			else:
				tw_property.set_delay(tween_duration * (tw_step.duration_delay / duration_ratio_total))
			
		for trigger in tw_step.send_triggers:
			tween.tween_callback(
				emit_signal.bind("trigger_fired", trigger)
			)
	
	# Connects the method to the function
	tween.connect("finished", _on_tween_finished)
	
	# Stops the tween, as this is just the compose_tween function!
	tween.stop()


#region Tween playback controls

## Stops the tween. Using [method play_tween] will start the animation again, from its current state.
func stop_tween() -> void:
	if _is_tween_valid():
		tween.stop()


## Pauses the tween. Using [method play_tween] will resume the animation.
func pause_tween() -> void:
	if _is_tween_valid():
		tween.pause()


## Plays the tween. If stopped, the tween will play again from the beginning using its current property 
## values. If paused, the tween will resume the animation.
func play_tween() -> void:
	_show_parent()
	if _is_tween_valid():
		tween.play()

## Resets the parent object's properties to their original state. Stops the tween.
func reset_tween() -> void:
	stop_tween()
	for path in _initial_values:
		parent_object.set_indexed(path, _initial_values[path])
	pass

## Resets the parent object's properties to their original state. Plays the tween.
func restart_tween() -> void:
	reset_tween()
	play_tween()


## Kills the tween. Not expected to be used externally.
func _kill_tween() -> void:
	if _is_tween_valid():
		tween.kill()

#endregion


#region Utility functions

## Checks if the tween in the TweenComposer is valid. Returns a warning if false.
func _is_tween_valid() -> bool:
	if tween.is_valid():
		return true
	else:
		push_warning(str(parent_object.name) + ": TweenComposer doesn't have an active tween.")
		return false

func _hide_parent() -> void:
	if parent_object is Control:
				parent_object.modulate = Color(1.0, 1.0, 1.0, 0.0)
	else:
		parent_object.hide()

func _show_parent() -> void:
	if parent_object is Control:
		parent_object.modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		parent_object.show()

func _delete_parent_entity() -> void:
	parent_object.set_process(false)
	parent_object.queue_free()

#endregion

func _on_tween_finished() -> void:
	if persist_tween_information:
		tween.stop()
	if delete_parent_after_tween_end:
		_delete_parent_entity()
