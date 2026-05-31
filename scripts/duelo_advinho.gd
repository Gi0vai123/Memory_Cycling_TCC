extends Node2D

@onready var baralho_azul = $BaralhoA
@onready var baralho_vermelho = $BaralhoV
@onready var P_vermelho = $CanvasLayer/PontosV
@onready var P_Azul = $CanvasLayer/PontosA
@onready var Vencedor = $CanvasLayer/Vencedor
@onready var menu_pause = $Pause


var pontos_azul: int = 0
var pontos_vermelho: int = 0

var todas_cartas = []
var acertos: int = 0
var turno_atual: String = ""
var carta_propria: Area2D = null
var carta_oponente: Area2D = null
var fase_escolha: String = ""

var cartas_navegaveis: Array = []
var cursor_index: int = 0
var cursor_ativo: bool = false

const DEBUG_UM_CONTROLE = true
const DEADZONE = 0.5
const COOLDOWN_MOVIMENTO = 0.2

var cooldown_timer: float = 0.0
var total_pares: int = 3

func _ready():
	match Dificuldade.pares:
		4: total_pares = 4
		5: total_pares = 5
		_: total_pares = 3
	iniciar_duelo()

func _process(delta):
	if cooldown_timer > 0:
		cooldown_timer -= delta
	if not cartas_navegaveis.is_empty() and cooldown_timer <= 0:
		_processar_analogico()

func _processar_analogico():
	var device = 0 if DEBUG_UM_CONTROLE else (0 if turno_atual == "azul" else 1)
	var h = Input.get_joy_axis(device, JOY_AXIS_LEFT_X)

	if h > DEADZONE:
		mover_cursor(1)
		cooldown_timer = COOLDOWN_MOVIMENTO
	elif h < -DEADZONE:
		mover_cursor(-1)
		cooldown_timer = COOLDOWN_MOVIMENTO

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if get_tree().paused:
			menu_pause.despausar()
		else:
			menu_pause.pausar()
	if cartas_navegaveis.is_empty():
		return
	if not DEBUG_UM_CONTROLE:
		if event is InputEventJoypadButton:
			var device_permitido = 0 if turno_atual == "azul" else 1
			if event.device != device_permitido:
				return
	if event.is_action_pressed("ui_accept") and cursor_ativo:
		ao_clicar_carta(cartas_navegaveis[cursor_index])

func mover_cursor(direcao: int):
	if cartas_navegaveis.is_empty():
		return
	# Primeiro movimento do controle ativa o cursor sem aplicar direcao
	if not cursor_ativo:
		cursor_ativo = true
		cartas_navegaveis[cursor_index].focar()
		return
	cartas_navegaveis[cursor_index].desfocar()
	cursor_index = (cursor_index + direcao) % cartas_navegaveis.size()
	cartas_navegaveis[cursor_index].focar()

func atualizar_navegacao():
	if cursor_ativo and not cartas_navegaveis.is_empty():
		cartas_navegaveis[cursor_index].desfocar()
	cursor_ativo = false

	if fase_escolha == "propria":
		cartas_navegaveis = todas_cartas.filter(func(c): return c.lado == turno_atual)
	elif fase_escolha == "oponente":
		var lado_oponente = "vermelho" if turno_atual == "azul" else "azul"
		cartas_navegaveis = todas_cartas.filter(func(c): return c.lado == lado_oponente)
	else:
		cartas_navegaveis = []
		return

	cursor_index = 0

func iniciar_duelo():
	limpar_cartas()
	criar_cartas_duelo()
	await get_tree().create_timer(0.3).timeout
	await cuspir_cartas()
	await virar_cartas()
	await abaixar_cartas()
	await embaralhar_cartas()
	iniciar_escolha()

func limpar_cartas():
	for c in todas_cartas:
		c.queue_free()
	todas_cartas.clear()
	cartas_navegaveis.clear()

func criar_cartas_duelo():
	var ids = []
	for i in range(1, total_pares + 1):
		ids.append(i)

	var base_azul = baralho_azul.get_child(0)
	base_azul.visible = false

	for i in range(total_pares):
		var carta = base_azul.duplicate()
		carta.visible = true
		carta.lado = "azul"
		carta.global_position = baralho_azul.global_position
		add_child(carta)
		carta.card_id = ids[i]
		carta.carregar_sprite()
		todas_cartas.append(carta)
		carta.connect("carta_clicada", Callable(self, "ao_clicar_carta"))
		carta.atualizar_id_visual()

	var base_vermelho = baralho_vermelho.get_child(0)
	base_vermelho.visible = false

	for i in range(total_pares):
		var carta = base_vermelho.duplicate()
		carta.visible = true
		carta.lado = "vermelho"
		carta.global_position = baralho_vermelho.global_position
		add_child(carta)
		carta.card_id = ids[i]
		carta.carregar_sprite()
		todas_cartas.append(carta)
		carta.connect("carta_clicada", Callable(self, "ao_clicar_carta"))
		carta.atualizar_id_visual()

