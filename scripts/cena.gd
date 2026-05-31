extends Node2D

@export var card_scene: PackedScene
@export var usar_contagem = true
@onready var contador_scene = $UImp/Contador
@onready var barra_azul = $UImp/ProgressBarA
@onready var barra_vermelha = $UImp/ProgressBarV
@onready var seta_azul = $UImp/ProgressBarA/setaazul
@onready var seta_vermelha = $UImp/ProgressBarV/setavermelha
@onready var menu_pause = $Pause

var tempo_total = 90.0
var tempo_azul = tempo_total
var tempo_vermelho = tempo_total
var tempo_ativo = false
var cartas = []
var posicoes_grid: Array = []  # posicoes finais das cartas (pra reembaralhar)
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

# Layout do grid — valores ajustados por dificuldade em _ajustar_layout()
var colunas: int = 6
var espacamento_x: int = 110
var espacamento_y: int = 160
var centro_y: int = 400

const DEBUG_UM_CONTROLE = true
const DEADZONE = 0.5
const COOLDOWN_MOVIMENTO = 0.2

# Cores do fundo de cada barra
const COR_FUNDO_AZUL := Color(0.04, 0.12, 0.22, 1.0)
const COR_FUNDO_VERMELHO := Color(0.22, 0.04, 0.12, 1.0)

var fundo_barra_a: StyleBoxFlat
var fundo_barra_v: StyleBoxFlat

var quantidade_pares: int = 15
var total_linhas: int = 0

# Cada jogador tem seu proprio cursor e cooldown — em DEBUG so o ativo aparece.
# O cursor so aparece depois que o jogador encostar no controle (mouse nao ativa)
var cursor_azul: int = 0
var cursor_vermelho: int = 0
var cooldown_azul: float = 0.0
var cooldown_vermelho: float = 0.0
var cursor_azul_ativo: bool = false
var cursor_vermelho_ativo: bool = false

func _ready():
	randomize()
	definir_lados()
	quantidade_pares = Dificuldade.pares
	colunas = Dificuldade.colunas
	_ajustar_layout()
	_preparar_fundo_barras()
	if Campeonato.campeonato_ativo:
		nome_jogador_azul = Campeonato.jogador_a
		nome_jogador_vermelho = Campeonato.jogador_b
	start_jogo()

# Define a cor de fundo fixa de cada barra (azul e vermelha)
func _preparar_fundo_barras():
	fundo_barra_a = StyleBoxFlat.new()
	fundo_barra_a.bg_color = COR_FUNDO_AZUL
	barra_azul.add_theme_stylebox_override("background", fundo_barra_a)
	fundo_barra_v = StyleBoxFlat.new()
	fundo_barra_v.bg_color = COR_FUNDO_VERMELHO
	barra_vermelha.add_theme_stylebox_override("background", fundo_barra_v)

func _process(delta):
	if tempo_ativo:
		timer_bar(delta)
	cooldown_azul = max(0.0, cooldown_azul - delta)
	cooldown_vermelho = max(0.0, cooldown_vermelho - delta)
	if pode_clicar and not cartas.is_empty():
		_processar_analogico()

func _processar_analogico():
	if DEBUG_UM_CONTROLE:
		# 1 controle: o device 0 controla sempre o cursor do jogador da vez
		_processar_controle(0, jogador_atual)
	else:
		# 2 controles: cada um move o cursor do seu jogador o tempo todo
		_processar_controle(0, "azul")
		_processar_controle(1, "vermelho")

func _processar_controle(device: int, jogador: String):
	var h = Input.get_joy_axis(device, JOY_AXIS_LEFT_X)
	var v = Input.get_joy_axis(device, JOY_AXIS_LEFT_Y)
	_aplicar_movimento(h, v, jogador)

