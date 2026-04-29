
# Tween Composer for Godot

![A hero image showing the logotype and examples of the inspector's UI](https://raw.githubusercontent.com/gurbsgurbs/tween-composer-godot/refs/heads/main/.github/assets/TweenComposer_Hero.png)

[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](https://choosealicense.com/licenses/mit/)

A tool for creating tween animations using the inspector tab in Godot. It works on 2D, 3D and UI objects!

## Features

- Tween configurations can be saved as resources and reused in different entities.
- Dropdown for basic properties (position, rotation, scale, color/opacity), plus an "Other" field for changing a custom property (using property paths, e.g. `position:x`).
- Sending triggers as a signal so other nodes can be connected and interact with the tween.
- Playback options to pause/play, reset, restart...
- "Hide before" and "Delete after" tween, to simplify the parent's spawning/destroying animations.
- 
## How to Use
Tween Composer works with `Node2D`, `Node3D` and `Control` nodes, but it can be used in virtually any node that needs tweens.

To animate an object:
1. Attach TweenComposer as its child.
2. Use the inspector to create a new set of tween steps, and set the tween properties for duration, loops, etc.

Tween Composer uses two resources to work:
- **TweenConfigStep**: A set of instructions for a tween step (what property, transition type, easing, etc)
- **TweenConfigCollection**: An array of tween steps that will be used to compose your animation. This can be saved and reused.

## Installation
You can find Tween Composer in the Asset Library inside Godot.

You can also:
- Create a addons folder on your Godot project
- Add the tween_composer folder inside it.
- Enable the plugin in `Project Settings...` and `Plugins` tab

## Improvements / Future features
A couple of ideas to expand TweenComposer in the future:
- Preview on editor (great for working on the animation without having to run it every time!)
- Implement tween_callback() and tween_method(), somehow.
- Using variables as property values, to make dynamic animations.
