extends Control

# ─────────────────────────────────────────────
#  Tela da Chave do Campeonato
#  Exibe o bracket 8→4→2→1 construído em código.
#
#  Layout (1280×720):
#   x=50   Quartas (4 caixas)
#   x=420  Semifinal (2 caixas)
#   x=760  Final (1 caixa)
#   x=1050 Campeão
# ─────────────────────────────────────────────

# Referências aos painéis de cada partida  { idx: { panel, lbl_a, lbl_b } }
var paineis_partidas: Dictionary = {}
var label_status: Label
var btn_jogar: Button
var label_campeao: Label


func _ready() -> void:
	_criar_interface()
	_atualizar_chave()


# ─────────────────────────────────────────────
#  Constrói a interface
# ─────────────────────────────────────────────
func _criar_interface() -> void:

	# Fundo
	var fundo = ColorRect.new()
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fundo.color = Color(0.07, 0.07, 0.14)
	add_child(fundo)

	# Título
	var titulo = Label.new()
	titulo.text = "CAMPEONATO"
	titulo.add_theme_font_size_override("font_size", 34)
	titulo.modulate = Color(1.0, 0.85, 0.2)
	titulo.position = Vector2(0, 16)
	titulo.size = Vector2(1280, 50)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(titulo)

	# Headers das rodadas
	var rodada_labels = ["QUARTAS DE FINAL", "SEMIFINAL", "FINAL", "CAMPEÃO"]
	var rodada_x      = [50.0,              430.0,      770.0,   1055.0]
	for i in range(rodada_labels.size()):
		var lbl = Label.new()
		lbl.text = rodada_labels[i]
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.modulate = Color(0.55, 0.75, 1.0)
		lbl.position = Vector2(rodada_x[i], 72)
		add_child(lbl)

	# ── Quartas (índices 0-3) ──────────────────
	# 4 caixas distribuídas verticalmente entre y=100 e y=560
	var y_quartas = [100.0, 210.0, 330.0, 440.0]
	for i in range(4):
		_criar_caixa_partida(i, Vector2(50, y_quartas[i]))

	# ── Conector visual entre quartas e semis (linhas placeholder) ──
	# (Godot 2D não tem linhas nativas; usamos ColorRects finos)
	_criar_conector(Vector2(310, 145), Vector2(430, 145))   # Q1 → meio
	_criar_conector(Vector2(310, 255), Vector2(310, 145))   # Q2 → Q1
	_criar_conector(Vector2(310, 255), Vector2(430, 255))   # → semi1 entrada
	_criar_conector(Vector2(310, 375), Vector2(430, 375))   # Q3 → meio
	_criar_conector(Vector2(310, 485), Vector2(310, 375))   # Q4 → Q3
	_criar_conector(Vector2(310, 485), Vector2(430, 485))   # → semi2 entrada

	# ── Semifinais (índices 4-5) ───────────────
	# Centralizadas verticalmente entre cada par de quartas
	var y_semis = [175.0, 405.0]
	for i in range(2):
		_criar_caixa_partida(4 + i, Vector2(430, y_semis[i]))

	# ── Conector semis → final ─────────────────
	_criar_conector(Vector2(690, 220), Vector2(770, 220))
	_criar_conector(Vector2(690, 450), Vector2(690, 220))
	_criar_conector(Vector2(690, 450), Vector2(770, 450))

	# ── Final (índice 6) ───────────────────────
	_criar_caixa_partida(6, Vector2(770, 300))

	# ── Conector final → campeão ───────────────
	_criar_conector(Vector2(1030, 340), Vector2(1060, 340))

	# ── Label campeão ──────────────────────────
	label_campeao = Label.new()
	label_campeao.text = "???"
	label_campeao.add_theme_font_size_override("font_size", 20)
	label_campeao.modulate = Color(1.0, 0.85, 0.2)
	label_campeao.position = Vector2(1060, 310)
	label_campeao.size = Vector2(200, 60)
	label_campeao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(label_campeao)

	# ── Status (próxima partida) ───────────────
	label_status = Label.new()
	label_status.text = ""
	label_status.add_theme_font_size_override("font_size", 18)
	label_status.modulate = Color(0.3, 1.0, 0.5)
	label_status.position = Vector2(50, 598)
	label_status.size = Vector2(900, 32)
	add_child(label_status)

	# ── Botão Jogar ────────────────────────────
	btn_jogar = Button.new()
	btn_jogar.text = "▶  JOGAR PRÓXIMA PARTIDA"
	btn_jogar.position = Vector2(400, 640)
	btn_jogar.size = Vector2(380, 54)
	btn_jogar.add_theme_font_size_override("font_size", 20)
	btn_jogar.pressed.connect(_on_btn_jogar_pressed)
	add_child(btn_jogar)

	# ── Botão Voltar ao menu ───────────────────
	var btn_voltar = Button.new()
	btn_voltar.text = "← Menu"
	btn_voltar.position = Vector2(40, 650)
	btn_voltar.size = Vector2(130, 44)
	btn_voltar.add_theme_font_size_override("font_size", 16)
	btn_voltar.pressed.connect(_on_btn_voltar_pressed)
	add_child(btn_voltar)


