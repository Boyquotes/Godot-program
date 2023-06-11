extends KinematicBody2D
class_name Player

enum {MOVE, CLIMB}

export(Resource) var moveData

var velocity = Vector2.ZERO
var state = MOVE
var double_jump = 1
var buffered_jump = false

onready var animatedSprite: = $AnimatedSprite
onready var ladderCheck: = $LadderCheck
onready var jumpBufferTimer: = $JumpBufferTimer

func _ready():
	animatedSprite.frames = load("res://Skins/PlayerBlueSkin.tres")
	moveData = moveData as PlayerMovementData

func _physics_process(delta):
	var input = Vector2.ZERO
	input.x = Input.get_axis("ui_left", "ui_right")
	input.y = Input.get_axis("ui_up", "ui_down")
	
	match state:
		MOVE: move_state(input)
		CLIMB: climb_state(input)

func move_state(input):
	if is_on_ladder() and Input.is_action_pressed("ui_up"):
		state = CLIMB
	apply_gravity()
	if input.x == 0:
		apply_friction()
		animatedSprite.animation = "Idle"
	else:
		apply_acceleration(input.x)
		animatedSprite.animation = "Run"
		if input.x > 0:
			animatedSprite.flip_h = true
		elif input.x < 0:
			animatedSprite.flip_h = false
		
	if is_on_floor():
		double_jump = moveData.DOUBLE_JUMP_COUNT
		if Input.is_action_just_pressed("ui_up") or buffered_jump:
			velocity.y = moveData.JUMP_FORCE
			buffered_jump = false
	else:
		animatedSprite.animation = "Jump"
		if Input.is_action_just_released("ui_up") and velocity.y < moveData.JUMP_RELEASE_FORCE:
			velocity.y = moveData.JUMP_RELEASE_FORCE
			
		if Input.is_action_just_pressed("ui_up") and double_jump > 0:
			velocity.y = moveData.JUMP_FORCE
			double_jump -= 1
			
		if Input.is_action_just_pressed("ui_up"):
			buffered_jump = true
			jumpBufferTimer.start()
			
		if velocity.y > 0:
			velocity.y += moveData.ADDITIONAL_FALL_GRAVITY
	
	velocity = move_and_slide(velocity, Vector2.UP)
	
func climb_state(input):
	if not is_on_ladder(): state = MOVE
	if input.length() != 0:
		animatedSprite.animation = "Run"
	else:
		animatedSprite.animation = "Idle"
	velocity = input * moveData.CLIMB_SPEED
	velocity = move_and_slide(velocity, Vector2.UP)

func is_on_ladder():
	if not ladderCheck.is_colliding(): return false
	var collider = ladderCheck.get_collider()
	if not collider is Ladder: return false
	return true

func apply_gravity():
	velocity.y += moveData.GRAVITY
	velocity.y = min(velocity.y, 300)

func apply_friction():
	velocity.x = move_toward(velocity.x, 0, moveData.FRICION)
	
func apply_acceleration(amount):
	velocity.x = move_toward(velocity.x, moveData.MAX_SPEED * amount, moveData.ACCELERATION)

func _on_JumpBufferTimer_timeout():
	buffered_jump = false