func cuspir_cartas():
	var espacamento = 150

	for i in range(total_pares):
		var carta_azul = todas_cartas[i]
		var carta_vermelha = todas_cartas[i + total_pares]

		var base_azul = baralho_azul.global_position
		var base_vermelho = baralho_vermelho.global_position
		var offset_x = (i - (total_pares / 2.0 - 0.5)) * espacamento

		var pos_final_azul = Vector2(base_azul.x + offset_x, base_azul.y + 200)
		var pos_final_vermelho = Vector2(base_vermelho.x + offset_x, base_vermelho.y - 200)

		var tween = create_tween()
		tween.tween_property(carta_azul, "global_position", pos_final_azul, 0.4)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(carta_vermelha, "global_position", pos_final_vermelho, 0.4)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

		await get_tree().create_timer(0.12).timeout

func ao_clicar_carta(carta):
	if fase_escolha == "propria":
		carta_propria = carta
		carta.virar()
		carta.bloquear()

		fase_escolha = "oponente"
		var lado_oponente = "vermelho" if turno_atual == "azul" else "azul"

		for c in todas_cartas:
			if c.lado == lado_oponente:
				c.desbloquear()
			else:
				c.bloquear()

		atualizar_navegacao()

	elif fase_escolha == "oponente":
		carta_oponente = carta
		carta.virar()
		carta.bloquear()

		cartas_navegaveis = []
		fase_escolha = ""

		for c in todas_cartas:
			c.bloquear()

		await get_tree().create_timer(0.5).timeout
		resolver_duelo()

func resolver_duelo():
	if carta_propria.card_id == carta_oponente.card_id:
		acertos += 1

		if turno_atual == "azul":
			pontos_azul += 1
			P_Azul.text = str(pontos_azul)
		else:
			pontos_vermelho += 1
			P_vermelho.text = str(pontos_vermelho)

		todas_cartas.erase(carta_propria)
		todas_cartas.erase(carta_oponente)

		var ponto_meio = (carta_propria.global_position + carta_oponente.global_position) / 2

		var t1 = create_tween()
		var t2 = create_tween()
		t1.tween_property(carta_propria, "global_position", ponto_meio, 0.3)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		t2.tween_property(carta_oponente, "global_position", ponto_meio, 0.3)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

		await get_tree().create_timer(0.35).timeout

		var saida = Vector2(-200, ponto_meio.y)
		var t3 = create_tween().set_parallel(true)
		t3.tween_property(carta_propria, "global_position", saida, 0.5)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		t3.tween_property(carta_propria, "scale", Vector2(0.0, 0.7), 0.5)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		t3.tween_property(carta_oponente, "global_position", saida, 0.5)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		t3.tween_property(carta_oponente, "scale", Vector2(0.0, 0.7), 0.5)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

		await get_tree().create_timer(0.55).timeout

		carta_propria.queue_free()
		carta_oponente.queue_free()

		if acertos >= total_pares:
			acertos = 0
			if turno_atual == "azul":
				Vencedor.text = "Azul venceu!"
				Vencedor.modulate = Color.CYAN
			else:
				Vencedor.text = "Vermelho venceu!"
				Vencedor.modulate = Color.RED
			Vencedor.visible = true
			await get_tree().create_timer(2.5).timeout
			Vencedor.visible = false
			pontos_azul = 0
			pontos_vermelho = 0
			P_Azul.text = "0"
			P_vermelho.text = "0"
			iniciar_duelo()
		else:
			await embaralhar_cartas()
			iniciar_escolha()
	else:
		acertos = 0
		await abaixar_cartas()
		await embaralhar_cartas()
		iniciar_escolha()

func virar_cartas():
	for carta in todas_cartas:
		carta.mostrar_frente()
	await get_tree().create_timer(2.5).timeout

func abaixar_cartas():
	for carta in todas_cartas:
		var tween = create_tween()
		tween.tween_property(carta, "scale", Vector2(0.7, 0.0), 0.2)\
			.set_trans(Tween.TRANS_SINE)
		await get_tree().create_timer(0.05).timeout

	await get_tree().create_timer(0.3).timeout

	for carta in todas_cartas:
		carta.mostrar_costas()
		var tween = create_tween()
		tween.tween_property(carta, "scale", Vector2(0.7, 0.7), 0.2)\
			.set_trans(Tween.TRANS_SINE)
		await get_tree().create_timer(0.05).timeout

	await get_tree().create_timer(0.3).timeout

func embaralhar_cartas():
	var cartas_azul = todas_cartas.filter(func(c): return c.lado == "azul")
	var cartas_vermelho = todas_cartas.filter(func(c): return c.lado == "vermelho")

	for _rodada in range(3):
		var posicoes_azul = cartas_azul.map(func(c): return c.global_position)
		var posicoes_vermelho = cartas_vermelho.map(func(c): return c.global_position)
		posicoes_azul.shuffle()
		posicoes_vermelho.shuffle()

		for i in range(cartas_azul.size()):
			var tween = create_tween()
			tween.tween_property(cartas_azul[i], "global_position", posicoes_azul[i], 0.45)\
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

		for i in range(cartas_vermelho.size()):
			var tween = create_tween()
			tween.tween_property(cartas_vermelho[i], "global_position", posicoes_vermelho[i], 0.45)\
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

		await get_tree().create_timer(0.55).timeout

func iniciar_escolha():
	turno_atual = "azul" if randi() % 2 == 0 else "vermelho"
	carta_propria = null
	carta_oponente = null
	fase_escolha = "propria"

	for carta in todas_cartas:
		if carta.lado == turno_atual:
			carta.desbloquear()
		else:
			carta.bloquear()

	atualizar_navegacao()
