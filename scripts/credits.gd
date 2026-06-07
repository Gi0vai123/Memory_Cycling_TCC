extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	$CanvasLayer/credits/VoltarCreditos.grab_focus()



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_voltar_creditos_pressed() -> void:
	print("aaaaaaaaaaaaaaa")
	get_tree().change_scene_to_file("res://scenes/menu_screen.tscn")
	
	pass # Replace with function body.
