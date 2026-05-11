extends Control

# ─────────────────────────────────────────────
#  Tela de seleção de modo de jogo.
#  Cards: Padrão / Campeonato / Adivinhação.
#
#  Botões da parte de baixo (Fácil/Normal/Difícil) são
#  os "Jogar" — ao clicar, navega pra cena do modo.
#
#  O Campeonato tem uma linha extra ("Quantos jogadores?")
#  com toggles 4/6/8 que ficam pré-selecionados — o valor
#  é aplicado em Campeonato.num_jogadores antes de navegar.
# ─────────────────────────────────────────────

# Tela
const LARGURA_TELA: float = 1280.0
const ALTURA_TELA: float = 720.0

# Layout dos cards
const LARGURA_CARD: float = 400.0
const ALTURA_CARD: float = 600.0
const MARGEM_ENTRE_CARDS: float = 24.0
const TOPO_CARDS: float = 75.0
const PADDING_INTERNO: float = 24.0

# Layout interno do card (Y a partir do topo do card)
const Y_TITULO: float = 20.0
const Y_IMAGEM: float = 65.0
const ALTURA_IMAGEM: float = 225.0
const Y_DESCRICAO: float = 305.0
const ALTURA_DESCRICAO: float = 90.0
const Y_PRE_SELECAO_LABEL: float = 405.0
const Y_PRE_SELECAO_BTN: float = 430.0
const ALTURA_PRE_SELECAO_BTN: float = 46.0
const Y_OPCOES_LABEL: float = 505.0
const Y_OPCOES_BTN: float = 530.0
const ALTURA_OPCOES_BTN: float = 58.0

# Cor dos toggles de pré-seleção
const COR_TOGGLE_ATIVO: Color = Color(1.0, 0.9, 0.3)
const COR_TOGGLE_INATIVO: Color = Color(0.55, 0.55, 0.7)

# Configuração dos modos.
#   opcoes        → botões da linha de baixo (sempre navegam pra cena)
#   pre_selecao   → (opcional) linha extra de toggles que só seta
#                   o estado antes de navegar
var modos: Array = [
	{
		"nome": "Modo Padrão",
		"descricao": "Partida 1x1 entre os times Azul e Vermelho. Vence quem encontrar mais pares antes do tempo acabar.",
		"cena": "res://scenes/modoP.tscn",
		"opcoes_label": "Dificuldade",
		"opcoes": [
			{"label": "Fácil", "valor": "facil"},
			{"label": "Normal", "valor": "normal"},
			{"label": "Difícil", "valor": "dificil"},
		],
	},
	{
		"nome": "Modo Campeonato",
		"descricao": "Chaveamento eliminatório entre os jogadores cadastrados. Escolha a quantidade e a dificuldade.",
		"cena": "res://scenes/cadastro_campeonato.tscn",
		"opcoes_label": "Dificuldade",
		"opcoes": [
			{"label": "Fácil", "valor": "facil"},
			{"label": "Normal", "valor": "normal"},
			{"label": "Difícil", "valor": "dificil"},
		],
		"pre_selecao": {
			"label": "Quantos jogadores?",
			"default": 8,
			"opcoes": [
				{"label": "4", "valor": 4},
				{"label": "6", "valor": 6},
				{"label": "8", "valor": 8},
			],
		},
	},
	{
		"nome": "Modo Adivinhação",
		"descricao": "Duelo entre os baralhos dos jogadores. Tente adivinhar qual carta o oponente vai virar a cada rodada.",
		"cena": "res://scenes/duelo-advinho.tscn",
		"opcoes_label": "Dificuldade",
		"opcoes": [
			{"label": "Fácil", "valor": "facil"},
			{"label": "Normal", "valor": "normal"},
			{"label": "Difícil", "valor": "dificil"},
		],
	},
]

# Estado dos toggles de pré-seleção: { modo_idx: valor_selecionado }
var pre_selecao_state: Dictionary = {}
# Botões dos toggles (pra atualizar o destaque visual): { modo_idx: [Button,...] }
var pre_selecao_btns: Dictionary = {}


func _ready() -> void:
	_criar_interface()


