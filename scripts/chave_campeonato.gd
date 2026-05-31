extends Control

# ─────────────────────────────────────────────
#  Tela da Chave do Campeonato (layout dinamico).
#
#  O chrome (titulo, status, botoes, campeao) eh editor-built
#  em chave_campeonato.tscn. As caixas das partidas e os
#  conectores sao gerados em codigo dentro do BracketContainer,
#  ja que a estrutura varia por formato (4/6/8 jogadores).
# ─────────────────────────────────────────────

const LARGURA_CAIXA: float = 255.0
const ALTURA_CAIXA: float = 86.0
const Y_INICIO: float = 110.0
const Y_FIM: float = 560.0
const X_INICIO: float = 50.0
const COLUNA_LARGURA: float = 360.0

const HEADERS_2 := ["SEMIFINAL", "FINAL", "CAMPEÃO"]
const HEADERS_3 := ["1ª RODADA", "SEMIFINAL", "FINAL", "CAMPEÃO"]
const HEADERS_3_QUARTAS := ["QUARTAS DE FINAL", "SEMIFINAL", "FINAL", "CAMPEÃO"]

@onready var titulo: Label = $Titulo
@onready var bracket: Control = $BracketContainer
@onready var label_status: Label = $LabelStatus
@onready var label_campeao: Label = $LabelCampeao
@onready var btn_jogar: Button = $BtnJogar

# Referencias aos paineis criados: { idx: { panel, lbl_a, lbl_b, pos } }
var paineis_partidas: Dictionary = {}


func _ready() -> void:
	titulo.text = "CAMPEONATO (%d JOGADORES)" % Campeonato.num_jogadores
	_montar_bracket()
	_atualizar_chave()


# ─────────────────────────────────────────────
#  Constroi o bracket dentro do BracketContainer
# ─────────────────────────────────────────────
func _montar_bracket() -> void:
	# Limpa filhos do container (re-entradas)
	for child in bracket.get_children():
		child.queue_free()
	paineis_partidas.clear()

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
		lbl.modulate = Color(0.85, 0.85, 0.95)
		lbl.position = Vector2(X_INICIO + r * COLUNA_LARGURA, 72)
		bracket.add_child(lbl)

	# Caixas
	for r in range(Campeonato.num_rodadas):
		if not partidas_por_rodada.has(r):
			continue
		var indices = partidas_por_rodada[r]
		var ys = _ys_distribuidos(indices.size())
		for k in range(indices.size()):
			var idx = indices[k]
			var pos = Vector2(X_INICIO + r * COLUNA_LARGURA, ys[k])
			_criar_caixa_partida(idx, pos)

	# Conectores
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


# ─────────────────────────────────────────────
#  Escolhe o vetor de headers conforme o formato
# ─────────────────────────────────────────────
func _escolher_headers() -> Array:
	if Campeonato.num_rodadas == 2:
		return HEADERS_2
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
#  Cria a caixa visual de uma partida (no BracketContainer)
# ─────────────────────────────────────────────
func _criar_caixa_partida(idx: int, pos: Vector2) -> void:
	var panel = Panel.new()
	panel.position = pos
	panel.size = Vector2(LARGURA_CAIXA, ALTURA_CAIXA)
	bracket.add_child(panel)

	var lbl_num = Label.new()
	lbl_num.text = "P" + str(idx + 1)
	lbl_num.add_theme_font_size_override("font_size", 11)
	lbl_num.modulate = Color(0.6, 0.6, 0.7)
	lbl_num.position = pos + Vector2(4, 4)
	bracket.add_child(lbl_num)

	var lbl_a = Label.new()
	lbl_a.text = "???"
	lbl_a.add_theme_font_size_override("font_size", 16)
	lbl_a.modulate = Color(0.55, 0.85, 1.0)
	lbl_a.position = pos + Vector2(8, 18)
	lbl_a.size = Vector2(240, 26)
	bracket.add_child(lbl_a)

	var lbl_vs = Label.new()
	lbl_vs.text = "— vs —"
	lbl_vs.add_theme_font_size_override("font_size", 11)
	lbl_vs.modulate = Color(0.6, 0.6, 0.7)
	lbl_vs.position = pos + Vector2(8, 44)
	bracket.add_child(lbl_vs)

	var lbl_b = Label.new()
	lbl_b.text = "???"
	lbl_b.add_theme_font_size_override("font_size", 16)
	lbl_b.modulate = Color(1.0, 0.55, 0.7)
	lbl_b.position = pos + Vector2(8, 58)
	lbl_b.size = Vector2(240, 26)
	bracket.add_child(lbl_b)

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
	linha.color = Color(0.5, 0.4, 0.6, 0.7)

	if abs(de.x - para.x) > abs(de.y - para.y):
		linha.position = Vector2(min(de.x, para.x), de.y - 1)
		linha.size = Vector2(abs(para.x - de.x), 2)
	else:
		linha.position = Vector2(de.x - 1, min(de.y, para.y))
		linha.size = Vector2(2, abs(para.y - de.y))

	bracket.add_child(linha)


# ─────────────────────────────────────────────
#  Atualiza todos os textos com o estado atual da chave
# ─────────────────────────────────────────────
func _atualizar_chave() -> void:
	var chave = Campeonato.chave
	var prox_idx = Campeonato.proxima_partida()

	for idx in paineis_partidas:
		var p = chave[idx]
		var refs = paineis_partidas[idx]

		refs.lbl_a.text = p.jogadorA if p.jogadorA != "" else "???"
		refs.lbl_b.text = p.jogadorB if p.jogadorB != "" else "???"

		if idx == prox_idx:
			refs.panel.modulate = Color(1.3, 1.1, 0.5)
		elif p.vencedor != "":
			refs.panel.modulate = Color(0.55, 0.55, 0.65)
		else:
			refs.panel.modulate = Color(1.0, 1.0, 1.0)

		if p.vencedor != "":
			if refs.lbl_a.text == p.vencedor:
				refs.lbl_a.modulate = Color(0.95, 0.78, 0.3)
				refs.lbl_b.modulate = Color(0.45, 0.45, 0.5)
			else:
				refs.lbl_b.modulate = Color(0.95, 0.78, 0.3)
				refs.lbl_a.modulate = Color(0.45, 0.45, 0.5)

	var campeao = Campeonato.campeao()
	if campeao != "":
		label_campeao.text = "🏆\n" + campeao
		label_campeao.modulate = Color(0.95, 0.78, 0.3)
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
