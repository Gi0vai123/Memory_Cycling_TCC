extends Node2D

@export var card_scene: PackedScene
@export var usar_contagem := true

@onready var contador_scene = $Contador
@onready var label_jogador = $LabelJogador
@onready var pontos_label = $PontosA
@onready var fase_label = $FaseLabel
@onready var menu_pause = $Pause

const ESPACAMENTO_X = 150
const ESPACAMENTO_Y = 200
const PARES_INICIAIS = 2
const INCREMENTO_PARES = 2
const COLUNAS = 4
const DEBUG_UM_CONTROLE = true
const DEADZONE = 0.5
const COOLDOWN_MOVIMENTO = 0.2

var pares_fase_atual = PARES_INICIAIS
var pares_encontrados = 0
var pares_necessarios = 0
var cartas = []
var primeira_carta = null
var segunda_carta = null
var pode_virar = true
var jogador_atual = "azul"
var pontos_azul = 0
var pontos_vermelho = 0

var cursor_index: int = 0
var cooldown_timer: float = 0.0

func _ready():
	randomize()
	if usar_contagem and contador_scene:
		await contagem_regressiva(contador_scene)
	iniciar_fase()

func _process(delta):
	if cooldown_timer > 0:
		cooldown_timer -= delta
	if pode_virar and not cartas.is_empty() and cooldown_timer <= 0:
		_processar_analogico()

func _processar_analogico():
	var device = 0 if DEBUG_UM_CONTROLE else (0 if jogador_atual == "azul" else 1)
	var total = cartas.size()
	var colunas = min(COLUNAS, total)
	var linhas = ceil(float(total) / float(colunas))
	var linha_atual = cursor_index / colunas
	var coluna_atual = cursor_index % colunas

	var h = Input.get_joy_axis(device, JOY_AXIS_LEFT_X)
	var v = Input.get_joy_axis(device, JOY_AXIS_LEFT_Y)

	if h > DEADZONE:
		var novo = cursor_index + 1
		if novo < total:
			_mover_cursor(novo)
		cooldown_timer = COOLDOWN_MOVIMENTO
	elif h < -DEADZONE:
		var novo = cursor_index - 1
		if novo >= 0:
			_mover_cursor(novo)
		cooldown_timer = COOLDOWN_MOVIMENTO
	elif v > DEADZONE:
		var nova_linha = linha_atual + 1
		if nova_linha < linhas:
			var cartas_ultima_linha = total % colunas
			if cartas_ultima_linha == 0:
				cartas_ultima_linha = colunas
			var max_col = colunas - 1
			if nova_linha == linhas - 1:
				max_col = cartas_ultima_linha - 1
			_mover_cursor(nova_linha * colunas + min(coluna_atual, max_col))
		cooldown_timer = COOLDOWN_MOVIMENTO
	elif v < -DEADZONE:
		var nova_linha = linha_atual - 1
		if nova_linha >= 0:
			_mover_cursor(nova_linha * colunas + coluna_atual)
		cooldown_timer = COOLDOWN_MOVIMENTO

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if get_tree().paused:
			menu_pause.despausar()
		else:
			menu_pause.pausar()
	if not pode_virar or cartas.is_empty():
		return
	if not DEBUG_UM_CONTROLE:
		if event is InputEventJoypadButton:
			var device_permitido = 0 if jogador_atual == "azul" else 1
			if event.device != device_permitido:
				return
	if event.is_action_pressed("ui_accept"):
		var carta = cartas[cursor_index]
		if is_instance_valid(carta) and not carta.virada:
			carta.virar()
			_on_carta_clicada(carta)

func _mover_cursor(novo_index: int):
	if cursor_index < cartas.size() and is_instance_valid(cartas[cursor_index]):
		cartas[cursor_index].desfocar()
	cursor_index = novo_index
	if cursor_index < cartas.size() and is_instance_valid(cartas[cursor_index]):
		cartas[cursor_index].focar()

func contagem_regressiva(contador):
	contador.visible = true
	for n in [3, 2, 1]:
		contador.text = str(n)
		await get_tree().create_timer(1.0).timeout
	contador.text = "VAI!"
	await get_tree().create_timer(0.5).timeout
	contador.text = ""
	contador.visible = false

func iniciar_fase():
	for c in cartas:
		if is_instance_valid(c):
			var root = c.get_parent()
			if root and is_instance_valid(root):
				root.queue_free()
	cartas.clear()
	primeira_carta = null
	segunda_carta = null
	pares_encontrados = 0
	pares_necessarios = pares_fase_atual
	cursor_index = 0
	atualizar_ui()
	await criar_cartas()
	await mostrar_cartas_inicial()

