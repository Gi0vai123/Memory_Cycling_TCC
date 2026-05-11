extends Node

# ─────────────────────────────────────────────
#  Singleton: Campeonato
#  Registrado como AutoLoad em project.godot:
#  [autoload]
#  Campeonato="*res://scripts/campeonato.gd"
#
#  Suporta chaves de 4, 6 ou 8 jogadores.
#  Cada partida guarda feed_idx/feed_slot — o índice
#  e o slot (A/B) para onde manda o vencedor.
# ─────────────────────────────────────────────

# Estado geral
var campeonato_ativo: bool = false
var jogadores: Array = []

# Quantidade de jogadores escolhida na seleção de modo (4, 6 ou 8)
var num_jogadores: int = 8

# Quantidade de rodadas da chave atual (semis+final = 2; quartas+semis+final = 3)
var num_rodadas: int = 0

# A chave: array de partidas
# Cada partida: { rodada, jogadorA, jogadorB, vencedor, feed_idx, feed_slot }
#   feed_idx: índice da partida que recebe o vencedor (-1 se for a final)
#   feed_slot: "A" ou "B" — slot que o vencedor vai ocupar
var chave: Array = []

# Índice da partida que está sendo jogada no momento
var partida_atual_idx: int = -1

# Nomes usados na partida atual (lidos por cena.gd)
var jogador_a: String = ""
var jogador_b: String = ""


# ─────────────────────────────────────────────
#  Iniciar campeonato com a lista de nomes
#  (o tamanho determina o formato da chave)
# ─────────────────────────────────────────────
func iniciar_campeonato(nomes: Array) -> void:
	jogadores = nomes.duplicate()
	jogadores.shuffle()   # aleatoriza a chave
	chave.clear()
	num_jogadores = jogadores.size()

	match num_jogadores:
		4:
			_montar_chave_4()
		6:
			_montar_chave_6()
		8:
			_montar_chave_8()
		_:
			# Fallback: tenta 8 (mantém compatibilidade)
			_montar_chave_8()

	campeonato_ativo = true
	partida_atual_idx = -1


# ─────────────────────────────────────────────
#  Helper para criar uma partida
# ─────────────────────────────────────────────
func _partida(rodada: int, jA: String, jB: String, feed_idx: int, feed_slot: String) -> Dictionary:
	return {
		"rodada": rodada,
		"jogadorA": jA,
		"jogadorB": jB,
		"vencedor": "",
		"feed_idx": feed_idx,
		"feed_slot": feed_slot,
	}


# ─────────────────────────────────────────────
#  4 jogadores: 2 semis + 1 final
#    Índices: 0=Semi1, 1=Semi2, 2=Final
# ─────────────────────────────────────────────
func _montar_chave_4() -> void:
	num_rodadas = 2
	chave.append(_partida(0, jogadores[0], jogadores[1], 2, "A"))
	chave.append(_partida(0, jogadores[2], jogadores[3], 2, "B"))
	chave.append(_partida(1, "", "", -1, ""))


# ─────────────────────────────────────────────
#  6 jogadores: 2 preliminares + 2 semis (com byes) + 1 final
#    Jogadores 0 e 1 (após shuffle) são cabeças-de-chave
#    Índices: 0=Prelim1, 1=Prelim2, 2=Semi1, 3=Semi2, 4=Final
# ─────────────────────────────────────────────
func _montar_chave_6() -> void:
	num_rodadas = 3
	# Preliminares — disputadas pelos jogadores 2..5
	chave.append(_partida(0, jogadores[2], jogadores[3], 2, "B"))
	chave.append(_partida(0, jogadores[4], jogadores[5], 3, "B"))
	# Semis — jogadores 0 e 1 entram com bye no slot A
	chave.append(_partida(1, jogadores[0], "", 4, "A"))
	chave.append(_partida(1, jogadores[1], "", 4, "B"))
	# Final
	chave.append(_partida(2, "", "", -1, ""))


# ─────────────────────────────────────────────
#  8 jogadores: 4 quartas + 2 semis + 1 final
#    Índices: 0..3=Quartas, 4=Semi1, 5=Semi2, 6=Final
# ─────────────────────────────────────────────
func _montar_chave_8() -> void:
	num_rodadas = 3
	# Quartas
	chave.append(_partida(0, jogadores[0], jogadores[1], 4, "A"))
	chave.append(_partida(0, jogadores[2], jogadores[3], 4, "B"))
	chave.append(_partida(0, jogadores[4], jogadores[5], 5, "A"))
	chave.append(_partida(0, jogadores[6], jogadores[7], 5, "B"))
	# Semis
	chave.append(_partida(1, "", "", 6, "A"))
	chave.append(_partida(1, "", "", 6, "B"))
	# Final
	chave.append(_partida(2, "", "", -1, ""))


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
#  e propaga para a próxima rodada via feed_idx/feed_slot
# ─────────────────────────────────────────────
func registrar_resultado(vencedor: String) -> void:
	if partida_atual_idx < 0:
		return

	chave[partida_atual_idx].vencedor = vencedor
	_propagar_vencedor(partida_atual_idx)


func _propagar_vencedor(idx: int) -> void:
	var p = chave[idx]
	if p.feed_idx < 0:
		return
	if p.feed_slot == "A":
		chave[p.feed_idx].jogadorA = p.vencedor
	else:
		chave[p.feed_idx].jogadorB = p.vencedor


# ─────────────────────────────────────────────
#  Retorna o nome do campeão (vencedor da última partida)
# ─────────────────────────────────────────────
func campeao() -> String:
	if chave.is_empty():
		return ""
	return chave[chave.size() - 1].vencedor


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
	# num_jogadores fica preservado — usado pela tela de cadastro
