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

func _ready():
	z_original = z_index
	qualid.text = str(card_id)
	scale = Vector2(0.7, 0.7)
	mostrar_costas()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

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
