extends CharacterBody3D

const SPEED = 3.0
const JUMP_VELOCITY = 4.5

@onready var camera_pivot: Node3D = $camera_pivot
@onready var camera_3d: Camera3D = $camera_pivot/Camera3D
@onready var visuals: Node3D = $visuals
@onready var animation_player: AnimationPlayer = $visuals/player/AnimationPlayer if has_node("visuals/player/AnimationPlayer") else null

func _ready() -> void:
	# Asegura que esta cámara tome el control automáticamente en cualquier mapa donde instancies al player
	if camera_3d:
		camera_3d.make_current()

	if animation_player:
		if animation_player.has_animation("idl") and animation_player.has_animation("walk"):
			animation_player.set_blend_time("idl", "walk", 0.2)
			animation_player.set_blend_time("walk", "idl", 0.2)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(-input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		
		# Solo gira la parte gráfica (visuals), no todo el nodo raíz ni la cámara
		visuals.look_at(global_position + direction)
		
		if animation_player and animation_player.has_animation("walk"):
			if animation_player.current_animation != "walk":
				animation_player.play("walk")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		
		if animation_player:
			var idle_anim = "idl" if animation_player.has_animation("idl") else "idle"
			if animation_player.has_animation(idle_anim) and animation_player.current_animation != idle_anim:
				animation_player.play(idle_anim)

	move_and_slide()
