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

# Nomes de exibição (sobrescritos pelo singleton Campeonato quando ativo)
var nome_jogador_azul: String = "Azul"
var nome_jogador_vermelho: String = "Vermelho"

const ESPACAMENTO_X = 110
const ESPACAMENTO_Y = 160

# Pares e colunas da rodada — lidos do singleton Dificuldade em _ready()
var quantidade_pares: int = 15
var colunas: int = 6

func contagem_regressiva(contador):
	contador.visible = true
	for n in [3, 2, 1]:
		contador.text = str(n)
		await get_tree().create_timer(1.0).timeout
	contador.text = "VAI!"
	await get_tree().create_timer(0.5).timeout
	contador.text = ""
	contador.visible = false

func _ready():
	randomize()
	definir_lados()
	quantidade_pares = Dificuldade.pares
	colunas = Dificuldade.colunas
	if Campeonato.campeonato_ativo:
		nome_jogador_azul    = Campeonato.jogador_a
		nome_jogador_vermelho = Campeonato.jogador_b
	start_jogo()

func _process(delta):
	if tempo_ativo:
		timer_bar(delta)

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
	var largura_total = (colunas - 1) * ESPACAMENTO_X
	var linhas = ceil(float(total) / float(colunas))
	var altura_total = (linhas - 1) * ESPACAMENTO_Y
	var centro = Vector2(640, 400)
	var start_x = centro.x - largura_total / 2.0
	var start_y = centro.y - altura_total / 2.0

	cartas.clear()

	var carta_roots = []
	for i in range(total):
		var col = i % colunas
		var row = i / colunas
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

func mostrar_cartas_inicial():
	tempo_ativo = false
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
	print("O tempo acabou!")
	await get_tree().create_timer(1.0).timeout
	reiniciar_jogo()

func verificar_carta(carta):
	if primeira_carta == null:
		primeira_carta = carta
		bloqueio_de_cartas()
	elif segunda_carta == null:
		segunda_carta = carta
		bloqueio_de_cartas()
		if primeira_carta.card_id == segunda_carta.card_id:
			pontos_ganhos()
			var col1 = primeira_carta.get_node_or_null("CollisionShape2D")
			var col2 = segunda_carta.get_node_or_null("CollisionShape2D")
			if col1: col1.disabled = true
			if col2: col2.disabled = true
			if pares_encontrados >= quantidade_pares:
				ganhou()
		else:
			mudando_atual()
			await get_tree().create_timer(0.5).timeout
			primeira_carta.virar()
			segunda_carta.virar()
			desbloquear_cartas()
			mostrar_sprite_equipe()
		primeira_carta = null
		segunda_carta = null

func ganhou():
	tempo_ativo = false
	var vencedor: String
	if Campeonato.campeonato_ativo:
		vencedor = nome_jogador_azul if jogador_atual == "azul" else nome_jogador_vermelho
	else:
		vencedor = "Azul" if jogador_atual == "azul" else "Vermelho"
	print("Equipe " + vencedor + " ganhou!")
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
	$UImp/PontosA.text = "Pontos da equipe azul: " + str(pontos_azul)
	$UImp/PontosV.text = "Pontos da equipe vermelha: " + str(pontos_vermelho)
