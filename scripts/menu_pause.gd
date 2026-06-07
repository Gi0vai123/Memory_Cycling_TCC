extends Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	$CanvasLayer/ColorRect/Continuar.pressed.connect(despausar)
	$CanvasLayer/ColorRect/Creditos.pressed.connect(_ir_creditos)
	$CanvasLayer/ColorRect/Sair.pressed.connect(_ir_menu)

func _ir_creditos() -> void:
	get_tree().change_scene_to_file("res://scenes/credits.tscn")
func _ir_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menu_screen.tscn")

func pausar() -> void:
	$CanvasLayer/ColorRect.visible = true
	get_tree().paused = true
	$CanvasLayer/ColorRect/Continuar.grab_focus()

func despausar() -> void:
	$CanvasLayer/ColorRect.visible = false
	get_tree().paused = false

func _on_credits_exit_pressed() -> void:
	$CanvasLayer/credits.visible = false
	pass # Replace with function body.
