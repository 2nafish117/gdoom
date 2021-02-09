extends Node

signal clear_console

enum ArgType {
	INT,
	FLOAT,
	BOOL,
	STRING,
}

var valid_commands := {
	"clear": [],
	"cmd1": [ArgType.STRING],
	"cmd2": [ArgType.BOOL, ArgType.STRING],
}

func clear():
	emit_signal("clear_console")
	return ""

func cmd2(arg1: bool, arg2: String):
	return "ran cmd2 with " + str(arg1) + " " + arg2

func is_valid_command(cmd: String, args: Array) -> bool:
	if cmd in valid_commands and len(args) == len(valid_commands[cmd]):
		return true
	return false

func get_type(arg: String) -> int:
	if arg.is_valid_integer():
		return ArgType.INT
	elif arg.is_valid_float():
		return ArgType.FLOAT
	elif arg == "true" or arg == "false":
		return ArgType.BOOL
	return ArgType.STRING

func get_type_str(type: int) -> String:
	match type:
		ArgType.INT:
			return "int"
		ArgType.FLOAT:
			return "float"
		ArgType.BOOL:
			return "bool"
	return "string"

func convert_type(val, type: int):
	match type:
		ArgType.INT:
			return int(val)
		ArgType.FLOAT:
			return float(val)
		ArgType.BOOL:
			return true if val == "true" else false
	return val

func execute_command(cmd: String, args: Array) -> String:
	if not (cmd in valid_commands):
		return '[Error] "' + cmd + '" not recognised'
	if len(args) != len(valid_commands[cmd]):
		return "[Error] expected " + str(len(valid_commands[cmd])) + " args, got " + str(len(args)) + " instead"
	for idx in range(len(valid_commands[cmd])):
		var required_type := valid_commands[cmd][idx] as int
		var got_type := get_type(args[idx]) as int
		if got_type != required_type:
			return "[Error] expected arg " + str(idx + 1) + " as " + get_type_str(required_type) + ", got " + get_type_str(got_type) + " instead"
		args[idx] = convert_type(args[idx], got_type)
	if not has_method(cmd):
		return "[Error] command not implemented"
	return callv(cmd, args)
