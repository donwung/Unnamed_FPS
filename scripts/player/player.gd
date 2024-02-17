extends CharacterBody3D

# const SPEED: float = 7.0
const JUMP_VELOCITY: float = 4.5
const SENSITIVITY: float = 0.001

#Player stats
@export var health = 100
@export var armor = 50
@export var ammo = 2
@export var devilTrigger = 50

# Player states
@export var IS_CROUCHING = false
@export var IS_GROUNDED = true
@export var IS_MOVING = false
#const STATE_TRANSITION_WINDOW = 1.0

var PLAYER_STATE = {
	"is_crouching": IS_CROUCHING, "is_grounded": IS_GROUNDED, "is_moving": IS_MOVING
}

# TODO: clean this up
@onready var head = $Head
@onready var camera = $Head/Camera
@onready var playerHUDValues = $Head/Camera/PlayerHUD/HUD_Values
@onready var viewmodel_camera = $Head/Camera/ViewmodelCamera/ViewmodelCamera/ViewmodelCamera
@onready var wep_dbs = $Head/Camera/Model_DBS

@onready var weapons_belt = [wep_dbs, wep_dbs]
@onready var current_weapon = weapons_belt[0]

@onready var movement = $Movement
@onready var stand_collider = $Stand_Collider
@onready var crouch_collider = $Crouch_Collider
@onready var can_stand_collider = $Can_Stand

# Get the gravity from the project settings to be synced with RigidBody nodes.
# TODO: maybe separate player from npc gravity?
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# On init
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	can_stand_collider.monitoring = true


# Camera movement
func _unhandled_input(event) -> void:
	if event is InputEventMouseMotion:
		var y_rotation = -event.relative.x * SENSITIVITY
		var x_rotation = -event.relative.y * SENSITIVITY

		head.rotate_y(y_rotation)
		camera.rotate_x(x_rotation)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))

# will eventually need to optimize and move input handling here instead of in the update funcs
# TODO: potentially need to split inputs into keypress and keyrelease for optimization
func _input(event):
	pass


func _process(delta) -> void:
	viewmodel_camera.global_transform = camera.global_transform

	# TODO: prevent rerender of UI by only rendering on update
	playerHUDValues.health = health
	playerHUDValues.armor = armor
	playerHUDValues.ammo = ammo
	playerHUDValues.devilTrigger = devilTrigger


func action_attack(delta, state, active_weapon):
	active_weapon.attack()


func _physics_process(delta) -> void:
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var state = PLAYER_STATE

	# TODO: Refactor so that the actions don't get called every update
	# Handle jump.
	if Input.is_action_just_pressed("jump"):
		movement.jump(delta, state, self)

	# Handle movement
	movement.move(delta, state, direction, self)

	# Handle crouching
	if Input.is_action_pressed("crouch"):
		movement.crouch(delta, state, self, true)
	else:
		movement.crouch(delta, state, self, false)

	# Handle attacking
	if Input.is_action_just_pressed("mb1"):
		action_attack(delta, state, current_weapon)

	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	camera.roll(input_dir, delta, self)
	camera.bob(input_dir, delta, self)
	viewmodel_camera.bob(current_weapon, delta, self)

	# Move player and calculate collision
	move_and_slide()