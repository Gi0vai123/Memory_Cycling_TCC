extends Area2D

@export var card_id: int = 0

@onready var front = $Front
@onready var back = $Back
@onready var qualid = $id

var virada := false
var bloqueada := false

signal carta_clicada(carta)

func _ready():
	qualid.text = str(card_id)   # pega o id e mostra no label
	mostrar_costas()
#função pra clicar e fazer a carta virar
func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		virar()
		emit_signal("carta_clicada", self)

func virar():
	if virada:
		mostrar_costas()
	else:
		mostrar_frente()

	virada = !virada
	mostrar_sprite()


func mostrar_frente():
	front.visible = true
	back.visible = false

func mostrar_costas():
	front.visible = false
	back.visible = true
	
func mostrar_sprite():
	if front.visible:
		$SpFrente.visible = true
		$SpCosta.visible = false
	else:
		$SpFrente.visible = false
		$SpCosta.visible = true

		
	
