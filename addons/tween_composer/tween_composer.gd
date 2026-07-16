@tool
@icon("uid://dwgblxlt6mirn")
class_name TweenComposer
extends Node
## Attach this node to any other node to tween its properties it.
## It can be used in 2D, 3D and Control nodes. [br]
## TweenComposer uses a [TweenSequence] resource to compose its tweens. This resource contains variables [br]
## to set the settings of the tween (like duration, loops, etc). And, more importantly, it houses another [br]
## resource, [TweenStepCollection], that contains all instructions for each step of the tween. [br]
## 
## You can save both [TweenSequence] and [TweenStepCollection] to reuse it in different game objects, [br]
## or to load different animations into the same one.
## [br][br]
##
## BUG: Known issue: Parallel and delayed tween property if it is a relative as well (currently throws an error to warn the user)
## 


@warning_ignore("unused_signal")
signal trigger_fired(trigger_name)


#region Variables

## The [TweenSequence] resource that will be used for composing each step of the tween.
@export var tween_sequence: TweenSequence

## Triggers the tween as it enters the scene.
@export var autostart: bool = true

## Adds a delay (in seconds) before the start of the tween.
@export var autostart_delay: float = 0.0:
	set(value):
		autostart_delay = max(0.0, value) # Blocks negative numbers


@export_subgroup("Preview")

## Toggle this on to preview the animation on the editor.
@export var preview: bool = false:
	set(value):
		## Safeguard: Preview is editor-only! Ignore true value it at runtime (and scene load).
		#if not Engine.is_editor_hint() or not is_node_ready():
			#preview = false
			#return
		
		preview = value
		
		if preview == true:
			if tween_sequence.tween_steps != null:
				_compose_tween()
				play_tween()
			else:
				push_warning(tween_sequence.sequence_name + ": Can't preview tween, no steps set.")
		if preview == false:
			reset_tween()
			_kill_tween()
		
		notify_property_list_changed()


@export_group("Parent settings")

## Sets if the parent entity will be hidden before the tween animation begins. [br]
## Useful if the tween has an intro animation (fade-in, scale from zero, etc.).
@export var hide_parent_before_tween_start: bool = false

## Sets if the parent entity will be removed when the tween is ends. [br]
## The tween is considered "finished" after all loops have played (therefore if [loop_repetitions] 
## is set to zero, the animation will never end.
@export var delete_parent_after_tween_end:bool = false


@export_group("Other settings")

@export var ignore_time_scale: bool = false
@export var set_pause_mode: Tween.TweenPauseMode = Tween.TweenPauseMode.TWEEN_PAUSE_BOUND

## Sets which process will be used for the tween.
## Use "Physics" if the tween requires frame-independent precision, better synchrony.
@export_enum("Idle", "Physics") var process_callback: int = 0


## The reference for the entity that will be animated by [TweenComposer]
var parent_object: Node

## The tween object that will be used by [TweenComposer].
var tween: Tween

## A Dictionary that stores all the initial property values, to be restored if [method reset_tween] is called.
var _initial_values: Dictionary

#endregion


func _ready() -> void:
	
	# Get parent
	parent_object = get_parent()
	
	if _is_parent_valid() == false:
		return
	
	# Stop function if code is running in the editor
	if Engine.is_editor_hint():
		return
	
	if hide_parent_before_tween_start:
		_hide_parent()
	
	# Compose the tween loop.
	if tween_sequence != null and tween_sequence.tween_steps != null:
		call_deferred("_compose_tween_at_ready")
	else:
		return

## Composes the tween and sets the autostart. Used only in [method _ready], as a deferred call 
## to ensure autostart_delay can be set externally in the tree.
func _compose_tween_at_ready() -> void:
	_compose_tween()
	if autostart:
		if autostart_delay > 0.0:
			await get_tree().create_timer(autostart_delay).timeout
		_show_parent()
		play_tween()


# Cleaning up the tween on delete
func _exit_tree() -> void:
	# Reset the tween original values if leaving editor
	if Engine.is_editor_hint():
		reset_tween()
	# Ensure tween is killed to prevent leaks
	_kill_tween()


