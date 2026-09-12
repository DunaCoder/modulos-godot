extends Camera3D

@export var shake_time : float = 0.0
@export var shake_force : float = 0.0

func _process(delta: float) -> void:
	_shake(delta)

func _shake(delta: float) -> void:
	if shake_time > 0:
		# randf_range es el sustituto oficial de rand_range en Godot 4
		h_offset = randf_range(-shake_force, shake_force)
		v_offset = randf_range(-shake_force, shake_force)
		shake_time -= delta
	else:
		# Si el tiempo terminó, devolvemos la cámara a su centro impecable
		h_offset = 0.0
		v_offset = 0.0

# Función pública para activar el temblor
func start_shake(force: float, duration: float) -> void:
	shake_force = force  # <-- Corregido para que guarde la fuerza del impacto
	shake_time = duration
