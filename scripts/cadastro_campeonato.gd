extends Control

# ─────────────────────────────────────────────
#  Tela de cadastro dos jogadores do campeonato (editor-built).
#  Os 8 pares (LblJog1..LblJog8 + CampoJog1..CampoJog8) sao
#  pre-declarados em cadastro_campeonato.tscn — o script soh
#  esconde/reposiciona com base em Campeonato.num_jogadores.
# ─────────────────────────────────────────────

@onready var titulo: Label = $Titulo
@onready var subtitulo: Label = $Subtitulo
@onready var aviso: Label = $Aviso

# Indice 0 = jogador 1, indice 7 = jogador 8
var labels: Array = []
var campos: Array = []


func _ready() -> void:
	# Monta os arrays de referencia
	for i in range(1, 9):
		labels.append(get_node("LblJog" + str(i)))
		campos.append(get_node("CampoJog" + str(i)))

	_ajustar_para_n_jogadores()


# ─────────────────────────────────────────────
#  Ajusta titulo/subtitulo, visibilidade e posicao
#  dos campos com base em Campeonato.num_jogadores
# ─────────────────────────────────────────────
func _ajustar_para_n_jogadores() -> void:
	var n = Campeonato.num_jogadores
	if n != 4 and n != 6 and n != 8:
		n = 8

	titulo.text = "CAMPEONATO — CADASTRO DE %d JOGADORES" % n
	subtitulo.text = "Preencha os %d nomes. Campos em branco viram 'Jogador N'." % n

	# Layout em 2 colunas (mesma logica do codigo original)
	var linhas_por_coluna = int(ceil(n / 2.0))
	var colunas_x = [240.0, 720.0]
	var start_y = 130.0
	var espaco_y = 80.0

	for i in range(8):
		if i < n:
			var col = 0 if i < linhas_por_coluna else 1
			var linha = i if col == 0 else i - linhas_por_coluna
			var pos_x = colunas_x[col]
			var pos_y = start_y + linha * espaco_y
			labels[i].position = Vector2(pos_x, pos_y)
			campos[i].position = Vector2(pos_x, pos_y + 28)
			labels[i].visible = true
			campos[i].visible = true
		else:
			labels[i].visible = false
			campos[i].visible = false


# ─────────────────────────────────────────────
#  Botão: Gerar Chave
# ─────────────────────────────────────────────
func _on_btn_gerar_chave_pressed() -> void:
	var n = Campeonato.num_jogadores
	if n != 4 and n != 6 and n != 8:
		n = 8

	var nomes: Array = []
	for i in range(n):
		var texto = campos[i].text.strip_edges()
		if texto == "":
			texto = "Jogador " + str(i + 1)
		nomes.append(texto)

	# Verifica nomes duplicados
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
#  Botão: Voltar à seleção de modo
# ─────────────────────────────────────────────
func _on_btn_voltar_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/selecao_modo.tscn")