# ─────────────────────────────────────────────
#  Monta a tela de seleção
# ─────────────────────────────────────────────
func _criar_interface() -> void:
	# Fundo escuro
	var fundo = ColorRect.new()
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fundo.color = Color(0.07, 0.07, 0.14)
	add_child(fundo)

	# Título
	var titulo = Label.new()
	titulo.text = "ESCOLHA O MODO"
	titulo.add_theme_font_size_override("font_size", 34)
	titulo.modulate = Color(1.0, 0.85, 0.2)
	titulo.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	titulo.offset_top = 28
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(titulo)

	# Calcula posição inicial pra centralizar os 3 cards
	var largura_total = LARGURA_CARD * modos.size() + MARGEM_ENTRE_CARDS * (modos.size() - 1)
	var inicio_x = (LARGURA_TELA - largura_total) / 2.0

	for i in range(modos.size()):
		var pos_x = inicio_x + i * (LARGURA_CARD + MARGEM_ENTRE_CARDS)
		_criar_card(i, modos[i], Vector2(pos_x, TOPO_CARDS))

	# Botão Voltar — canto superior esquerdo (não rouba espaço dos cards)
	var btn_voltar = Button.new()
	btn_voltar.text = "← Voltar"
	btn_voltar.position = Vector2(24, 26)
	btn_voltar.size = Vector2(120, 36)
	btn_voltar.add_theme_font_size_override("font_size", 15)
	btn_voltar.pressed.connect(_on_btn_voltar_pressed)
	add_child(btn_voltar)


# ─────────────────────────────────────────────
#  Constrói um card individual (modo de jogo)
# ─────────────────────────────────────────────
func _criar_card(modo_idx: int, modo: Dictionary, pos: Vector2) -> void:
	# Fundo do card
	var card = ColorRect.new()
	card.color = Color(0.15, 0.15, 0.25)
	card.position = pos
	card.size = Vector2(LARGURA_CARD, ALTURA_CARD)
	add_child(card)

	# Largura útil dentro do card
	var largura_util = LARGURA_CARD - PADDING_INTERNO * 2

	# Título do modo
	var titulo = Label.new()
	titulo.text = modo["nome"]
	titulo.add_theme_font_size_override("font_size", 26)
	titulo.modulate = Color(1.0, 1.0, 1.0)
	titulo.position = Vector2(0, Y_TITULO)
	titulo.size = Vector2(LARGURA_CARD, 36)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(titulo)

	# Placeholder da imagem
	var img_placeholder = ColorRect.new()
	img_placeholder.color = Color(0.25, 0.25, 0.35)
	img_placeholder.position = Vector2(PADDING_INTERNO, Y_IMAGEM)
	img_placeholder.size = Vector2(largura_util, ALTURA_IMAGEM)
	card.add_child(img_placeholder)

	var img_label = Label.new()
	img_label.text = "[ imagem em breve ]"
	img_label.add_theme_font_size_override("font_size", 15)
	img_label.modulate = Color(0.6, 0.6, 0.7)
	img_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	img_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	img_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	img_placeholder.add_child(img_label)

	# Descrição — usa custom_minimum_size + autowrap pra garantir wrap
	var desc = Label.new()
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(largura_util, 0)
	desc.position = Vector2(PADDING_INTERNO, Y_DESCRICAO)
	desc.size = Vector2(largura_util, ALTURA_DESCRICAO)
	desc.add_theme_font_size_override("font_size", 16)
	desc.modulate = Color(0.85, 0.85, 0.95)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	desc.clip_contents = true
	desc.text = modo["descricao"]
	card.add_child(desc)

	# Linha de pré-seleção (opcional — só Campeonato tem hoje)
	if modo.has("pre_selecao"):
		_criar_pre_selecao(modo_idx, modo["pre_selecao"], card)

	# Linha de opções (botões "Jogar")
	_criar_linha_opcoes(modo, card)


