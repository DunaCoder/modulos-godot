extends CharacterBody3D

@export var velocidad: float = 3.0
@export var limite_movimientos: int = 15 
var movimientos_realizados: int = 0

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

var activo: bool = false
var tiempo_en_ruta: float = 0.0
var max_tiempo_por_punto: float = 100.0 

func _ready() -> void:
	nav_agent.path_desired_distance = 1.0
	nav_agent.target_desired_distance = 1.0

func _unhandled_input(event: InputEvent) -> void:
	# Inicia con ESPACIO solo si no está activo actualmente
	if event.is_action_pressed("ui_accept") and not activo:
		activo = true
		movimientos_realizados = 0
		print("¡Exploración autónoma iniciada!")
		ir_a_punto_aleatorio()

func _physics_process(delta: float) -> void:
	if not activo:
		return
		
	# CONTROL DE SEGURIDAD (Time Out)
	tiempo_en_ruta += delta
	
	if nav_agent.is_navigation_finished() or tiempo_en_ruta >= max_tiempo_por_punto:
		movimientos_realizados += 1
		print("Movimiento realizado: ", movimientos_realizados, "/", limite_movimientos)

		if movimientos_realizados >= limite_movimientos:
			activo = false
			velocity = Vector3.ZERO
			print("¡Límite de movimientos alcanzado! El bot se detiene.")
			return 

		if tiempo_en_ruta >= max_tiempo_por_punto:
			print("Punto tardó mucho o inaccesible. Cambiando de ruta...")
		else:
			print("¡Llegué con éxito! Buscando nuevo destino...")
			
		ir_a_punto_aleatorio()
		return
		
	# Movimiento del NavigationAgent3D
	var siguiente_posicion = nav_agent.get_next_path_position()
	var direccion = global_position.direction_to(siguiente_posicion)
	
	velocity.x = direccion.x * velocidad
	velocity.z = direccion.z * velocidad
	
	# Rotación opcional para que la cápsula mire a donde camina
	if direccion.length() > 0.1:
		look_at(Vector3(siguiente_posicion.x, global_position.y, siguiente_posicion.z))
	
	move_and_slide()

func ir_a_punto_aleatorio() -> void:
	tiempo_en_ruta = 0.0
	
	# 1. Método por rango aleatorio (tu método original):
	var x_al_azar = randf_range(-20.0, 20.0)
	var z_al_azar = randf_range(-20.0, 20.0)
	var destino_aleatorio = Vector3(x_al_azar, 1.0, z_al_azar)
	
	# 2. Alternativa usando la malla de navegación oficial de Godot:
	var nav_map = get_world_3d().navigation_map
	var punto_navmesh = NavigationServer3D.map_get_random_point(nav_map, 1, true)
	
	# Usamos el del NavMesh si es válido, si no, el de tu rango
	if punto_navmesh != Vector3.ZERO:
		nav_agent.target_position = punto_navmesh
	else:
		nav_agent.target_position = destino_aleatorio
