extends Area2D
@export var card_id: int = 0
var tween_rotacao: Tween
var tween_hover: Tween
@onready var sp_frente = $SpFrente
@onready var sp_costa = $SpCosta
@onready var qualid = $id
var pode_animar := false
var virada := false
var virando := false
var mouse_dentro := false
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
	14: "res://prefabs/frente-cartas/frente-carta-14.jpg",
	15: "res://prefabs/frente-cartas/frente-carta-15.jpg",
	16: "res://prefabs/frente-cartas/frente-carta-16.jpg",
	17: "res://prefabs/frente-cartas/frente-carta-17.jpg",
	18: "res://prefabs/frente-cartas/frente-carta-18.jpg",
	19: "res://prefabs/frente-cartas/frente-carta-19.jpg",
	20: "res://prefabs/frente-cartas/frente-carta-20.jpg",
	21: "res://prefabs/frente-cartas/frente-carta-21.jpg",
}

func _ready():
	z_original = z_index
	qualid.text = str(card_id)
	mostrar_costas()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func carregar_sprite():
	if card_id in SPRITES:
		var texture = load(SPRITES[card_id])
		if texture:
			sp_frente.texture = texture
		else:
			push_error("Sprite não encontrado para card_id: " + str(card_id))
	else:
		push_error("card_id fora do range: " + str(card_id))

func _on_mouse_entered():
	mouse_dentro = true
	if not pode_animar or virando:
		return
	z_index = 100
	if tween_hover: tween_hover.kill()
	tween_hover = create_tween()
	tween_hover.tween_property(self, "scale", Vector2(1, 1), 0.15)
	animar_loop_rotacao()

func _on_mouse_exited():
	mouse_dentro = false
	z_index = z_original
	var t = create_tween()
	t.tween_property(self, "scale", Vector2(0.8, 0.8), 0.15)
	parar_rotacao()
	if virando:
		return
	if tween_hover: tween_hover.kill()
	tween_hover = create_tween()
	tween_hover.tween_property(self, "scale", Vector2(0.7, 0.7), 0.15)

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
		virar()
		emit_signal("carta_clicada", self)

func virar():
	if virando:
		return
	virando = true

	# Cancela hover em andamento pra evitar conflito de tween no scale
	if tween_hover: tween_hover.kill()

	var alvo = scale
	var y0 = position.y

	# Fase 1: encolhe horizontal + pula
	var t1 = create_tween().set_parallel(true)
	t1.tween_property(self, "scale", Vector2(0.0, alvo.y), 0.12) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t1.tween_property(self, "position:y", y0 - 12, 0.12) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await t1.finished

	# Mid-flip: troca o sprite visível
	if virada:
		mostrar_costas()
	else:
		mostrar_frente()
	virada = !virada

	# Fase 2: expande horizontal + cai
	var t2 = create_tween().set_parallel(true)
	t2.tween_property(self, "scale", alvo, 0.12) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t2.tween_property(self, "position:y", y0, 0.12) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await t2.finished

	virando = false

	# Se o mouse saiu da carta durante o flip, ajusta o scale para o repouso
	if not mouse_dentro and scale != Vector2(0.7, 0.7):
		if tween_hover: tween_hover.kill()
		tween_hover = create_tween()
		tween_hover.tween_property(self, "scale", Vector2(0.7, 0.7), 0.12)

func mostrar_frente():
	sp_frente.visible = true
	sp_costa.visible = false

func mostrar_costas():
	sp_frente.visible = false
	sp_costa.visible = true
