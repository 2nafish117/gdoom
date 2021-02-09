extends Node

enum {MODE_KEYBOARD_MOUSE, MODE_JOYPAD}

var input_mode = MODE_KEYBOARD_MOUSE
var to_string := {MODE_KEYBOARD_MOUSE: "ModeKeyboardMouse", MODE_JOYPAD: "ModeJoypad"}
var count := 0

func get_input_mode():
	return to_string[input_mode]

func _ready() -> void:
	Dbg.stats.add_stat("input_mode", self, "get_input_mode", true)

func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouse:
		input_mode = MODE_KEYBOARD_MOUSE
	
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		input_mode = MODE_JOYPAD