func _aplicar_movimento(h: float, v: float, jogador: String):
	var cooldown = cooldown_azul if jogador == "azul" else cooldown_vermelho
	if cooldown > 0:
		return
	if abs(h) < DEADZONE and abs(v) < DEADZONE:
		return

	# Primeiro toque no controle so ativa o cursor e mostra o destaque, sem mover
	var ativo_flag = cursor_azul_ativo if jogador == "azul" else cursor_vermelho_ativo
	if not ativo_flag:
		if jogador == "azul":
			cursor_azul_ativo = true
			cooldown_azul = COOLDOWN_MOVIMENTO
		else:
			cursor_vermelho_ativo = true
			cooldown_vermelho = COOLDOWN_MOVIMENTO
		var pos = cursor_azul if jogador == "azul" else cursor_vermelho
		if pos < cartas.size() and is_instance_valid(cartas[pos]):
			cartas[pos].focar(jogador, jogador == jogador_atual)
		return

	var cursor = cursor_azul if jogador == "azul" else cursor_vermelho
	var total = cartas.size()
	total_linhas = ceil(float(total) / float(colunas))
	var linha_atual = cursor / colunas
	var coluna_atual = cursor % colunas
	var cartas_ultima_linha = total % colunas
	if cartas_ultima_linha == 0:
		cartas_ultima_linha = colunas

	var novo: int = -1
	if h > DEADZONE:
		var n = cursor + 1
		if n < total:
			novo = n
	elif h < -DEADZONE:
		var n = cursor - 1
		if n >= 0:
			novo = n
	elif v > DEADZONE:
		var nova_linha = linha_atual + 1
		if nova_linha < total_linhas:
			var max_col = colunas - 1
			if nova_linha == total_linhas - 1:
				max_col = cartas_ultima_linha - 1
			novo = nova_linha * colunas + min(coluna_atual, max_col)
	elif v < -DEADZONE:
		var nova_linha = linha_atual - 1
		if nova_linha >= 0:
			novo = nova_linha * colunas + coluna_atual

	if novo == -1:
		return
	_mover_cursor_jogador(novo, jogador)
	if jogador == "azul":
		cooldown_azul = COOLDOWN_MOVIMENTO
	else:
		cooldown_vermelho = COOLDOWN_MOVIMENTO

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if get_tree().paused:
			menu_pause.despausar()
		else:
			menu_pause.pausar()
	if not pode_clicar or cartas.is_empty():
		return
	# So o controle do jogador da vez consegue confirmar
	var device_ativo = 0 if DEBUG_UM_CONTROLE else (0 if jogador_atual == "azul" else 1)
	if event is InputEventJoypadButton and event.device != device_ativo:
		return
	if event.is_action_pressed("ui_accept"):
		# So confirma se o cursor do jogador ja foi ativado pelo controle
		var ativo = cursor_azul_ativo if jogador_atual == "azul" else cursor_vermelho_ativo
		if not ativo:
			return
		var cursor = cursor_azul if jogador_atual == "azul" else cursor_vermelho
		if cursor >= cartas.size():
			return
		var carta = cartas[cursor]
		if is_instance_valid(carta) and not carta.virada:
			carta.selecionar()

func _mover_cursor_jogador(novo_index: int, jogador: String):
	var cursor_atual = cursor_azul if jogador == "azul" else cursor_vermelho
	var ativo = jogador == jogador_atual
	if cursor_atual < cartas.size() and is_instance_valid(cartas[cursor_atual]):
		cartas[cursor_atual].desfocar(jogador, ativo)
	if jogador == "azul":
		cursor_azul = novo_index
	else:
		cursor_vermelho = novo_index
	if novo_index < cartas.size() and is_instance_valid(cartas[novo_index]):
		cartas[novo_index].focar(jogador, ativo)

