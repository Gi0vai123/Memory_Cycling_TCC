extends Control

# ─────────────────────────────────────────────
#  Tela da Chave do Campeonato (layout dinâmico)
#  Funciona com chaves de 4, 6 ou 8 jogadores —
#  posiciona caixas e conectores com base nas
#  rodadas presentes em Campeonato.chave.
# ─────────────────────────────────────────────

const LARGURA_CAIXA: float = 255.0
const ALTURA_CAIXA: float = 86.0
const Y_INICIO: float = 110.0
const Y_FIM: float = 560.0

# Largura de cada coluna (rodada). col_x[r] = X_INICIO + r * COLUNA_LARGURA
const X_INICIO: float = 50.0
const COLUNA_LARGURA: float = 360.0

# Headers genéricos por número de rodadas total
# (escolhe o vetor certo com base em Campeonato.num_rodadas)
const HEADERS_2 := ["SEMIFINAL", "FINAL", "CAMPEÃO"]
const HEADERS_3 := ["1ª RODADA", "SEMIFINAL", "FINAL", "CAMPEÃO"]
const HEADERS_3_QUARTAS := ["QUARTAS DE FINAL", "SEMIFINAL", "FINAL", "CAMPEÃO"]

# Referências aos painéis: { idx: { panel, lbl_a, lbl_b, pos } }
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
	titulo.text = "CAMPEONATO (%d JOGADORES)" % Campeonato.num_jogadores
	titulo.add_theme_font_size_override("font_size", 30)
	titulo.modulate = Color(1.0, 0.85, 0.2)
	titulo.position = Vector2(0, 16)
	titulo.size = Vector2(1280, 50)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(titulo)

	# Agrupa partidas por rodada
	var partidas_por_rodada: Dictionary = {}
	for i in range(Campeonato.chave.size()):
		var r: int = Campeonato.chave[i].rodada
		if not partidas_por_rodada.has(r):
			partidas_por_rodada[r] = []
		partidas_por_rodada[r].append(i)

	# Headers das rodadas
	var headers = _escolher_headers()
	for r in range(Campeonato.num_rodadas + 1):
		if r >= headers.size():
			break
		var lbl = Label.new()
		lbl.text = headers[r]
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.modulate = Color(0.55, 0.75, 1.0)
		lbl.position = Vector2(X_INICIO + r * COLUNA_LARGURA, 72)
		add_child(lbl)

	# Cria as caixas de cada rodada
	for r in range(Campeonato.num_rodadas):
		if not partidas_por_rodada.has(r):
			continue
		var indices = partidas_por_rodada[r]
		var ys = _ys_distribuidos(indices.size())
		for k in range(indices.size()):
			var idx = indices[k]
			var pos = Vector2(X_INICIO + r * COLUNA_LARGURA, ys[k])
			_criar_caixa_partida(idx, pos)

	# Conectores: cada partida liga ao seu feed_idx
	for i in range(Campeonato.chave.size()):
		var p = Campeonato.chave[i]
		if p.feed_idx >= 0 and paineis_partidas.has(p.feed_idx):
			_desenhar_conector(i, p.feed_idx)

	# Conector final → coluna do campeão
	var ultima_idx = Campeonato.chave.size() - 1
	if paineis_partidas.has(ultima_idx):
		var pos_final = paineis_partidas[ultima_idx].pos
		var saida = Vector2(pos_final.x + LARGURA_CAIXA, pos_final.y + ALTURA_CAIXA / 2.0)
		var x_campeao = X_INICIO + Campeonato.num_rodadas * COLUNA_LARGURA
		_criar_conector(saida, Vector2(x_campeao, saida.y))

	# Label campeão
	var x_campeao_col = X_INICIO + Campeonato.num_rodadas * COLUNA_LARGURA
	label_campeao = Label.new()
	label_campeao.text = "???"
	label_campeao.add_theme_font_size_override("font_size", 20)
	label_campeao.modulate = Color(1.0, 0.85, 0.2)
	label_campeao.position = Vector2(x_campeao_col, 300)
	label_campeao.size = Vector2(220, 80)
	label_campeao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(label_campeao)

	# Status
	label_status = Label.new()
	label_status.text = ""
	label_status.add_theme_font_size_override("font_size", 18)
	label_status.modulate = Color(0.3, 1.0, 0.5)
	label_status.position = Vector2(50, 598)
	label_status.size = Vector2(900, 32)
	add_child(label_status)

	# Botão Jogar
	btn_jogar = Button.new()
	btn_jogar.text = "▶  JOGAR PRÓXIMA PARTIDA"
	btn_jogar.position = Vector2(400, 640)
	btn_jogar.size = Vector2(380, 54)
	btn_jogar.add_theme_font_size_override("font_size", 20)
	btn_jogar.pressed.connect(_on_btn_jogar_pressed)
	add_child(btn_jogar)

	# Botão Voltar ao menu
	var btn_voltar = Button.new()
	btn_voltar.text = "← Menu"
	btn_voltar.position = Vector2(40, 650)
	btn_voltar.size = Vector2(130, 44)
	btn_voltar.add_theme_font_size_override("font_size", 16)
	btn_voltar.pressed.connect(_on_btn_voltar_pressed)
	add_child(btn_voltar)


