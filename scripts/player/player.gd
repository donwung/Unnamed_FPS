extends CharacterBody3D


const JUMP_VELOCITY: float = 4.5
const SENSITIVITY: float = 0.001
const GRAVITY: float = 9.8

const BASE_SPEED: float = 7.0
var SPEED: float = 7.0

#Player stats
@export var health = 100
@export var armor = 50
@export var ammo = 2
@export var devilTrigger = 50

# Player states
# @export var IS_CROUCHING = false
# @export var IS_GROUNDED = true
# @export var IS_MOVING = false
#const STATE_TRANSITION_WINDOW = 1.0

# var PLAYER_STATE = {
# 	"is_crouching": false,
# 	"is_grounded": true,
# 	"is_moving": false,
# }
# var state = PLAYER_STATE

# TODO: clean this up
@onready var head = $Head
@onready var camera = $Head/Camera
@onready var playerHUDValues = $Head/Camera/PlayerHUD/HUD_Values
@onready var viewmodel_camera = $Head/Camera/ViewmodelCamera/ViewmodelCamera/ViewmodelCamera
@onready var wep_dbs = $Head/Camera/Weapons/DBS
@onready var wep_sg = $Head/Camera/Weapons/SemiSG
@onready var wep_revolver = $Head/Camera/Weapons/Revolver

@onready var weapons_belt = [wep_dbs, wep_sg, wep_revolver]
@onready var wpn_idx = 0
@onready var current_weapon = weapons_belt[wpn_idx]

@onready var movement = $Movement
@onready var stand_collider = $Stand_Collider
@onready var crouch_collider = $Crouch_Collider
@onready var can_stand_collider = $Can_Stand

@onready var standing_head_pos = $Standing_Head_Position
@onready var crouching_head_pos = $Crouching_Head_Position

@onready var input_queue = $Input_Queue
@onready var status_manager = $Status_Manager

@onready var state = status_manager.state

# On init
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	can_stand_collider.monitoring = true
	head.position.y = standing_head_pos.position.y
	input_queue.attach_status_manager(status_manager)
	status_manager.attach_player(self)

	select_weapon(0)

# Camera movement
func _unhandled_input(event) -> void:
	if event is InputEventMouseMotion:
		var y_rotation = -event.relative.x * SENSITIVITY
		var x_rotation = -event.relative.y * SENSITIVITY

		head.rotate_y(y_rotation)
		camera.rotate_x(x_rotation)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(89))


func _process(delta) -> void:
	viewmodel_camera.global_transform = camera.global_transform

	# TODO: prevent rerender of UI by only rendering on update
	playerHUDValues.health = health
	playerHUDValues.armor = armor
	playerHUDValues.ammo = ammo
	playerHUDValues.devilTrigger = devilTrigger


func action_attack(delta, state, active_weapon):
	active_weapon.attack()


# TODO: Refactor so that the actions don't get called every update
func _physics_process(delta) -> void:
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Add the gravity.
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		state.is_grounded = true

	# Handle jump.
	if Input.is_action_just_pressed("jump"):
		input_queue.add_command("jump", state)
		movement.jump(delta, state, self)


	# Handle movement
	if direction:
		movement.move(delta, state, direction, self)
	else:
		movement.stop(delta, state, direction, self)

	# Handle crouching
	if Input.is_action_pressed("crouch"):
		movement.crouch(delta, state, self)
		head.position.y = crouching_head_pos.position.y
	else:
		# if this set of functions gets out of hand, remove nested if
		if can_stand_collider.can_stand():
			movement.stand(delta, state, self)
			head.position.y = standing_head_pos.position.y
		else:
			print("cannot stand")
		# if Input.is_action_just_released("crouch"):
		# 	print("just released crouch")
	
	# Handle command inputs
	# TODO: optimize + giga refactor this
	if Input.is_action_just_pressed("forward"):
		input_queue.add_command("forward", state)
	if Input.is_action_just_pressed("backward"):
		input_queue.add_command("backward", state)
	if Input.is_action_just_pressed("crouch"):
		input_queue.add_command("crouch", state)
	if (Input.is_action_just_released("forward") && !input_dir) || (Input.is_action_just_released("backward") && !input_dir):
		input_queue.add_command("neutral", state)


	# input_queue.receive_state(state)

	# Handle attacking
	if Input.is_action_just_pressed("mb1"):
		action_attack(delta, state, current_weapon)

	if Input.is_action_just_pressed("next_weapon"):
		wpn_idx+= 1
		if wpn_idx > weapons_belt.size()-1:
			wpn_idx = 0
		select_weapon(wpn_idx)
	if Input.is_action_just_pressed("prev_weapon"):
		wpn_idx-= 1
		if wpn_idx < 0:
			wpn_idx = weapons_belt.size()-1
		select_weapon(wpn_idx)

	# Camera effects
	camera.roll_and_bob(input_dir, delta, self)
	viewmodel_camera.bob(current_weapon, delta, self)

	# Move player and calculate collision
	move_and_slide()

func select_weapon(idx):
	for wep in weapons_belt:
		wep.visible = false
	weapons_belt[idx].visible = true
	current_weapon = weapons_belt[idx]

func receive_damage(damage, damage_type):
	health -= damage
	if health < 0:
		get_tree().reload_current_scene()
	
func get_hp():
	return health
