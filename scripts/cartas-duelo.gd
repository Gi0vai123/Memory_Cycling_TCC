extends Area2D

@export var card_id: int = 0
@export var lado: String = "" 

var tween_rotacao: Tween

@onready var front = $Front
@onready var back = $Back
@onready var qualid = $id

var pode_animar := true
var virada := false
var bloqueada := false
var z_original = 0

signal carta_clicada(carta)

const SPRITES = {
	1:  "res://prefabs/frente-cartas/frente-carta-1.jpg",
	2:  "res://prefabs/frente-cartas/frente-carta-2.jpg",
	3:  "res://prefabs/frente-cartas/frente-carta-3.jpg",
	4:  "res://prefabs/frente-cartas/frente-carta-4.jpg",
	5:  "res://prefabs/frente-cartas/frente-carta-5.jpg",
	6:  "res://prefabs/frente-cartas/frente-carta-6.jpg",
	7:  "res://prefabs/frente-cartas/frente-carta-7.png",
	8:  "res://prefabs/frente-cartas/frente-carta-8.jpg",
	9:  "res://prefabs/frente-cartas/frente-carta-9.jpg",
	10: "res://prefabs/frente-cartas/frente-carta-10.jpg",
	11: "res://prefabs/frente-cartas/frente-carta-11.jpg",
	12: "res://prefabs/frente-cartas/frente-carta-12.jpg",
	13: "res://prefabs/frente-cartas/frente-carta-13.jpg",
}

func carregar_sprite():
	if card_id in SPRITES:
		var texture = load(SPRITES[card_id])
		if texture:
			$SpFrente.texture = texture
		else:
			push_error("Sprite não encontrado para card_id: " + str(card_id))
	else:
		push_error("card_id fora do range: " + str(card_id))

func _ready():
	z_original = z_index
	atualizar_id_visual()
	carregar_sprite()
	mostrar_costas()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func iniciar_animacao(atraso: float = 0.0):
	pode_animar = false
	await get_tree().create_timer(atraso).timeout
	virar()
	await get_tree().create_timer(2.0).timeout
	virar()
	pode_animar = true

func _on_mouse_entered():
	if not pode_animar or bloqueada:
		return
	
	z_index = 100
	
	var t = create_tween()
	t.tween_property(self, "scale", Vector2(1, 1), 0.15)
	
	animar_loop_rotacao()

func _on_mouse_exited():
	z_index = z_original
	
	var t = create_tween()
	t.tween_property(self, "scale", Vector2(0.7, 0.7), 0.15)
	
	parar_rotacao()

func animar_loop_rotacao():
	if tween_rotacao:
		tween_rotacao.kill()

	tween_rotacao = create_tween().set_loops()

	tween_rotacao.tween_property(self, "rotation_degrees", -6, 0.8).from(6)
	tween_rotacao.tween_property(self, "rotation_degrees", 6, 0.8).from(-6)

func parar_rotacao():
	if tween_rotacao:
		tween_rotacao.kill()
	
	var t = create_tween()
	t.tween_property(self, "rotation_degrees", 0, 0.2)

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		if bloqueada:
			return
		
		emit_signal("carta_clicada", self)

func mostrar_frente():
	$SpFrente.visible = true
	$SpCosta.visible = false
	front.visible = true
	back.visible = false

func mostrar_costas():
	$SpFrente.visible = false
	$SpCosta.visible = true
	front.visible = false
	back.visible = true

func virar():
	if virada:
		mostrar_costas()
	else:
		mostrar_frente()
	virada = !virada

func mostrar_sprite():
	var sp_frente = get_node_or_null("SpFrente")
	var sp_costa = get_node_or_null("SpCosta")

	if sp_frente == null or sp_costa == null:
		return

	if front.visible:
		sp_frente.visible = true
		sp_costa.visible = false
	else:
		sp_frente.visible = false
		sp_costa.visible = true


func bloquear():
	bloqueada = true

func desbloquear():
	bloqueada = false

func atualizar_id_visual():
	if qualid:
		qualid.text = str(card_id)