# Ajusta o spacing e o centro do grid conforme a dificuldade
func _ajustar_layout() -> void:
	match quantidade_pares:
		12:  # Fácil 6×4
			espacamento_x = 130
			espacamento_y = 170
			centro_y = 380
		15:  # Normal 10×3
			espacamento_x = 110
			espacamento_y = 175
			centro_y = 400
		20:  # Difícil 10×4
			espacamento_x = 100
			espacamento_y = 170
			centro_y = 380
		_:
			espacamento_x = 110
			espacamento_y = 170
			centro_y = 400

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
	var linhas = ceil(float(total) / float(colunas))
	var altura_total = (linhas - 1) * espacamento_y
	var centro = Vector2(640, centro_y)
	var start_y = centro.y - altura_total / 2.0

	cartas.clear()
	posicoes_grid.clear()

	var carta_roots = []
	for i in range(total):
		var row = i / colunas
		var col = i % colunas

		var cartas_nessa_linha: int
		if row < linhas - 1:
			cartas_nessa_linha = colunas
		else:
			cartas_nessa_linha = total % colunas
			if cartas_nessa_linha == 0:
				cartas_nessa_linha = colunas

		var largura_linha = (cartas_nessa_linha - 1) * espacamento_x
		var start_x = centro.x - largura_linha / 2.0

		var pos_final = Vector2(
			start_x + col * espacamento_x,
			start_y + row * espacamento_y
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
		posicoes_grid.append(pos_final)
		carta_roots.append({"root": carta_root, "pos": pos_final})

	for entry in carta_roots:
		var tween = create_tween()
		tween.tween_property(entry["root"], "position", entry["pos"], 0.4) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	await get_tree().create_timer(0.5).timeout
	await mostrar_cartas_inicial()

	for c in cartas:
		c.pode_animar = true

	cursor_azul = 0
	cursor_vermelho = max(0, cartas.size() - 1)
	cursor_azul_ativo = false
	cursor_vermelho_ativo = false
	# Nao focar nada agora — o cursor so aparece no primeiro toque do controle

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
			# Cartas ja matched ficam sempre travadas — nao reabilita
			if not disabled and c.matched:
				continue
			var col = c.get_node_or_null("CollisionShape2D")
			if col:
				col.disabled = disabled

# Embaralha de novo quando todos os pares forem achados.
# Pausa o tempo, junta as cartas no centro, troca os IDs e devolve pro grid.
func reembaralhar():
	tempo_ativo = false
	pode_clicar = false
	_set_collision(true)

	# Espera qualquer flip em andamento terminar
	await get_tree().create_timer(0.3).timeout

	# Vira tudo pra costa e libera o matched pra proxima rodada
	for c in cartas:
		c.matched = false
		if c.virada:
			c.virar()

	# Junta no centro
	var centro_pos = Vector2(640, centro_y)
	for c in cartas:
		var root = c.get_parent()
		if root:
			var tw = create_tween()
			tw.tween_property(root, "position", centro_pos, 0.5) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	await get_tree().create_timer(0.6).timeout

	# Reseta o visual de cada carta antes de voltar pro grid
	for c in cartas:
		if c.tween_hover:
			c.tween_hover.kill()
		if c.tween_rotacao:
			c.tween_rotacao.kill()
		c.scale = Vector2(0.8, 0.8)
		c.position = Vector2.ZERO
		c.rotation_degrees = 0
		c.z_index = c.z_original
		c.modulate = Color.WHITE
		c.focado_por.clear()

	# Embaralha os IDs e recarrega o sprite de cada carta
	var ids = []
	for c in cartas:
		ids.append(c.card_id)
	ids.shuffle()
	for i in cartas.size():
		cartas[i].card_id = ids[i]
		cartas[i].carregar_sprite()

	# Devolve cada carta pra sua posicao original no grid
	for i in cartas.size():
		var root = cartas[i].get_parent()
		if root and i < posicoes_grid.size():
			var tw = create_tween()
			tw.tween_property(root, "position", posicoes_grid[i], 0.5) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	await get_tree().create_timer(0.6).timeout

	# Garante a posicao final exata caso algum tween tenha desviado
	for i in cartas.size():
		var c = cartas[i]
		var root = c.get_parent()
		c.scale = Vector2(0.8, 0.8)
		c.position = Vector2.ZERO
		c.rotation_degrees = 0
		c.z_index = c.z_original
		if root:
			root.scale = Vector2(1, 1)
			if i < posicoes_grid.size():
				root.position = posicoes_grid[i]

	pares_encontrados = 0
	_set_collision(false)
	tempo_ativo = true
	pode_clicar = true
	# Refoca os cursores ja ativados depois do reembaralho
	if DEBUG_UM_CONTROLE:
		var idx = cursor_azul if jogador_atual == "azul" else cursor_vermelho
		var ativo = cursor_azul_ativo if jogador_atual == "azul" else cursor_vermelho_ativo
		if ativo and idx < cartas.size():
			cartas[idx].focar(jogador_atual)
	else:
		if cursor_azul_ativo and cursor_azul < cartas.size():
			cartas[cursor_azul].focar("azul", jogador_atual == "azul")
		if cursor_vermelho_ativo and cursor_vermelho < cartas.size():
			cartas[cursor_vermelho].focar("vermelho", jogador_atual == "vermelho")

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
	# So a barra do jogador da vez aparece, a outra some com fade.
	# Usa self_modulate pra nao afetar as setas (filhas) — elas ficam sempre visiveis
	var alpha_a := 1.0 if jogador_atual == "azul" else 0.0
	var alpha_v := 1.0 if jogador_atual == "vermelho" else 0.0
	var tw = create_tween().set_parallel(true)
	tw.tween_property(barra_azul, "self_modulate:a", alpha_a, 0.4) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(barra_vermelha, "self_modulate:a", alpha_v, 0.4) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if jogador_atual == "azul":
		barra_azul.value = (tempo_azul / tempo_total) * barra_azul.max_value
	else:
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
	ganhou()

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
			# Marca as duas como matched antes de reabrir colisoes —
			# _set_collision pula matched, entao elas ficam travadas pra sempre
			primeira_carta.matched = true
			segunda_carta.matched = true
			primeira_carta = null
			segunda_carta = null
			_set_collision(false)
			if pares_encontrados >= quantidade_pares:
				reembaralhar()
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
			pode_clicar = true

func ganhou():
	tempo_ativo = false
	pode_clicar = false

	# Vencedor: quem tem mais pontos. Empate vai pra quem virou o ultimo par (jogador_atual).
	var lado_vencedor: String
	if pontos_azul > pontos_vermelho:
		lado_vencedor = "azul"
	elif pontos_vermelho > pontos_azul:
		lado_vencedor = "vermelho"
	else:
		lado_vencedor = jogador_atual  # desempate

	var vencedor: String
	if Campeonato.campeonato_ativo:
		vencedor = nome_jogador_azul if lado_vencedor == "azul" else nome_jogador_vermelho
	else:
		vencedor = "Azul" if lado_vencedor == "azul" else "Vermelho"

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
	var jogador_anterior = jogador_atual
	jogador_atual = lado_oposto(jogador_atual)
	textJ()
	atualizar_barra_jogador()
	if cartas.is_empty():
		return
	var ativo_ant = cursor_azul_ativo if jogador_anterior == "azul" else cursor_vermelho_ativo
	var ativo_novo = cursor_azul_ativo if jogador_atual == "azul" else cursor_vermelho_ativo
	var idx_ant = cursor_azul if jogador_anterior == "azul" else cursor_vermelho
	var idx_novo = cursor_azul if jogador_atual == "azul" else cursor_vermelho
	if DEBUG_UM_CONTROLE:
		# 1 cursor: tira o destaque do anterior e mostra o do novo (se ja foram ativados)
		if ativo_ant and idx_ant < cartas.size() and is_instance_valid(cartas[idx_ant]):
			cartas[idx_ant].desfocar(jogador_anterior)
		if ativo_novo and idx_novo < cartas.size() and is_instance_valid(cartas[idx_novo]):
			cartas[idx_novo].focar(jogador_atual)
	else:
		# 2 cursores: abaixa a carta do antigo ativo e levanta a do novo
		if idx_ant != idx_novo:
			if ativo_ant and idx_ant < cartas.size() and is_instance_valid(cartas[idx_ant]):
				cartas[idx_ant].set_levantada(false)
			if ativo_novo and idx_novo < cartas.size() and is_instance_valid(cartas[idx_novo]):
				cartas[idx_novo].set_levantada(true)

func pontos_ganhos():
	pares_encontrados += 1
	match jogador_atual:
		"azul":
			pontos_azul += 1
		"vermelho":
			pontos_vermelho += 1
	atualizar_labels()

func atualizar_labels():
	$UImp/PontosA.text =  str(pontos_azul)
	$UImp/PontosV.text =  str(pontos_vermelho)
