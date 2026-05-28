extends Node

# Singleton (autoload) com a dificuldade escolhida.
# A tela de seleção seta 'pares' e 'colunas' antes de mudar de cena
# e cena.gd lê esses valores para montar o grid de cartas.

var pares: int = 15
var colunas: int = 6
