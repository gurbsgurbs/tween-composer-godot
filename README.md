
# Tween Composer for Godot

![A hero image showing the logotype and examples of the inspector's UI](https://private-user-images.githubusercontent.com/231096855/584066265-2253af29-2275-4471-ab9b-53c4669543dc.png?jwt=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3NzcyNzc1MTgsIm5iZiI6MTc3NzI3NzIxOCwicGF0aCI6Ii8yMzEwOTY4NTUvNTg0MDY2MjY1LTIyNTNhZjI5LTIyNzUtNDQ3MS1hYjliLTUzYzQ2Njk1NDNkYy5wbmc_WC1BbXotQWxnb3JpdGhtPUFXUzQtSE1BQy1TSEEyNTYmWC1BbXotQ3JlZGVudGlhbD1BS0lBVkNPRFlMU0E1M1BRSzRaQSUyRjIwMjYwNDI3JTJGdXMtZWFzdC0xJTJGczMlMkZhd3M0X3JlcXVlc3QmWC1BbXotRGF0ZT0yMDI2MDQyN1QwODA2NThaJlgtQW16LUV4cGlyZXM9MzAwJlgtQW16LVNpZ25hdHVyZT1lOTRkYTYwOWI3NjRkYzIyZmJkNTM3ZjRiNzNkNmI4NWIwYWIyZTVlMDY1ZmRiMjEyM2EwNzg4OGM4YTNiODJlJlgtQW16LVNpZ25lZEhlYWRlcnM9aG9zdCZyZXNwb25zZS1jb250ZW50LXR5cGU9aW1hZ2UlMkZwbmcifQ.23cqRd_8ZIQXDJiqrfkIXh_Jr9l0vG043J-fl3JhUmg)

[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](https://choosealicense.com/licenses/mit/)

A tool for creating tween animations using the inspector tab in Godot. It works on 2D, 3D and UI objects!
## Features

- Tween configurations can be saved as resources and reused in different entities.
- Dropdown for basic properties (position, rotation, scale, color/opacity), plus an "Other" field for changing a custom property (using property paths, e.g. `position:x`).
- Sending triggers as a signal so other nodes can be connected and interact with the tween.
- Playback options to pause/play, reset, restart...
- "Hide before" and "Delete after" tween animation.
## How to Use
Tween Composer works with `Node2D`, `Node3D` and `Control` nodes, but it can be used in virtually any node that needs tweens.

To animate an object, simply attach TweenComposer as its child.

Tween Composer uses two resources to work:
1. **TweenConfigStep**: A set of instructions for a tween step (what property, transition type, easing, etc)
1. **TweenConfigCollection**: An array of tween steps that will be used to compose your animation. This can be saved and reused.
## Installation
You can find Tween Composer in the Asset Library inside Godot.

You can also:
- Create a addons folder on your Godot project
- Add the tween_composer folder inside it.
- Enable the plugin in `Project Settings...` and `Plugins` tab
