extends Control

func _ready() -> void:
	
	
	
	pass


func _process(delta: float) -> void:
	
	
	
	pass

func _on_start_btn_pressed() -> void:
	
	get_tree().change_scene_to_file("res://scenes/modoP.tscn")
	
	pass

func _on_options_btn_pressed() -> void:
	
	$option_menu.visible = true
	
	pass

func _on_exit_option_btn_pressed() -> void:
	
	$option_menu.visible = false
	
	pass

func _on_credits_btn_pressed() -> void:
	
	$credits.visible = true
	
	pass

func _on_credits_exit_pressed() -> void:
	
	$credits.visible = false
	
	pass

func _on_exit_btn_pressed() -> void:
	
	get_tree().quit()
	
	pass


func _on_donate_btn_pressed() -> void:
	
	print("clicou")
	$qr_code.visible = true
	
	pass

func _on_exit_donate_btn_pressed() -> void:
	
	$qr_code.visible = false
	
	pass
