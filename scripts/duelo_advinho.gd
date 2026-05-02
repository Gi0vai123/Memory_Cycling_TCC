extends Node2D

@onready var baralho_azul = $BaralhoA
@onready var baralho_vermelho = $BaralhoV
@onready var P_vermelho = $"CanvasLayer/Pontos Vermelhos"
@onready var P_Azul = $"CanvasLayer/Pontos Azul"

var pontos_azul: int = 0
var pontos_vermelho: int = 0

var todas_cartas = []
var acertos: int = 0
var turno_atual: String = ""
var carta_propria: Area2D = null
var carta_oponente: Area2D = null
var fase_escolha: String = ""

func _ready():
	iniciar_duelo()

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

func criar_cartas_duelo():
	var ids = [1, 2, 3]

	var base_azul = baralho_azul.get_child(0)
	base_azul.visible = false

	for i in range(3):
		var carta = base_azul.duplicate()
		carta.visible = true
		carta.card_id = ids[i]
		carta.lado = "azul"
		carta.global_position = baralho_azul.global_position

		add_child(carta)
		todas_cartas.append(carta)

		carta.connect("carta_clicada", Callable(self, "ao_clicar_carta"))
		carta.atualizar_id_visual()

	var base_vermelho = baralho_vermelho.get_child(0)
	base_vermelho.visible = false

	for i in range(3):
		var carta = base_vermelho.duplicate()
		carta.visible = true
		carta.card_id = ids[i]
		carta.lado = "vermelho"
		carta.global_position = baralho_vermelho.global_position

		add_child(carta)
		todas_cartas.append(carta)

		carta.connect("carta_clicada", Callable(self, "ao_clicar_carta"))
		carta.atualizar_id_visual()

func cuspir_cartas():
	var espacamento = 150

	for i in range(3):
		var carta_azul = todas_cartas[i]
		var carta_vermelha = todas_cartas[i + 3]

		var base_azul = baralho_azul.global_position
		var base_vermelho = baralho_vermelho.global_position

		var offset_x = (i - 1) * espacamento

		var pos_final_azul = Vector2(base_azul.x + offset_x, base_azul.y + 200)
		var pos_final_vermelho = Vector2(base_vermelho.x + offset_x, base_vermelho.y - 200)

		var tween = create_tween()

		tween.tween_property(carta_azul, "global_position", pos_final_azul, 0.4)\
			.set_trans(Tween.TRANS_BACK)\
			.set_ease(Tween.EASE_OUT)

		tween.tween_property(carta_vermelha, "global_position", pos_final_vermelho, 0.4)\
			.set_trans(Tween.TRANS_BACK)\
			.set_ease(Tween.EASE_OUT)

		await get_tree().create_timer(0.12).timeout

func ao_clicar_carta(carta):
	if fase_escolha == "propria":
		carta_propria = carta
		carta.mostrar_frente()
		carta.bloquear()

		print("Carta própria escolhida: ", carta.card_id, " (", carta.lado, ")")

		fase_escolha = "oponente"
		var lado_oponente = "vermelho" if turno_atual == "azul" else "azul"

		for c in todas_cartas:
			if c.lado == lado_oponente:
				c.desbloquear()
			else:
				c.bloquear()

	elif fase_escolha == "oponente":
		carta_oponente = carta
		carta.mostrar_frente()
		carta.bloquear()

		print("Carta oponente escolhida: ", carta_oponente.card_id, " (", carta_oponente.lado, ")")

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

		print("ACERTOU! ", acertos, "/3")

		todas_cartas.erase(carta_propria)
		todas_cartas.erase(carta_oponente)

		var ponto_meio = (carta_propria.global_position + carta_oponente.global_position) / 2

		var t1 = create_tween()
		var t2 = create_tween()

		t1.tween_property(carta_propria, "global_position", ponto_meio, 0.3)\
			.set_trans(Tween.TRANS_CUBIC)\
			.set_ease(Tween.EASE_IN_OUT)

		t2.tween_property(carta_oponente, "global_position", ponto_meio, 0.3)\
			.set_trans(Tween.TRANS_CUBIC)\
			.set_ease(Tween.EASE_IN_OUT)

		await get_tree().create_timer(0.35).timeout

		var saida = Vector2(-200, ponto_meio.y)

		var t3 = create_tween().set_parallel(true)

		t3.tween_property(carta_propria, "global_position", saida, 0.5)\
			.set_trans(Tween.TRANS_CUBIC)\
			.set_ease(Tween.EASE_IN)

		t3.tween_property(carta_propria, "scale", Vector2(0.0, 0.7), 0.5)\
			.set_trans(Tween.TRANS_CUBIC)\
			.set_ease(Tween.EASE_IN)

		t3.tween_property(carta_oponente, "global_position", saida, 0.5)\
			.set_trans(Tween.TRANS_CUBIC)\
			.set_ease(Tween.EASE_IN)

		t3.tween_property(carta_oponente, "scale", Vector2(0.0, 0.7), 0.5)\
			.set_trans(Tween.TRANS_CUBIC)\
			.set_ease(Tween.EASE_IN)

		await get_tree().create_timer(0.55).timeout

		carta_propria.queue_free()
		carta_oponente.queue_free()

		if acertos >= 3:
			print("VENCEU! Lado ", turno_atual, " acertou todos os pares!")
			get_tree().reload_current_scene()
		else:
			await embaralhar_cartas()
			iniciar_escolha()
	else:
		print("ERROU!")
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
				.set_trans(Tween.TRANS_CUBIC)\
				.set_ease(Tween.EASE_IN_OUT)

		for i in range(cartas_vermelho.size()):
			var tween = create_tween()
			tween.tween_property(cartas_vermelho[i], "global_position", posicoes_vermelho[i], 0.45)\
				.set_trans(Tween.TRANS_CUBIC)\
				.set_ease(Tween.EASE_IN_OUT)

		await get_tree().create_timer(0.55).timeout

func iniciar_escolha():
	turno_atual = "azul" if randi() % 2 == 0 else "vermelho"
	print("Vez do lado: ", turno_atual)

	carta_propria = null
	carta_oponente = null
	fase_escolha = "propria"

	for carta in todas_cartas:
		if carta.lado == turno_atual:
			carta.desbloquear()
		else:
			carta.bloquear()