## The main function of Tween Composer. Iterates through all the configuration resources to compose 
## the tween animation. Will not play the animation at the end (use [method play_tween] to do so).
func _compose_tween() -> void:
	
	if _is_tween_config_valid() == false:
		return
	
	if _is_parent_valid() == false:
		return
	
	
	var tw_steps = tween_sequence.tween_steps.step_collection


	# Calculate the duration of tween(s)
	
	## The sum of all duration ratios of non-parallel steps. Used to calculate the different timing of each step in the tween animation.
	var duration_ratio_total: float = 0.0
		
	for tw_step in tw_steps:
		
		# Warning
		if tw_step == null:
			push_error(tween_sequence.tween_steps.resource_name + ": Collection contains empty steps.")
			return
		
		if tw_step.parallel == false:
			duration_ratio_total += tw_step.duration_ratio
	
	
	# Crash prevention if all steps are parallel (or all their ratios are 0)
	if duration_ratio_total <= 0:
		push_warning(tween_sequence.tween_steps.resource_name + ": Total duration ratio = 0. Using 1.0 to avoid division by zero. It's likely that all steps are set to parallel.")
		duration_ratio_total = 1.0
	
	
	# Resestting the tween creation
	if tween:
		tween.kill()
	_initial_values = {}
	
	
	# Initial setup of tween parameters
	tween = create_tween()
	
	if tween_sequence.loop:
		tween.set_loops(tween_sequence.loop_repetitions)
	
	if process_callback == 1:
		tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	else:
		tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	
	tween.set_pause_mode(set_pause_mode)
	tween.set_ignore_time_scale(ignore_time_scale)
	
	
	# Creating the tweens by getting values from tween array.
	# (The big loop starts here)
	for tw_step in tw_steps:
		
		if !tw_step.active:
			continue
		
		# Saving initial value of property to _initial_values dictionary
		if _initial_values.has(tw_step.property_name) == false: # Avoid duplicates, only get first value
			_initial_values[tw_step.property_name] = parent_object.get_indexed(tw_step.property_name)
		
		# Warnings:
		if parent_object is Node3D and tw_step.tween_property == tw_step.TweenOptions.MODULATE:
			push_error(tween_sequence.tween_steps.resource_name + ": Node3D does not support 'modulate'. Use 'Other' to target a material property.")
			continue
		elif (parent_object is CollisionObject2D or parent_object is CollisionObject3D) and tw_step.tween_property == tw_step.TweenOptions.SCALE:
			push_error(tween_sequence.tween_steps.resource_name + ": Changes to the Scale property in PhysicsBody objects may lead to unexpected results or even be overridden")
		
		# Basic tween setup
		tween.set_trans(tw_step.transition)
		tween.set_ease(tw_step.easing)
		tween.set_parallel(tw_step.parallel)
		
		var is_relative: bool = false
		if tw_step.relative_value == true:
			is_relative = true
		
		# Getting proper values from either simple values or expressions:
		var target_value_formatted: Variant
		match  tw_step.value_source:
			TweenStepItem.ValueSource.VALUE:
				target_value_formatted = tw_step.target_value
			TweenStepItem.ValueSource.EXPRESSION:
				target_value_formatted = _resolve_expression(tw_step)
		
		# Formatting the value depending on parent Node type and property tweened
		if parent_object is Node2D or parent_object is Control:
			# Only get 1 rotation axis if 2D
			if tw_step.tween_property == tw_step.TweenOptions.ROTATION and target_value_formatted is Vector3:
				target_value_formatted = target_value_formatted.x
			# Transform  Vector3 to Vector2 if 2D
			elif (tw_step.tween_property == tw_step.TweenOptions.POSITION or tw_step.tween_property == tw_step.TweenOptions.SCALE) and target_value_formatted is Vector3:
				target_value_formatted = Vector2(target_value_formatted.x, target_value_formatted.y)
		
		
		# Constructing the tween property
		var tw_property = tween.tween_property(parent_object, tw_step.property_name, target_value_formatted, tween_sequence.tween_duration * (tw_step.duration_ratio / duration_ratio_total))
		if is_relative:
			tw_property.as_relative()
		if tw_step.duration_delay > 0.0:
			if is_relative:
				push_error(tween_sequence.tween_steps.resource_name + ": TweenComposer currently doesn't support the combo of relative + parallel + delay")
			else:
				tw_property.set_delay(tween_sequence.tween_duration * (tw_step.duration_delay / duration_ratio_total))
			
		for trigger in tw_step.send_triggers:
			tween.tween_callback(
				emit_signal.bind("trigger_fired", trigger)
			)
	
	# Connects the tween finishing signal to the function
	tween.connect("finished", _on_tween_finished)
	
	# Stops the tween, as this is just the compose_tween function!
	tween.stop()