func calcular_grid(total_cartas: int) -> Vector2i:
	var colunas = min(COLUNAS, total_cartas)
	var linhas = ceil(float(total_cartas) / float(colunas))
	return Vector2i(colunas, linhas)

func criar_cartas():
	if card_scene == null:
		push_error("Card Scene não atribuída!")
		return

	var total = pares_fase_atual * 2
	var ids = []
	for i in range(1, pares_fase_atual + 1):
		ids.append(i)
		ids.append(i)
	ids.shuffle()

	var grid = calcular_grid(total)
	var colunas = grid.x
	var linhas = grid.y

	var largura_total = (colunas - 1) * ESPACAMENTO_X
	var altura_total = (linhas - 1) * ESPACAMENTO_Y
	var centro = Vector2(640, 360)
	var offset_x = centro.x - largura_total / 2.0
	var offset_y = centro.y - altura_total / 2.0

	var carta_roots = []
	for i in range(total):
		var col = i % colunas
		var row = i / colunas
		var pos_final = Vector2(
			offset_x + col * ESPACAMENTO_X,
			offset_y + row * ESPACAMENTO_Y
		)
		var carta_root = card_scene.instantiate()
		add_child(carta_root)
		carta_root.position = Vector2.ZERO
		carta_root.scale = Vector2(1, 1)
		var area = carta_root.get_node("carta")
		area.position = Vector2.ZERO
		area.card_id = ids[i]
		area.pode_animar = false
		area.connect("carta_clicada", Callable(self, "_on_carta_clicada"))
		cartas.append(area)
		carta_roots.append({"root": carta_root, "pos": pos_final})

	for entry in carta_roots:
		var tween = create_tween()
		tween.tween_property(entry["root"], "position", entry["pos"], 0.4) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(0.5).timeout

func mostrar_cartas_inicial():
	pode_virar = false
	_set_collision(true)
	for c in cartas:
		if not c.virada:
			c.virar()
	var tempo_memo = 1.5 + pares_fase_atual * 0.3
	await get_tree().create_timer(tempo_memo).timeout
	for c in cartas:
		if c.virada:
			c.virar()
	_set_collision(false)
	pode_virar = true
	for c in cartas:
		c.pode_animar = true
	cursor_index = 0
	if not cartas.is_empty():
		cartas[0].focar()

func _on_carta_clicada(carta):
	if not pode_virar:
		return
	if carta == primeira_carta:
		return
	if primeira_carta == null:
		primeira_carta = carta
	elif segunda_carta == null:
		segunda_carta = carta
		pode_virar = false
		await verificar_par()

func verificar_par():
	if primeira_carta.card_id == segunda_carta.card_id:
		var col1 = primeira_carta.get_node_or_null("CollisionShape2D")
		var col2 = segunda_carta.get_node_or_null("CollisionShape2D")
		if col1:
			col1.disabled = true
		if col2:
			col2.disabled = true
		_registrar_ponto()
		pares_encontrados += 1
		primeira_carta = null
		segunda_carta = null
		pode_virar = true
		atualizar_ui()
		if pares_encontrados >= pares_necessarios:
			await get_tree().create_timer(0.5).timeout
			fase_vencida()
	else:
		await get_tree().create_timer(0.6).timeout
		primeira_carta.virar()
		segunda_carta.virar()
		primeira_carta = null
		segunda_carta = null
		trocar_jogador()
		pode_virar = true

func fase_vencida():
	pares_fase_atual += INCREMENTO_PARES
	if fase_label:
		fase_label.text = "Fase concluída! Próxima: %d pares..." % pares_fase_atual
	await get_tree().create_timer(2.0).timeout
	iniciar_fase()

func fase_perdida():
	pares_fase_atual = PARES_INICIAIS
	if fase_label:
		fase_label.text = "Tempo esgotado! Voltando ao início..."
	await get_tree().create_timer(2.0).timeout
	iniciar_fase()

func _registrar_ponto():
	if jogador_atual == "azul":
		pontos_azul += 1
	else:
		pontos_vermelho += 1

func trocar_jogador():
	if jogador_atual == "azul":
		jogador_atual = "vermelho"
	else:
		jogador_atual = "azul"
	atualizar_ui()

func _set_collision(disabled: bool):
	for c in cartas:
		if is_instance_valid(c):
			var collision = c.get_node_or_null("CollisionShape2D")
			if collision:
				collision.disabled = disabled

func atualizar_ui():
	if label_jogador:
		label_jogador.text = "Vez: Equipe " + jogador_atual.capitalize()
	if pontos_label:
		pontos_label.text = "Azul: %d | Vermelho: %d" % [pontos_azul, pontos_vermelho]
	if fase_label:
		fase_label.text = "Pares: %d/%d" % [pares_encontrados, pares_necessarios]
