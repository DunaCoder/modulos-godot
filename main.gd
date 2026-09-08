extends Node3D

# Arrastra tu escena (mapa1.tscn) a esta casilla en el Inspector de Godot
@export var mapa_actual: PackedScene

func _ready() -> void:
	cargar_mapa()

func cargar_mapa() -> void:
	if mapa_actual:
		var instancia_mapa = mapa_actual.instantiate()
		add_child(instancia_mapa)
		print("Mapa cargado exitosamente en Main.")
	else:
		push_warning("Atención: No has asignado ningún mapa en la variable 'mapa_actual' desde el Inspector.")