#region Load Functions

## Loads a new [TweenSequence] resource.
func load_tween_sequence(new_resource: TweenSequence) -> void:
	reset_tween()
	tween_sequence = new_resource
	_compose_tween()

## Loads a new [TweenSequence] resource. [br]
## Starts the tween animation after loading.
func load_tween_sequence_and_start(new_resource: TweenSequence) -> void:
	reset_tween()
	tween_sequence = new_resource
	_compose_tween()
	play_tween()


## Loads a new [TweenStepCollection] resource, while keeping the [TweenSequence]'s settings intact.
func load_tween_steps(config:TweenStepCollection) -> void:
	reset_tween()
	tween_sequence.tween_steps = config
	_compose_tween()

## Loads a new [TweenStepCollection] resource, while keeping the [TweenSequence]'s settings intact. [br]
## Starts the tween animation after loading.
func load_tween_steps_and_start(config:TweenStepCollection) -> void:
	reset_tween()
	tween_sequence.tween_steps = config
	_compose_tween()
	play_tween()

#endregion


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


## Resets the parent object's properties to their original state. Plays the tween.
func restart_tween() -> void:
	reset_tween()
	play_tween()


## Kills the tween. Not expected to be used.
func _kill_tween() -> void:
	if _is_tween_valid():
		tween.kill()

#endregion


#region Utility functions

## Checks if the tween in the TweenComposer is valid. Returns a warning if false.
func _is_tween_valid() -> bool:
	if tween == null:
		return false
	elif tween.is_valid():
		return true
	else:
		return false


func _is_tween_config_valid() -> bool:
	# Safety checks and warnings
	if tween_sequence.tween_steps == null:
		push_error(str(parent_object.name) + ": TweenComposer must have a TweenConfigCollection file!")
		return false
	elif tween_sequence.tween_steps.step_collection.size() == 0:
		push_error(str(parent_object.name) + ": " + str(tween_sequence.tween_steps.resource_name) + "Configuration is empty (no tween steps set)!")
		return false
	else:
		return true


func _is_parent_valid() -> bool:
	if parent_object == null:
		return false
		push_warning("TweenComposer: Parent not found")
	else:
		return true


func _resolve_expression(tw_step: TweenStepItem) -> Variant:
	var text: String = tw_step.expression_text
	
	if text.is_empty():
		push_error(tween_sequence.tween_steps.resource_name + " / " + tw_step.step_name + ": Expression is empty!")
		return tw_step.target_value # Fallback to default target value in step
	
	var expression: Expression = Expression.new()
	expression.parse(text, ["parent", "initial"])
	
	var result: Variant = expression.execute([parent_object, _initial_values])
	if expression.has_execute_failed():
		push_error(tween_sequence.tween_steps.resource_name + " / " + tw_step.step_name + ": Expression execution failed!")
		return tw_step.target_value # Fallback to default target value in step
	
	return result


func _hide_parent() -> void:
	# INFO: Toggling "visible" in Control nodes can mess with the UI position, so the solution was to "turn invisible" instead.
	if parent_object is Control:
		parent_object.modulate = Color(1.0, 1.0, 1.0, 0.0)
	else:
		parent_object.hide()


func _show_parent() -> void:
	# INFO: Toggling "visible" in Control nodes can mess with the UI position, so the solution was to "turn invisible" instead.
	if parent_object is Control:
		parent_object.modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		parent_object.show()


func _delete_parent_entity() -> void:
	parent_object.set_process(false)
	parent_object.queue_free()


func _on_tween_finished() -> void:
	# End preview if running on editor.
	if Engine.is_editor_hint():
		preview = false
		return
	elif tween_sequence.persist_tween_information:
		tween.stop()
	elif delete_parent_after_tween_end:
		_delete_parent_entity()


func _validate_property(property: Dictionary) -> void:
	# Safeguard against preview left ON and running the game.
	if property.name == "preview":
		property.usage &= ~PROPERTY_USAGE_STORAGE # tilde to remove a flag, that's new for me!

func _notification(what: int) -> void:
	# Safeguard against preview being on when saving a project (could lead to modified values being saved)
	if what == NOTIFICATION_EDITOR_PRE_SAVE:
		if preview == true:
			preview = false

#endregion
