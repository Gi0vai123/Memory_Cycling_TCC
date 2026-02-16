extends Node2D

@export var card_scene: PackedScene
@export var usar_contagem := true
@export var contador_scene: PackedScene

var pontos_azul = 0
var pontos_vermelho = 0
var pontos_feitos = 0
var jogador_1 = str("")
var jogador_2 = str("")
var ponto_azul = 0
var ponto_vermelho = 0
var lado_escolhido := ""
var jogador_que_comeca := ""
var pares_encontrados := 0
var primeira_carta = null
var segunda_carta = null
var jogador_atual = ""
# define o ponto 0 e o ´ponto final onde a carta vai parar
var final_positions := [
	Vector2(-200, -200),
	Vector2(0, -200),
	Vector2(200, -200),
	Vector2(-200, -400),
	Vector2(0, -400),
	Vector2(200, -400)
]

var start_pos := Vector2(0, 0) # posição inicial única

func contagem_regressiva(contador):
	var label = contador.get_node("Contador") # pega o Label
	var contador_num = 3
	
	while contador_num > 0:
		label.text = str(contador_num)  # atualiza o texto da Label
		await get_tree().create_timer(1.0).timeout  # espera 1 segundo
		contador_num -= 1
	
	label.text = "VAI!"
	await get_tree().create_timer(0.5).timeout
	
	label.text = ""  # limpa a Label após a contagem



func _ready():
	randomize()
	start_jogo()  # chama a sequência do jogo
	definir_lados()
	var tamanho = get_viewport().get_visible_rect().size
	print(tamanho)

	
# sequência do jogo: contagem regressiva e depois criar cartas
func start_jogo() -> void:
	if usar_contagem and contador_scene:
		# instancia a cena do contador na árvore de nós
		var contador = contador_scene.instantiate()
		add_child(contador)
		# executa a contagem e aguarda terminar antes de criar as cartas
		await contagem_regressiva(contador)
		
		# remove a cena do contador após a contagem, para limpar a tela
		contador.queue_free()
		labelcolor()
		mostrar_sprite_equipe()
	# só depois cria as cartas
	criar_cartas()

func criar_cartas():
	var ids = [1,2,3,1,2,3]
	ids.shuffle() #embaralha
	
	for i in range(ids.size()):
		var carta = card_scene.instantiate() #instancia a cena para que eu possa pegar as variaveis

		var area = carta.get_node("carta")
		area.card_id = ids[i]

		# todas começam no mesmo lugar
		carta.position = start_pos
		
		add_child(carta)
		# conecta o signal da carta à função de verificação
		carta.get_node("carta").connect("carta_clicada", Callable(self, "verificar_carta"))
		
		# posição final definida manualmente
		var pos_final = final_positions[i]

	

		# animação suave
		var tween = create_tween()
		tween.tween_property(carta, "position", pos_final, 0.6)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_OUT)
			
func verificar_carta(carta):
	
	# se não houver primeira carta selecionada
	if primeira_carta == null:
		primeira_carta = carta
		bloqueio_de_cartas()
		
	elif segunda_carta == null:
		segunda_carta = carta
		bloqueio_de_cartas()
		
		# compara IDs
		if primeira_carta.card_id == segunda_carta.card_id:
			print("Você acertou!")
			pontos_ganhos()
			primeira_carta.get_node("CollisionShape2D").disabled = true
			segunda_carta.get_node("CollisionShape2D").disabled = true
			if pares_encontrados == 3:
				ganhou()
		else:
			print("Errou!")
			mudando_atual()
			# vira as cartas de volta 
			await get_tree().create_timer(0.5).timeout
			primeira_carta.virar()
			segunda_carta.virar()
			$Cartas/carta.mostrar_sprite()
			desbloquear_cartas()
			
		
		# limpa para próxima tentativa
		primeira_carta = null
		segunda_carta = null
		


func ganhou():
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
	
func bloquear_acerto():
	primeira_carta.get_node("CollisionShape2D").disabled = true
	segunda_carta.get_node("CollisionShape2D").disabled = true
	
func lado_oposto(lado):
	if lado == "azul":
		return "vermelho"
	else:
		return "azul"

	
func definir_lados():
	var lados = ["azul", "vermelho"]
	lado_escolhido = lados.pick_random()
	jogador_que_comeca = lados.pick_random()
	jogador_1 = jogador_que_comeca
	jogador_2 = lado_oposto(jogador_que_comeca)
	jogador_atual = jogador_que_comeca
	print("Lado escolhido:", lado_escolhido)
	print("Quem começa:", jogador_que_comeca)

func labelcolor():
	var labelTime = $LabelJogador
	labelTime.text = str(jogador_atual)
func mudando_atual():
	labelcolor()
	jogador_atual = lado_oposto(jogador_atual)
	print(jogador_atual)
	
func pontos_ganhos():
	pares_encontrados += 1
	match jogador_atual:
		"azul":
			ponto_azul += 1
		"vermelho":
			ponto_vermelho += 1
	print("Azul:", ponto_azul)
	print("Vermelho:", ponto_vermelho)
	
func mostrar_sprite_equipe():
	match jogador_atual:
		"azul": 
			$equipe_azul.visible = true
			$equipe_vermelha.visible = false
		"vermelho":
			$equipe_azul.visible = false
			$equipe_vermelha.visible = true
			
	
