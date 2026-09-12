extends CharacterBody3D

# --- REFERENCIAS A NODOS FIJAS Y ESTRICTAS ---
@onready var neck = $Neck
@onready var camera = $Neck/Camera3D
@onready var raycast = $Neck/Camera3D/HitscanRay
@onready var arma_equipada = $Neck/Camera3D/Pistola

# --- VARIABLES DE MOVIMIENTO ---
const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# --- VARIABLES DE CÁMARA ---
@export var sensibility : float = 0.2  # Sensibilidad del mouse
@export var captured : bool = true     # Controla si el mouse está atrapado

func _ready() -> void:
	# Forzamos el alcance a 200 metros aquí para ganarle al bug del Inspector
	if raycast:
		raycast.target_position = Vector3(0, 0, -200.0)
		
	_update_mouse_mode()

func _physics_process(delta: float) -> void:
	# Gravedad
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Salto
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Liberar/Atrapar Mouse con Escape
	if Input.is_action_just_pressed("ui_cancel"):
		captured = !captured
		_update_mouse_mode()

	# Movimiento WASD
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func _input(event: InputEvent) -> void:
	# Rotación de la cámara y el cuello
	_camera_rotation(event)
	
	# Disparo con Clic Izquierdo nativo
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and captured:
		procesar_disparo_hitscan()

func procesar_disparo_hitscan() -> void:
	# 1. Feedback de la cámara (Shake)
	if camera and camera.has_method("start_shake"):
		camera.start_shake(0.1, 0.15)
	
	# 2. Descontar bala en la pistola
	if arma_equipada and arma_equipada.has_method("recibir_disparo"):
		arma_equipada.recibir_disparo()
	
	# 3. Cálculo matemático del tiro
	if raycast:
		raycast.force_raycast_update()
		
		if raycast.is_colliding():
			var coordenada_choque = raycast.get_collision_point()
			var normal_pared = raycast.get_collision_normal()
			
			# Creamos el punto rojo efímero por código puro
			var punto_temporal = MeshInstance3D.new()
			var esfera = SphereMesh.new()
			esfera.radius = 0.04
			esfera.height = 0.08
			punto_temporal.mesh = esfera
			
			var material = StandardMaterial3D.new()
			material.albedo_color = Color(1, 0, 0)
			material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
			punto_temporal.material_override = material
			
			get_tree().current_scene.add_child(punto_temporal)
			
			# --- AJUSTE ANTE EL SUELO HORIZONTAL ---
			# Si la normal apunta hacia arriba, subimos el punto para que flote sobre el piso
			if normal_pared.y > 0.5:
				punto_temporal.global_position = coordenada_choque + Vector3(0, 0.05, 0)
			else:
				# Si es una pared vertical, lo empujamos hacia afuera de la superficie de forma normal
				punto_temporal.global_position = coordenada_choque + (normal_pared * 0.02)
			
			# Se limpia solo en 2 segundos
			get_tree().create_timer(2.0).timeout.connect(func(): punto_temporal.queue_free())
			
			var objeto_golpeado = raycast.get_collider()
			print("🎯 [Hitscan] Impacto en: ", objeto_golpeado.name)
			
			# === NUEVA LÓGICA DE OBJETIVOS INTERACTIVOS ===
			# Comprobamos si el objeto (o su script) tiene el método para recibir daño
			if objeto_golpeado.has_method("recibir_dano"):
				# Le pasamos cuántos puntos de daño hace el disparo (ej: 25)
				objeto_golpeado.recibir_dano(25)

func _camera_rotation(event: InputEvent) -> void:
	if captured and event is InputEventMouseMotion:
		# Girar el CUERPO a los lados (Eje Y)
		rotate_y(-deg_to_rad(event.relative.x * sensibility))
		
		# Inclinar la CÁMARA arriba y abajo (Eje X)
		if camera:
			camera.rotate_x(-deg_to_rad(event.relative.y * sensibility))
			var max_angle : float = 85.0
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-max_angle), deg_to_rad(max_angle))

func _update_mouse_mode() -> void:
	if captured:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func trigger_camera_shake(force: float, time: float) -> void:
	if camera and camera.has_method("start_shake"):
		camera.shake_force = force
		camera.shake_time = time