# ─────────────────────────────────────────────
#  Cria a caixa visual de uma partida
# ─────────────────────────────────────────────
func _criar_caixa_partida(idx: int, pos: Vector2) -> void:
	var panel = Panel.new()
	panel.position = pos
	panel.size = Vector2(255, 86)
	add_child(panel)

	# Número da partida
	var lbl_num = Label.new()
	lbl_num.text = "P" + str(idx + 1)
	lbl_num.add_theme_font_size_override("font_size", 11)
	lbl_num.modulate = Color(0.5, 0.5, 0.5)
	lbl_num.position = pos + Vector2(4, 4)
	add_child(lbl_num)

	# Jogador A
	var lbl_a = Label.new()
	lbl_a.text = "???"
	lbl_a.add_theme_font_size_override("font_size", 16)
	lbl_a.modulate = Color(0.55, 0.75, 1.0)   # azulado
	lbl_a.position = pos + Vector2(8, 18)
	lbl_a.size = Vector2(240, 26)
	add_child(lbl_a)

	# Separador "vs"
	var lbl_vs = Label.new()
	lbl_vs.text = "— vs —"
	lbl_vs.add_theme_font_size_override("font_size", 11)
	lbl_vs.modulate = Color(0.45, 0.45, 0.45)
	lbl_vs.position = pos + Vector2(8, 44)
	add_child(lbl_vs)

	# Jogador B
	var lbl_b = Label.new()
	lbl_b.text = "???"
	lbl_b.add_theme_font_size_override("font_size", 16)
	lbl_b.modulate = Color(1.0, 0.5, 0.5)     # avermelhado
	lbl_b.position = pos + Vector2(8, 58)
	lbl_b.size = Vector2(240, 26)
	add_child(lbl_b)

	paineis_partidas[idx] = {
		"panel": panel,
		"lbl_a": lbl_a,
		"lbl_b": lbl_b
	}


# ─────────────────────────────────────────────
#  Cria um conector horizontal/vertical (linha fina)
# ─────────────────────────────────────────────
func _criar_conector(de: Vector2, para: Vector2) -> void:
	var linha = ColorRect.new()
	linha.color = Color(0.3, 0.3, 0.5, 0.7)

	if abs(de.x - para.x) > abs(de.y - para.y):
		# Horizontal
		linha.position = Vector2(min(de.x, para.x), de.y - 1)
		linha.size = Vector2(abs(para.x - de.x), 2)
	else:
		# Vertical
		linha.position = Vector2(de.x - 1, min(de.y, para.y))
		linha.size = Vector2(2, abs(para.y - de.y))

	add_child(linha)


# ─────────────────────────────────────────────
#  Atualiza todos os textos com o estado atual da chave
# ─────────────────────────────────────────────
func _atualizar_chave() -> void:
	var chave = Campeonato.chave
	var prox_idx = Campeonato.proxima_partida()

	for idx in paineis_partidas:
		var p = chave[idx]
		var refs = paineis_partidas[idx]

		# Nomes
		refs.lbl_a.text = p.jogadorA if p.jogadorA != "" else "???"
		refs.lbl_b.text = p.jogadorB if p.jogadorB != "" else "???"

		# Cor do painel: destaque na próxima partida
		if idx == prox_idx:
			refs.panel.modulate = Color(1.2, 1.2, 0.4)   # amarelo
		elif p.vencedor != "":
			refs.panel.modulate = Color(0.5, 0.5, 0.5)   # cinza = encerrada
		else:
			refs.panel.modulate = Color(1.0, 1.0, 1.0)

		# Risca o perdedor e destaca o vencedor
		if p.vencedor != "":
			if refs.lbl_a.text == p.vencedor:
				refs.lbl_a.modulate = Color(0.2, 1.0, 0.4)   # verde = venceu
				refs.lbl_b.modulate = Color(0.35, 0.35, 0.35) # cinza = perdeu
			else:
				refs.lbl_b.modulate = Color(0.2, 1.0, 0.4)
				refs.lbl_a.modulate = Color(0.35, 0.35, 0.35)

	# Campeão
	var campeao = Campeonato.campeao()
	if campeao != "":
		label_campeao.text = "🏆\n" + campeao
		label_campeao.modulate = Color(1.0, 0.85, 0.2)
		btn_jogar.visible = false
		label_status.text = "Campeonato encerrado! Campeão: " + campeao
	else:
		label_campeao.text = "???"
		btn_jogar.visible = prox_idx >= 0
		if prox_idx >= 0:
			var p = chave[prox_idx]
			label_status.text = "Próxima partida (P%d): %s  vs  %s" % [
				prox_idx + 1, p.jogadorA, p.jogadorB
			]
		else:
			label_status.text = "Aguardando partidas anteriores..."


# ─────────────────────────────────────────────
#  Botão: Jogar próxima partida
# ─────────────────────────────────────────────
func _on_btn_jogar_pressed() -> void:
	var idx = Campeonato.proxima_partida()
	if idx < 0:
		return
	Campeonato.iniciar_partida(idx)
	get_tree().change_scene_to_file("res://scenes/modoP.tscn")


# ─────────────────────────────────────────────
#  Botão: Voltar ao menu principal
# ─────────────────────────────────────────────
func _on_btn_voltar_pressed() -> void:
	Campeonato.resetar()
	get_tree().change_scene_to_file("res://scenes/menu_screen.tscn")
