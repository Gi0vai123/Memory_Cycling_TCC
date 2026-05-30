extends Node2D

@export var card_scene: PackedScene
@export var usar_contagem = true
@onready var contador_scene = $UImp/Contador
@onready var barra_azul = $UImp/ProgressBarA
@onready var barra_vermelha = $UImp/ProgressBarV
@onready var seta_azul = $UImp/ProgressBarA/setaazul
@onready var seta_vermelha = $UImp/ProgressBarV/setavermelha

var tempo_total = 100.0
var tempo_azul = tempo_total
var tempo_vermelho = tempo_total
var tempo_ativo = false
var cartas = []
var pontos_azul = 0
var pontos_vermelho = 0
var jogador_atual = ""
var jogador_que_comeca = ""
var pares_encontrados = 0
var primeira_carta = null
var segunda_carta = null
var valor_anterior_azul = 0.0
var valor_anterior_vermelho = 0.0
var pode_clicar = false

var nome_jogador_azul: String = "Azul"
var nome_jogador_vermelho: String = "Vermelho"

const COLUNAS = 9
const ESPACAMENTO_X = 130
const ESPACAMENTO_Y = 150
const DEBUG_UM_CONTROLE = true
const DEADZONE = 0.5
const COOLDOWN_MOVIMENTO = 0.2

var quantidade_pares: int = 15
var cursor_index: int = 0
var total_linhas: int = 0
var cooldown_timer: float = 0.0

func _ready():
	randomize()
	definir_lados()
	quantidade_pares = Dificuldade.pares
	if Campeonato.campeonato_ativo:
		nome_jogador_azul = Campeonato.jogador_a
		nome_jogador_vermelho = Campeonato.jogador_b
	start_jogo()

func _process(delta):
	if tempo_ativo:
		timer_bar(delta)
	if cooldown_timer > 0:
		cooldown_timer -= delta
	if pode_clicar and not cartas.is_empty() and cooldown_timer <= 0:
		_processar_analogico()

func _processar_analogico():
	var device = 0 if DEBUG_UM_CONTROLE else (0 if jogador_atual == "azul" else 1)
	var h = Input.get_joy_axis(device, JOY_AXIS_LEFT_X)
	var v = Input.get_joy_axis(device, JOY_AXIS_LEFT_Y)

	var total = cartas.size()
	total_linhas = ceil(float(total) / float(COLUNAS))
	var linha_atual = cursor_index / COLUNAS
	var coluna_atual = cursor_index % COLUNAS
	var cartas_ultima_linha = total % COLUNAS
	if cartas_ultima_linha == 0:
		cartas_ultima_linha = COLUNAS

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
		if nova_linha < total_linhas:
			var max_col = COLUNAS - 1
			if nova_linha == total_linhas - 1:
				max_col = cartas_ultima_linha - 1
			_mover_cursor(nova_linha * COLUNAS + min(coluna_atual, max_col))
		cooldown_timer = COOLDOWN_MOVIMENTO
	elif v < -DEADZONE:
		var nova_linha = linha_atual - 1
		if nova_linha >= 0:
			_mover_cursor(nova_linha * COLUNAS + coluna_atual)
		cooldown_timer = COOLDOWN_MOVIMENTO

func _input(event):
	if not pode_clicar or cartas.is_empty():
		return
	if not DEBUG_UM_CONTROLE:
		if event is InputEventJoypadButton:
			var device_permitido = 0 if jogador_atual == "azul" else 1
			if event.device != device_permitido:
				return
	if event.is_action_pressed("ui_accept"):
		var carta = cartas[cursor_index]
		if is_instance_valid(carta) and not carta.virada:
			carta.selecionar()

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

func start_jogo() -> void:
	if usar_contagem and contador_scene:
		await contagem_regressiva(contador_scene)
	textJ()
	mostrar_sprite_equipe()
	atualizar_labels()
	tempo_azul = tempo_total
	tempo_vermelho = tempo_total
	await criar_cartas()

