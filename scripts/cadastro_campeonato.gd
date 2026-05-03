extends Control

# ─────────────────────────────────────────────
#  Tela de cadastro dos 8 jogadores
#  A UI é construída em código (_criar_interface)
#  para manter o foco na lógica.
# ─────────────────────────────────────────────

var campos_nomes: Array = []   # Array de LineEdit


func _ready() -> void:
	_criar_interface()


# ─────────────────────────────────────────────
#  Monta a tela de cadastro via código
# ─────────────────────────────────────────────
func _criar_interface() -> void:

	# Fundo escuro
	var fundo = ColorRect.new()
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fundo.color = Color(0.07, 0.07, 0.14)
	add_child(fundo)

	# Título
	var titulo = Label.new()
	titulo.text = "CAMPEONATO — CADASTRO DE JOGADORES"
	titulo.add_theme_font_size_override("font_size", 30)
	titulo.modulate = Color(1.0, 0.85, 0.2)
	titulo.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	titulo.offset_top = 24
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(titulo)

	# Subtítulo
	var sub = Label.new()
	sub.text = "Preencha os 8 nomes. Campos em branco viram 'Jogador N'."
	sub.add_theme_font_size_override("font_size", 16)
	sub.modulate = Color(0.7, 0.7, 0.7)
	sub.position = Vector2(0, 72)
	sub.size = Vector2(1280, 30)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(sub)

	# Dois grupos de 4 campos lado a lado
	# Coluna esquerda (jogadores 1-4) e direita (5-8)
	var colunas_x = [240.0, 720.0]
	var start_y = 130.0
	var espaco_y = 80.0

	for col in range(2):
		for linha in range(4):
			var num_jogador = col * 4 + linha + 1
			var pos_y = start_y + linha * espaco_y
			var pos_x = colunas_x[col]

			# Label com número do jogador
			var lbl = Label.new()
			lbl.text = "Jogador " + str(num_jogador) + ":"
			lbl.position = Vector2(pos_x, pos_y)
			lbl.add_theme_font_size_override("font_size", 18)
			lbl.modulate = Color(0.85, 0.85, 1.0)
			add_child(lbl)

			# Campo de texto
			var campo = LineEdit.new()
			campo.placeholder_text = "Nome do jogador " + str(num_jogador)
			campo.position = Vector2(pos_x, pos_y + 28)
			campo.size = Vector2(300, 40)
			campo.add_theme_font_size_override("font_size", 17)
			add_child(campo)
			campos_nomes.append(campo)

	# Label de aviso (fica invisível até tentar sem preencher)
	var aviso = Label.new()
	aviso.name = "Aviso"
	aviso.text = ""
	aviso.modulate = Color(1.0, 0.3, 0.3)
	aviso.position = Vector2(0, 490)
	aviso.size = Vector2(1280, 30)
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aviso.add_theme_font_size_override("font_size", 17)
	add_child(aviso)

	# Botão GERAR CHAVE
	var btn = Button.new()
	btn.name = "BtnGerarChave"
	btn.text = "GERAR CHAVE"
	btn.position = Vector2(490, 540)
	btn.size = Vector2(300, 55)
	btn.add_theme_font_size_override("font_size", 22)
	btn.pressed.connect(_on_btn_gerar_chave_pressed)
	add_child(btn)

	# Botão Voltar
	var btn_voltar = Button.new()
	btn_voltar.text = "← Voltar"
	btn_voltar.position = Vector2(40, 650)
	btn_voltar.size = Vector2(140, 44)
	btn_voltar.add_theme_font_size_override("font_size", 16)
	btn_voltar.pressed.connect(_on_btn_voltar_pressed)
	add_child(btn_voltar)


# ─────────────────────────────────────────────
#  Botão: Gerar Chave
# ─────────────────────────────────────────────
func _on_btn_gerar_chave_pressed() -> void:
	var nomes: Array = []
	var aviso = get_node("Aviso")

	for i in range(campos_nomes.size()):
		var texto = campos_nomes[i].text.strip_edges()
		if texto == "":
			texto = "Jogador " + str(i + 1)
		nomes.append(texto)

	# Verifica nomes duplicados (opcional: aviso)
	var unicos = {}
	var tem_duplicata = false
	for nome in nomes:
		if unicos.has(nome):
			tem_duplicata = true
			break
		unicos[nome] = true

	if tem_duplicata:
		aviso.text = "⚠ Existem nomes repetidos. Corrija antes de continuar."
		return

	aviso.text = ""

	Campeonato.iniciar_campeonato(nomes)
	get_tree().change_scene_to_file("res://scenes/chave_campeonato.tscn")


# ─────────────────────────────────────────────
#  Botão: Voltar ao menu
# ─────────────────────────────────────────────
func _on_btn_voltar_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu_screen.tscn")
