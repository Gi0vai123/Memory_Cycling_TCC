extends Area2D
@export var card_id: int = 0
var tween_rotacao: Tween
@onready var sp_frente = $SpFrente
@onready var sp_costa = $SpCosta
@onready var qualid = $id
var pode_animar := false
var virada := false
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
	if not pode_animar:
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
		virar()
		emit_signal("carta_clicada", self)

func virar():
	if virada:
		mostrar_costas()
	else:
		mostrar_frente()
	virada = !virada

func mostrar_frente():
	sp_frente.visible = true
	sp_costa.visible = false

func mostrar_costas():
	sp_frente.visible = false
	sp_costa.visible = true