func criar_cartas():
	var ids = []
	for i in range(1, quantidade_pares + 1):
		ids.append(i)
		ids.append(i)
	ids.shuffle()

	var total = ids.size()
	var linhas = ceil(float(total) / float(COLUNAS))
	var altura_total = (linhas - 1) * ESPACAMENTO_Y
	var centro = Vector2(640, 450)
	var start_y = centro.y - altura_total / 2.0

	cartas.clear()

	var carta_roots = []
	for i in range(total):
		var row = i / COLUNAS
		var col = i % COLUNAS

		var cartas_nessa_linha: int
		if row < linhas - 1:
			cartas_nessa_linha = COLUNAS
		else:
			cartas_nessa_linha = total % COLUNAS
			if cartas_nessa_linha == 0:
				cartas_nessa_linha = COLUNAS

		var largura_linha = (cartas_nessa_linha - 1) * ESPACAMENTO_X
		var start_x = centro.x - largura_linha / 2.0

		var pos_final = Vector2(
			start_x + col * ESPACAMENTO_X,
			start_y + row * ESPACAMENTO_Y
		)

		var carta_root = card_scene.instantiate()
		add_child(carta_root)
		carta_root.position = Vector2.ZERO
		carta_root.scale = Vector2(1, 1)
		var area = carta_root.get_node("carta")
		area.position = Vector2.ZERO
		area.card_id = ids[i]
		area.carregar_sprite()
		area.pode_animar = false
		area.connect("carta_clicada", Callable(self, "verificar_carta"))
		cartas.append(area)
		carta_roots.append({"root": carta_root, "pos": pos_final})

	for entry in carta_roots:
		var tween = create_tween()
		tween.tween_property(entry["root"], "position", entry["pos"], 0.4) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	await get_tree().create_timer(0.5).timeout
	await mostrar_cartas_inicial()

	for c in cartas:
		c.pode_animar = true

	cursor_index = 0
	if not cartas.is_empty():
		cartas[0].focar()

func mostrar_cartas_inicial():
	tempo_ativo = false
	pode_clicar = false
	atualizar_barra_jogador()
	_set_collision(true)
	for c in cartas:
		if not c.virada:
			c.virar()
	await get_tree().create_timer(4.0).timeout
	for c in cartas:
		if c.virada:
			c.virar()
	_set_collision(false)
	tempo_ativo = true
	pode_clicar = true

func _set_collision(disabled: bool):
	for c in cartas:
		if is_instance_valid(c):
			var col = c.get_node_or_null("CollisionShape2D")
			if col:
				col.disabled = disabled

func timer_bar(delta):
	if jogador_atual == "azul":
		if tempo_azul > 0:
			valor_anterior_azul = barra_azul.value
			tempo_azul -= delta
			barra_azul.value = (tempo_azul / tempo_total) * barra_azul.max_value
			atualizar_setas(valor_anterior_azul - barra_azul.value)
		else:
			tempo_ativo = false
			fim_de_tempo()
	else:
		if tempo_vermelho > 0:
			valor_anterior_vermelho = barra_vermelha.value
			tempo_vermelho -= delta
			barra_vermelha.value = (tempo_vermelho / tempo_total) * barra_vermelha.max_value
			atualizar_setas(valor_anterior_vermelho - barra_vermelha.value)
		else:
			tempo_ativo = false
			fim_de_tempo()

func atualizar_barra_jogador():
	barra_azul.visible = true
	barra_vermelha.visible = true
	if jogador_atual == "azul":
		barra_azul.modulate.a = 1.0
		barra_vermelha.modulate.a = 0.5
		barra_azul.value = (tempo_azul / tempo_total) * barra_azul.max_value
	else:
		barra_azul.modulate.a = 0.5
		barra_vermelha.modulate.a = 1.0
		barra_vermelha.value = (tempo_vermelho / tempo_total) * barra_vermelha.max_value

