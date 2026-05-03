extends Node

# ─────────────────────────────────────────────
#  Singleton: Campeonato
#  Registrar como AutoLoad no project.godot:
#  [autoload]
#  Campeonato="*res://scripts/campeonato.gd"
# ─────────────────────────────────────────────

# Estado geral
var campeonato_ativo: bool = false
var jogadores: Array = []

# A chave: array de 7 dicionários (4 quartas + 2 semis + 1 final)
# Cada dicionário: { rodada, jogadorA, jogadorB, vencedor }
var chave: Array = []

# Índice da partida que está sendo jogada no momento
var partida_atual_idx: int = -1

# Nomes usados na partida atual (lidos por cena.gd)
var jogador_a: String = ""
var jogador_b: String = ""


# ─────────────────────────────────────────────
#  Iniciar campeonato com 8 nomes
# ─────────────────────────────────────────────
func iniciar_campeonato(nomes: Array) -> void:
	jogadores = nomes.duplicate()
	jogadores.shuffle()   # aleatoriza a chave
	chave.clear()

	# Rodada 0 — Quartas de final (4 partidas)
	# Confrontos: [0]x[1], [2]x[3], [4]x[5], [6]x[7]
	for i in range(0, 8, 2):
		chave.append({
			"rodada": 0,
			"jogadorA": jogadores[i],
			"jogadorB": jogadores[i + 1],
			"vencedor": ""
		})

	# Rodada 1 — Semifinal (2 partidas)
	for i in range(2):
		chave.append({
			"rodada": 1,
			"jogadorA": "",
			"jogadorB": "",
			"vencedor": ""
		})

	# Rodada 2 — Final (1 partida)
	chave.append({
		"rodada": 2,
		"jogadorA": "",
		"jogadorB": "",
		"vencedor": ""
	})

	campeonato_ativo = true
	partida_atual_idx = -1


# ─────────────────────────────────────────────
#  Retorna o índice da próxima partida a jogar
#  (-1 se não houver)
# ─────────────────────────────────────────────
func proxima_partida() -> int:
	for i in range(chave.size()):
		var p = chave[i]
		if p.vencedor == "" and p.jogadorA != "" and p.jogadorB != "":
			return i
	return -1


# ─────────────────────────────────────────────
#  Prepara os dados da partida antes de mudar de cena
# ─────────────────────────────────────────────
func iniciar_partida(idx: int) -> void:
	partida_atual_idx = idx
	jogador_a = chave[idx].jogadorA
	jogador_b = chave[idx].jogadorB


# ─────────────────────────────────────────────
#  Registra o vencedor da partida atual
#  e propaga para a próxima rodada
# ─────────────────────────────────────────────
func registrar_resultado(vencedor: String) -> void:
	if partida_atual_idx < 0:
		return

	chave[partida_atual_idx].vencedor = vencedor
	_propagar_vencedores()


# ─────────────────────────────────────────────
#  Lógica interna: preenche jogadores nas rodadas seguintes
#
#  Estrutura dos índices na chave:
#    0: Q1 (jA→S1.jogA)   1: Q2 (jA→S1.jogB)
#    2: Q3 (jA→S2.jogA)   3: Q4 (jA→S2.jogB)
#    4: S1 (jA→F.jogA)
#    5: S2 (jA→F.jogB)
#    6: Final
# ─────────────────────────────────────────────
func _propagar_vencedores() -> void:
	# Quartas → Semifinais
	# S1 (idx 4): recebe vencedor de Q1 (idx 0) e Q2 (idx 1)
	# S2 (idx 5): recebe vencedor de Q3 (idx 2) e Q4 (idx 3)
	for semi_i in range(2):
		var q_a_idx = semi_i * 2        # 0 ou 2
		var q_b_idx = semi_i * 2 + 1   # 1 ou 3
		var semi_idx = 4 + semi_i      # 4 ou 5

		if chave[q_a_idx].vencedor != "":
			chave[semi_idx].jogadorA = chave[q_a_idx].vencedor
		if chave[q_b_idx].vencedor != "":
			chave[semi_idx].jogadorB = chave[q_b_idx].vencedor

	# Semifinais → Final
	if chave[4].vencedor != "":
		chave[6].jogadorA = chave[4].vencedor
	if chave[5].vencedor != "":
		chave[6].jogadorB = chave[5].vencedor


# ─────────────────────────────────────────────
#  Retorna o nome do campeão (ou "" se ainda não definido)
# ─────────────────────────────────────────────
func campeao() -> String:
	if chave.size() == 7:
		return chave[6].vencedor
	return ""


# ─────────────────────────────────────────────
#  Reseta tudo (útil para jogar novamente)
# ─────────────────────────────────────────────
func resetar() -> void:
	campeonato_ativo = false
	jogadores.clear()
	chave.clear()
	partida_atual_idx = -1
	jogador_a = ""
	jogador_b = ""