# ─────────────────────────────────────────────
#  Cria a linha de toggles de pré-seleção
# ─────────────────────────────────────────────
func _criar_pre_selecao(modo_idx: int, ps: Dictionary, card: Control) -> void:
	# Estado inicial
	pre_selecao_state[modo_idx] = ps["default"]
	pre_selecao_btns[modo_idx] = []

	# Rótulo
	var rotulo = Label.new()
	rotulo.text = ps["label"]
	rotulo.add_theme_font_size_override("font_size", 14)
	rotulo.modulate = Color(0.75, 0.75, 0.9)
	rotulo.position = Vector2(0, Y_PRE_SELECAO_LABEL)
	rotulo.size = Vector2(LARGURA_CARD, 20)
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(rotulo)

	# Botões toggle
	var opcoes = ps["opcoes"]
	var largura_btn = 88.0
	var espaco_btn = 16.0
	var total = largura_btn * opcoes.size() + espaco_btn * (opcoes.size() - 1)
	var inicio_x = (LARGURA_CARD - total) / 2.0

	for j in range(opcoes.size()):
		var op = opcoes[j]
		var btn = Button.new()
		btn.text = op["label"]
		btn.set_meta("valor", op["valor"])
		btn.position = Vector2(inicio_x + j * (largura_btn + espaco_btn), Y_PRE_SELECAO_BTN)
		btn.size = Vector2(largura_btn, ALTURA_PRE_SELECAO_BTN)
		btn.add_theme_font_size_override("font_size", 18)
		btn.pressed.connect(_on_pre_selecao_pressed.bind(modo_idx, op["valor"]))
		card.add_child(btn)
		pre_selecao_btns[modo_idx].append(btn)

	_atualizar_visual_pre_selecao(modo_idx)


# ─────────────────────────────────────────────
#  Cria a linha de opções (botões que navegam)
# ─────────────────────────────────────────────
func _criar_linha_opcoes(modo: Dictionary, card: Control) -> void:
	# Rótulo
	var rotulo = Label.new()
	rotulo.text = modo["opcoes_label"]
	rotulo.add_theme_font_size_override("font_size", 14)
	rotulo.modulate = Color(0.75, 0.75, 0.9)
	rotulo.position = Vector2(0, Y_OPCOES_LABEL)
	rotulo.size = Vector2(LARGURA_CARD, 20)
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(rotulo)

	# Botões
	var opcoes = modo["opcoes"]
	var largura_btn = 110.0
	var espaco_btn = 14.0
	var total = largura_btn * opcoes.size() + espaco_btn * (opcoes.size() - 1)
	var inicio_x = (LARGURA_CARD - total) / 2.0

	for j in range(opcoes.size()):
		var op = opcoes[j]
		var btn = Button.new()
		btn.text = op["label"]
		btn.position = Vector2(inicio_x + j * (largura_btn + espaco_btn), Y_OPCOES_BTN)
		btn.size = Vector2(largura_btn, ALTURA_OPCOES_BTN)
		btn.add_theme_font_size_override("font_size", 18)
		btn.pressed.connect(_on_opcao_pressed.bind(modo, op["valor"]))
		card.add_child(btn)


# ─────────────────────────────────────────────
#  Toggle de pré-seleção pressionado
# ─────────────────────────────────────────────
func _on_pre_selecao_pressed(modo_idx: int, valor) -> void:
	pre_selecao_state[modo_idx] = valor
	_atualizar_visual_pre_selecao(modo_idx)


# ─────────────────────────────────────────────
#  Atualiza o destaque dos toggles do card
# ─────────────────────────────────────────────
func _atualizar_visual_pre_selecao(modo_idx: int) -> void:
	if not pre_selecao_btns.has(modo_idx):
		return
	var selecionado = pre_selecao_state[modo_idx]
	for btn in pre_selecao_btns[modo_idx]:
		if btn.get_meta("valor") == selecionado:
			btn.modulate = COR_TOGGLE_ATIVO
		else:
			btn.modulate = COR_TOGGLE_INATIVO


# ─────────────────────────────────────────────
#  Botão de opção (Fácil/Normal/Difícil) pressionado
# ─────────────────────────────────────────────
func _on_opcao_pressed(modo: Dictionary, _valor) -> void:
	# Se o card tem pré-seleção, aplica o valor escolhido antes de navegar.
	# Hoje só o Campeonato usa isso (num_jogadores).
	if modo.has("pre_selecao"):
		var modo_idx = modos.find(modo)
		var num = pre_selecao_state.get(modo_idx, modo["pre_selecao"]["default"])
		if modo["nome"] == "Modo Campeonato":
			Campeonato.num_jogadores = int(num)

	# TODO: armazenar dificuldade (_valor) num autoload quando a regra
	# de número de pares por dificuldade estiver definida.

	get_tree().change_scene_to_file(modo["cena"])


# ─────────────────────────────────────────────
#  Botão Voltar
# ─────────────────────────────────────────────
func _on_btn_voltar_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu_screen.tscn")