func atualizar_setas(diferenca):
	var largura = barra_azul.size.x
	var pixels_por_valor = largura / barra_azul.max_value
	var movimento = diferenca * pixels_por_valor
	if jogador_atual == "azul" and barra_azul.value > 0:
		seta_azul.global_position.x -= movimento
	elif barra_vermelha.value > 0:
		seta_vermelha.global_position.x -= movimento

func fim_de_tempo():
	await get_tree().create_timer(1.0).timeout
	reiniciar_jogo()

func verificar_carta(carta):
	if not pode_clicar:
		return
	if primeira_carta == null:
		primeira_carta = carta
		primeira_carta.get_node_or_null("CollisionShape2D").disabled = true
	elif segunda_carta == null and carta != primeira_carta:
		segunda_carta = carta
		pode_clicar = false
		_set_collision(true)
		if primeira_carta.card_id == segunda_carta.card_id:
			pontos_ganhos()
			primeira_carta = null
			segunda_carta = null
			_set_collision(false)
			if pares_encontrados >= quantidade_pares:
				ganhou()
				return
			pode_clicar = true
		else:
			mudando_atual()
			await get_tree().create_timer(0.5).timeout
			primeira_carta.virar()
			segunda_carta.virar()
			primeira_carta = null
			segunda_carta = null
			_set_collision(false)
			mostrar_sprite_equipe()
			pode_clicar = true

func ganhou():
	tempo_ativo = false
	var vencedor: String
	if Campeonato.campeonato_ativo:
		vencedor = nome_jogador_azul if jogador_atual == "azul" else nome_jogador_vermelho
	else:
		vencedor = "Azul" if jogador_atual == "azul" else "Vermelho"
	await get_tree().create_timer(1.5).timeout
	if Campeonato.campeonato_ativo:
		Campeonato.registrar_resultado(vencedor)
		get_tree().change_scene_to_file("res://scenes/chave_campeonato.tscn")
	else:
		reiniciar_jogo()

func reiniciar_jogo():
	get_tree().reload_current_scene()

func bloqueio_de_cartas():
	if primeira_carta != null:
		var col = primeira_carta.get_node_or_null("CollisionShape2D")
		if col: col.disabled = true
	if segunda_carta != null:
		var col = segunda_carta.get_node_or_null("CollisionShape2D")
		if col: col.disabled = true

func desbloquear_cartas():
	if primeira_carta != null:
		var col = primeira_carta.get_node_or_null("CollisionShape2D")
		if col: col.disabled = false
	if segunda_carta != null:
		var col = segunda_carta.get_node_or_null("CollisionShape2D")
		if col: col.disabled = false

func lado_oposto(lado):
	return "vermelho" if lado == "azul" else "azul"

func definir_lados():
	var lados = ["azul", "vermelho"]
	jogador_que_comeca = lados.pick_random()
	jogador_atual = jogador_que_comeca

func textJ():
	if Campeonato.campeonato_ativo:
		$UImp/LabelJogador.text = nome_jogador_azul if jogador_atual == "azul" else nome_jogador_vermelho
	else:
		$UImp/LabelJogador.text = jogador_atual

func mudando_atual():
	jogador_atual = lado_oposto(jogador_atual)
	textJ()
	atualizar_barra_jogador()

func pontos_ganhos():
	pares_encontrados += 1
	match jogador_atual:
		"azul":
			pontos_azul += 1
		"vermelho":
			pontos_vermelho += 1
	atualizar_labels()

func mostrar_sprite_equipe():
	match jogador_atual:
		"azul":
			$equipe_azul.visible = true
			$equipe_vermelha.visible = false
		"vermelho":
			$equipe_azul.visible = false
			$equipe_vermelha.visible = true

func atualizar_labels():
	$UImp/PontosA.text = str(pontos_azul)
	$UImp/PontosV.text = str(pontos_vermelho)
