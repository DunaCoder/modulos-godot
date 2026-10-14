extends CharacterBody3D

@export var velocidad: float = 3.0
@export var limite_movimientos: int = 15
@export var rango_aleatorio: float = 15.0
var movimientos_realizados: int = 0

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

var activo: bool = false
var tiempo_en_ruta: float = 0.0
var max_tiempo_por_punto: float = 8.0

func _ready() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	nav_agent.path_desired_distance = 0.3
	nav_agent.target_desired_distance = 0.5
	nav_agent.radius = 0.5

	# DEBUG: comprobar que el enemigo está sobre el navmesh
	var map := nav_agent.get_navigation_map()
	var closest := NavigationServer3D.map_get_closest_point(map, global_position)
	print("[DEBUG] Distancia al navmesh: ", global_position.distance_to(closest))
	print("[DEBUG] Mi posición: ", global_position, " | Punto más cercano en navmesh: ", closest)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and not activo:
		activo = true
		movimientos_realizados = 0
		print("¡Exploración iniciada!")
		ir_a_punto_aleatorio()

func _physics_process(delta: float) -> void:
	if not activo:
		return

	tiempo_en_ruta += delta

	if nav_agent.is_navigation_finished() or tiempo_en_ruta >= max_tiempo_por_punto:
		movimientos_realizados += 1
		print("Movimiento ", movimientos_realizados, "/", limite_movimientos)

		if movimientos_realizados >= limite_movimientos:
			activo = false
			velocity = Vector3.ZERO
			print("Fin.")
			return

		ir_a_punto_aleatorio()
		return

	# Comprobar que hay ruta
	if not nav_agent.is_target_reachable():
		print("[DEBUG] Target inalcanzable, elijo otro.")
		ir_a_punto_aleatorio()
		return

	var siguiente_posicion := nav_agent.get_next_path_position()
	var direccion := siguiente_posicion - global_position
	direccion.y = 0.0

	if direccion.length() < 0.05:
		# Sin dirección útil -> no toco rotación ni velocidad
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	direccion = direccion.normalized()
	velocity.x = direccion.x * velocidad
	velocity.z = direccion.z * velocidad
	velocity.y = 0.0

	# Rotación Y pura (yaw), sin look_at que se lía
	var yaw_objetivo := atan2(-direccion.x, -direccion.z)
	rotation.y = lerp_angle(rotation.y, yaw_objetivo, 8.0 * delta)

	move_and_slide()

func ir_a_punto_aleatorio() -> void:
	tiempo_en_ruta = 0.0
	var map := nav_agent.get_navigation_map()

	# Elegir punto aleatorio alrededor de la posición actual del enemigo
	var punto_crudo := global_position + Vector3(
		randf_range(-rango_aleatorio, rango_aleatorio),
		0.0,
		randf_range(-rango_aleatorio, rango_aleatorio)
	)

	# Proyectar sobre el navmesh (esto es CLAVE)
	var punto_valido := NavigationServer3D.map_get_closest_point(map, punto_crudo)

	nav_agent.target_position = punto_valido
	print("[DEBUG] Nuevo target: ", punto_valido, " | Distancia al navmesh del target: ",
		  punto_crudo.distance_to(punto_valido))