# ─────────────────────────────────────────────
#  Escolhe o vetor de headers conforme o formato
# ─────────────────────────────────────────────
func _escolher_headers() -> Array:
	if Campeonato.num_rodadas == 2:
		return HEADERS_2
	# 3 rodadas: 8 jogadores começam em quartas, 6 começam em "1ª rodada" (preliminares)
	if Campeonato.num_jogadores == 8:
		return HEADERS_3_QUARTAS
	return HEADERS_3


# ─────────────────────────────────────────────
#  Distribui N caixas verticalmente entre Y_INICIO e Y_FIM
# ─────────────────────────────────────────────
func _ys_distribuidos(n: int) -> Array:
	var resultado: Array = []
	if n <= 0:
		return resultado
	if n == 1:
		resultado.append((Y_INICIO + Y_FIM) / 2.0 - ALTURA_CAIXA / 2.0)
		return resultado
	var espaco_util = (Y_FIM - Y_INICIO) - ALTURA_CAIXA
	for i in range(n):
		var t = float(i) / float(n - 1)
		resultado.append(Y_INICIO + t * espaco_util)
	return resultado


# ─────────────────────────────────────────────
#  Cria a caixa visual de uma partida
# ─────────────────────────────────────────────
func _criar_caixa_partida(idx: int, pos: Vector2) -> void:
	var panel = Panel.new()
	panel.position = pos
	panel.size = Vector2(LARGURA_CAIXA, ALTURA_CAIXA)
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
	lbl_a.modulate = Color(0.55, 0.75, 1.0)
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
	lbl_b.modulate = Color(1.0, 0.5, 0.5)
	lbl_b.position = pos + Vector2(8, 58)
	lbl_b.size = Vector2(240, 26)
	add_child(lbl_b)

	paineis_partidas[idx] = {
		"panel": panel,
		"lbl_a": lbl_a,
		"lbl_b": lbl_b,
		"pos": pos,
	}


# ─────────────────────────────────────────────
#  Desenha um conector L entre duas partidas
# ─────────────────────────────────────────────
func _desenhar_conector(src_idx: int, dst_idx: int) -> void:
	var src_pos: Vector2 = paineis_partidas[src_idx].pos
	var dst_pos: Vector2 = paineis_partidas[dst_idx].pos
	var src_saida = Vector2(src_pos.x + LARGURA_CAIXA, src_pos.y + ALTURA_CAIXA / 2.0)
	var dst_entrada = Vector2(dst_pos.x, dst_pos.y + ALTURA_CAIXA / 2.0)
	var meio_x = (src_saida.x + dst_entrada.x) / 2.0

	_criar_conector(src_saida, Vector2(meio_x, src_saida.y))
	_criar_conector(Vector2(meio_x, src_saida.y), Vector2(meio_x, dst_entrada.y))
	_criar_conector(Vector2(meio_x, dst_entrada.y), dst_entrada)


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

		# Cor do painel
		if idx == prox_idx:
			refs.panel.modulate = Color(1.2, 1.2, 0.4)   # amarelo
		elif p.vencedor != "":
			refs.panel.modulate = Color(0.5, 0.5, 0.5)   # cinza = encerrada
		else:
			refs.panel.modulate = Color(1.0, 1.0, 1.0)

		# Risca o perdedor e destaca o vencedor
		if p.vencedor != "":
			if refs.lbl_a.text == p.vencedor:
				refs.lbl_a.modulate = Color(0.2, 1.0, 0.4)
				refs.lbl_b.modulate = Color(0.35, 0.35, 0.35)
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
