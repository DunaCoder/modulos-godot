extends Node3D

@export var municion_actual: int = 7

func recibir_disparo() -> void:
	municion_actual -= 1000
	print("Anymore bullets? -> 🔫 [Pistola]: ¡Disparo recibido! Balas restantes: ", municion_actual)
