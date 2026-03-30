extends Node2D
@export var card_scene: PackedScene
@export var usar_contagem = true
@onready var contador_scene = $Contador
@onready var barra_azul = $ProgressBarA
@onready var barra_vermelha = $ProgressBarV
@onready var pos_xy_deck = $Cards/Deck
@onready var seta_azul = $ProgressBarA/setaazul
@onready var seta_vermelha = $ProgressBarV/setavermelha

var tempo_total = 100.0
var tempo_azul = tempo_total
var tempo_vermelho = tempo_total
var tempo_ativo = false
var cartas = []
var pontos_azul = 0
var pontos_vermelho = 0
var pontos_feitos = 0
var jogador_1 = str("")
var jogador_2 = str("")
var lado_escolhido = ""
var jogador_que_comeca = ""
var pares_encontrados = 0
var primeira_carta = null
var segunda_carta = null
var jogador_atual = ""

var valor_anterior_azul = 0.0
var valor_anterior_vermelho = 0.0
	
var colunas = 8
var espacamento_x = 130
var espacamento_y = 150
var start_x = -400
var start_y = -400

var final_positions = []
var start_pos = Vector2(0, 0)

func gerar_posicoes(total_cartas):
	final_positions.clear()

	for i in range(total_cartas):
		var col = i % colunas
		var row = i / colunas
		
		var pos_x = start_x + col * espacamento_x
		var pos_y = start_y + row * espacamento_y
		final_positions.append(Vector2(pos_x, pos_y))

func contagem_regressiva(contador):
	var contador_num = 3
	
	contador.visible = true
	
	while contador_num > 0:
		contador.text = str(contador_num)
		await get_tree().create_timer(1.0).timeout
		contador_num -= 1
	
	contador.text = "VAI!"
	await get_tree().create_timer(0.5).timeout
	contador.text = ""

func _ready():
	randomize()
	definir_lados()
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
	
	criar_cartas()

func criar_cartas():

	var quantidade_pares = 12
	var ids = []

	for i in range(1, quantidade_pares + 1):
		ids.append(i)
		ids.append(i)
		
	ids.shuffle()
	
	gerar_posicoes(ids.size())
	cartas.clear()
	
	for i in range(ids.size()):
		var carta = card_scene.instantiate()
		
		var area = carta.get_node("carta")
		area.card_id = ids[i]
		
		area.mostrar_sprite()
		carta.position = start_pos
		add_child(carta)
		cartas.append(area)
		
		area.connect("carta_clicada", Callable(self, "verificar_carta"))

		var pos_final = final_positions[i]
		
		var tween = create_tween()
		tween.tween_property(carta, "position", pos_final, 0.4)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_OUT)
		area.pode_animar = false
		await tween.finished
		
		await get_tree().create_timer(0.05).timeout

	# depois que TODAS terminarem
	await mostrar_cartas_inicial()
	for carta in cartas:
		carta.pode_animar = true

func mostrar_cartas_inicial():
	
	tempo_ativo = false
	atualizar_barra_jogador()
	# vira todas pra frente
	for carta in cartas:
		carta.get_node("CollisionShape2D").disabled = true
		carta.virar()
		
	await get_tree().create_timer(4.0).timeout
	
	# vira todas pra trás
	for carta in cartas:
		carta.virar()
		carta.get_node("CollisionShape2D").disabled = false
	
	# agora começa o tempo
	tempo_ativo = true
	

func timer_bar(delta):

	if jogador_atual == "azul":
		if tempo_azul > 0:
			valor_anterior_azul = barra_azul.value
			tempo_azul -= delta
			barra_azul.value = (tempo_azul / tempo_total) * barra_azul.max_value
			var diferenca = valor_anterior_azul - barra_azul.value
			atualizar_setas(diferenca)
		else:
			tempo_ativo = false
			fim_de_tempo()
			reiniciar_jogo()

	else:
		if tempo_vermelho > 0:
			valor_anterior_vermelho = barra_vermelha.value
			tempo_vermelho -= delta
			barra_vermelha.value = (tempo_vermelho / tempo_total) * barra_vermelha.max_value
			var diferenca = valor_anterior_vermelho - barra_vermelha.value
			atualizar_setas(diferenca)
		else:
			tempo_ativo = false
			fim_de_tempo()
			reiniciar_jogo()
	
			
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

	
	# porcentagem (0 a 1)
	var p_azul = barra_azul.value
	var p_vermelho = barra_vermelha.value 
	
	var largura = barra_azul.size.x
	var pixels_por_valor = largura / barra_azul.max_value
	var movimento = diferenca * pixels_por_valor
	
	if p_azul > 0 and jogador_atual == "azul":
		seta_azul.global_position.x -= movimento
	elif p_vermelho > 0:
		seta_vermelha.global_position.x -= movimento
	

func fim_de_tempo():
	print("O tempo acabou!")

func verificar_carta(carta):
	if primeira_carta == null:
		primeira_carta = carta
		bloqueio_de_cartas()
		
	elif segunda_carta == null:
		segunda_carta = carta
		bloqueio_de_cartas()
		
		if primeira_carta.card_id == segunda_carta.card_id:
			pontos_ganhos()
			primeira_carta.get_node("CollisionShape2D").disabled = true
			segunda_carta.get_node("CollisionShape2D").disabled = true
			if pares_encontrados == 5:
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
	if jogador_atual == "azul":
		print("Jogador Azul Ganhou!")
	else:
		print("Jogador Vermelho Ganhou!")
	await get_tree().create_timer(1.5).timeout
	reiniciar_jogo()

func reiniciar_jogo():
	get_tree().reload_current_scene()



func bloqueio_de_cartas():
	if primeira_carta != null:
		primeira_carta.get_node("CollisionShape2D").disabled = true
	if segunda_carta != null:
		segunda_carta.get_node("CollisionShape2D").disabled = true

func desbloquear_cartas():
	if primeira_carta != null:
		primeira_carta.get_node("CollisionShape2D").disabled = false
	if segunda_carta != null:
		segunda_carta.get_node("CollisionShape2D").disabled = false

func lado_oposto(lado):
	return "vermelho" if lado == "azul" else "azul"

func definir_lados():
	var lados = ["azul", "vermelho"]
	lado_escolhido = lados.pick_random()
	jogador_que_comeca = lados.pick_random()
	jogador_1 = jogador_que_comeca
	jogador_2 = lado_oposto(jogador_que_comeca)
	jogador_atual = jogador_que_comeca

func textJ():
	$LabelJogador.text = str(jogador_atual)

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

func mostrar_sprite_equipe():
	match jogador_atual:
		"azul":
			$equipe_azul.visible = true
			$equipe_vermelha.visible = false
		"vermelho":
			$equipe_azul.visible = false
			$equipe_vermelha.visible = true

func atualizar_labels():
	$PontosA.text = "Pontos da equipe azul: " + str(pontos_azul)
	$PontosV.text = "Pontos da equipe vermelha: " + str(pontos_vermelho)
