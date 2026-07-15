
# Tween Composer for Godot

![A hero image showing the logotype and examples of the inspector's UI](https://raw.githubusercontent.com/gurbsgurbs/tween-composer-godot/refs/heads/main/.github/assets/TweenComposer_Hero.png)

[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](https://choosealicense.com/licenses/mit/)

A tool for creating tween animations using the inspector tab in Godot. It works on 2D, 3D and UI objects!

Works with Godot 4.4+

Head to the itch.io page for more updates: https://gurbsgurbs.itch.io/tween-composer

## Features

- Tweens can be saved as resources and reused in different entities.
- Dropdown for basic properties (position, rotation, scale, color/opacity), plus an "Other" field for changing ANY property using property paths, e.g. `position:x`.
- Sending triggers as a signal so other nodes can be connected and interact with the tween. Fire that particle mid-tween!
- Playback options to pause/play, reset or restart.
- "Hide before" and "Delete after" tween, to simplify the parent's spawning/destroying animations.
- Load your tween resources to play different animations.
- Use expressions for random values, or to get values from variables.
- Preview the tween directly in the editor!

## How to Use
Tween Composer works with `Node2D`, `Node3D` and `Control` nodes, but it can be used in virtually any node that needs tweens.

### To animate an object:
1. Attach TweenComposer as its child.
2. Use the inspector to create a new Sequence, with a set of tween steps, and set the tween properties for duration, loops, etc.

#### To use expressions:
<details>
  <summary>Using expressions</summary>

* In the step configurations, set  the Value Source to `Expression`.

With expressions you can:
* Use random values: e.g. randf_range(-100,100)
* Use the value from variables declared in the parent node, using `parent`. e.g. `parent.some_variable`
* Call initial values using `initial`. e.g. `initial.position`
The expression input works for the pre-defined properties in the dropdown (position, rotation etc) as well as the "Other" option.

⚠️ Pay extra attendtion:
Use the proper type when writing your expression, or you'll get errors or unexpected behaviors.

Some other expression examples:

* For using a random value in a Position 2D: `Vector2(randf_range(-10,10),10)`
* For tweening back to the initial Color of a sprite: `initial.modulate`
* For scaling up a "damage number" label, based on the damage value: `Vector2(clampf(remap(parent.damage_amount, 0.0, 1000.0, 1.0, 2.0), 1.0, 2.0)` (scale will proportionally double if the damage is between 0 to 1000).
</details>

## Installation
You can find Tween Composer in the Asset Library inside Godot.

You can also:
1. Download the latest version under "Releases"
1. Unzip the file on your Godot project's root folder
1. Enable the plugin in `Project Settings...` and `Plugins` tab

## Improvements / Future features
A couple of ideas to expand TweenComposer in the future:
- Implement tween_callback() and tween_method(), somehow.
