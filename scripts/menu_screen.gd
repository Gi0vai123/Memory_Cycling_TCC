extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float):
	pass



func _on_start_btn_pressed():
	get_tree().change_scene_to_file("res://memory.tscn")
	# tenta iniciar kekw


func _on_credits_btn_pressed() -> void:
	# é uma outra cena
	pass # Replace with function body.


func _on_exit_btn_pressed() -> void:
	get_tree().quit() #kita
