extends Control

export(bool) var pause_on_activate := true

onready var input := $MarginContainer/VBoxContainer/LineEdit
onready var output := $MarginContainer/VBoxContainer/TextEdit
onready var command_handler := $CommandHandler

onready var mouse_mode := Input.get_mouse_mode()
onready var time_scale := Engine.time_scale

func on_activate():
	mouse_mode = Input.get_mouse_mode()
	time_scale = Engine.time_scale
	if pause_on_activate:
		#Engine.time_scale = 0.0
		get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	input.clear()
	input.grab_focus()
	input.set_process_input(true)

func on_deactivate():
	Input.set_mouse_mode(mouse_mode)
	# Engine.time_scale = time_scale
	if pause_on_activate:
		get_tree().paused = false
	input.clear()
	input.set_process_input(false)

func parse_command(text: String):
	output_text(text)
	var words = text.split(" ", false)
	words = Array(words)
	var result := ""
	if len(words) > 0:
		var command := words[0] as String
		var args := words.slice(1, len(words) - 1) as Array
		result = command_handler.execute_command(command, args)
	output_result(result)
	output.scroll_vertical = 99999999

func output_text(text: String):
	output.text += "\n>>\t" + text

func output_result(text: String):
	output.text += "\n\t\t" + text

func _on_LineEdit_text_entered(new_text: String) -> void:
	parse_command(new_text)
	input.clear()

func _on_CommandHandler_clear_console() -> void:
	output.text = "DebugConsole [~ enable/disable]"
