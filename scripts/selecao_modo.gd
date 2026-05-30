extends Control

# ─────────────────────────────────────────────
#  Tela de selecao de modo de jogo (editor-built).
#  Todos os nos (cards, botoes, labels) estao definidos
#  diretamente em selecao_modo.tscn — esse script soh
#  trata os cliques e o destaque dos toggles 4/6/8.
# ─────────────────────────────────────────────

const CENA_PADRAO: String     = "res://scenes/modoP.tscn"
const CENA_CAMPEONATO: String = "res://scenes/cadastro_campeonato.tscn"
const CENA_ADIVINHA: String   = "res://scenes/duelo-advinho.tscn"
const CENA_PROGRESSO: String  = "res://scenes/Progresso.tscn"
const CENA_MENU: String       = "res://scenes/menu_screen.tscn"

const COR_TOGGLE_ATIVO: Color   = Color(1.0, 0.9, 0.3)
const COR_TOGGLE_INATIVO: Color = Color(0.55, 0.55, 0.7)

# Toggles de quantidade de jogadores no card do Campeonato
@onready var btn_4: Button = $CardCampeonato/Btn4
@onready var btn_6: Button = $CardCampeonato/Btn6
@onready var btn_8: Button = $CardCampeonato/Btn8

# Quantidade de jogadores selecionada (default 8)
var num_jogadores_selecionado: int = 8


func _ready() -> void:
	_atualizar_toggles()
	$BtnVoltar.grab_focus()

# ─────────────────────────────────────────────
#  Toggles de quantidade de jogadores (Campeonato)
# ─────────────────────────────────────────────
func _atualizar_toggles() -> void:
	btn_4.modulate = COR_TOGGLE_ATIVO if num_jogadores_selecionado == 4 else COR_TOGGLE_INATIVO
	btn_6.modulate = COR_TOGGLE_ATIVO if num_jogadores_selecionado == 6 else COR_TOGGLE_INATIVO
	btn_8.modulate = COR_TOGGLE_ATIVO if num_jogadores_selecionado == 8 else COR_TOGGLE_INATIVO


func _on_btn_4_pressed() -> void:
	num_jogadores_selecionado = 4
	_atualizar_toggles()


func _on_btn_6_pressed() -> void:
	num_jogadores_selecionado = 6
	_atualizar_toggles()


func _on_btn_8_pressed() -> void:
	num_jogadores_selecionado = 8
	_atualizar_toggles()


# ─────────────────────────────────────────────
#  Pares por dificuldade
# ─────────────────────────────────────────────
const PARES_FACIL: int   = 11
const PARES_NORMAL: int  = 15
const PARES_DIFICIL: int = 21


# ─────────────────────────────────────────────
#  Modo Padrao — 3 botoes de dificuldade
# ─────────────────────────────────────────────
func _on_padrao_facil_pressed() -> void:
	Dificuldade.pares = PARES_FACIL
	get_tree().change_scene_to_file(CENA_PADRAO)


func _on_padrao_normal_pressed() -> void:
	Dificuldade.pares = PARES_NORMAL
	get_tree().change_scene_to_file(CENA_PADRAO)


func _on_padrao_dificil_pressed() -> void:
	Dificuldade.pares = PARES_DIFICIL
	get_tree().change_scene_to_file(CENA_PADRAO)


# ─────────────────────────────────────────────
#  Modo Campeonato — aplica num_jogadores e navega
# ─────────────────────────────────────────────
func _on_camp_facil_pressed() -> void:
	Campeonato.num_jogadores = num_jogadores_selecionado
	Dificuldade.pares = PARES_FACIL
	get_tree().change_scene_to_file(CENA_CAMPEONATO)


func _on_camp_normal_pressed() -> void:
	Campeonato.num_jogadores = num_jogadores_selecionado
	Dificuldade.pares = PARES_NORMAL
	get_tree().change_scene_to_file(CENA_CAMPEONATO)


func _on_camp_dificil_pressed() -> void:
	Campeonato.num_jogadores = num_jogadores_selecionado
	Dificuldade.pares = PARES_DIFICIL
	get_tree().change_scene_to_file(CENA_CAMPEONATO)


# ─────────────────────────────────────────────
#  Modo Adivinhacao
# ─────────────────────────────────────────────
func _on_adv_facil_pressed() -> void:
	Dificuldade.pares = PARES_FACIL
	get_tree().change_scene_to_file(CENA_ADIVINHA)


func _on_adv_normal_pressed() -> void:
	Dificuldade.pares = PARES_NORMAL
	get_tree().change_scene_to_file(CENA_ADIVINHA)


func _on_adv_dificil_pressed() -> void:
	Dificuldade.pares = PARES_DIFICIL
	get_tree().change_scene_to_file(CENA_ADIVINHA)


# ─────────────────────────────────────────────
#  Modo Progresso — fases que crescem em pares
# ─────────────────────────────────────────────
func _on_prog_facil_pressed() -> void:
	Dificuldade.pares = PARES_FACIL
	get_tree().change_scene_to_file(CENA_PROGRESSO)


func _on_prog_normal_pressed() -> void:
	Dificuldade.pares = PARES_NORMAL
	get_tree().change_scene_to_file(CENA_PROGRESSO)


func _on_prog_dificil_pressed() -> void:
	Dificuldade.pares = PARES_DIFICIL
	get_tree().change_scene_to_file(CENA_PROGRESSO)


# ─────────────────────────────────────────────
#  Voltar ao menu principal
# ─────────────────────────────────────────────
func _on_voltar_pressed() -> void:
	get_tree().change_scene_to_file(CENA_MENU)
