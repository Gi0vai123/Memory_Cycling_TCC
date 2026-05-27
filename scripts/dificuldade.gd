extends Node

# Singleton (autoload) com a dificuldade escolhida.
# A tela de seleção seta 'pares' antes de mudar de cena
# e cena.gd lê esse valor para montar as cartas.

var pares: int = 15
