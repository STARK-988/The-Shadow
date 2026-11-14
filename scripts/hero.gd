
extends CharacterBody2D
 
@export var shadow: Area2D  
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
 
var facing := 1
var attack_timer := 0.0
var attack_len := 0.35 
var teleport_timer := 0.0
var history: Array = []
var time := 0.0
 
 
func _ready() -> void:
	add_to_group("player")  
	_find_shadow()
	_sync_shadow_sprite()
	print("SHADOW NODE = ", shadow)   
 
	# ربط الأزرار
	var keys := {"move_left": KEY_A, "move_right": KEY_D, "jump": KEY_SPACE,
		"attack": KEY_M, "teleport": KEY_C, "restart": KEY_R}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		InputMap.action_erase_events(action)
		var ev := InputEventKey.new()
		ev.physical_keycode = keys[action]
		InputMap.action_add_event(action, ev)
 
 
func _find_shadow() -> void:
	if shadow != null:
		return
	shadow = get_tree().get_first_node_in_group("shadow") as Area2D
	if shadow == null:
		for n in get_parent().get_children():
			if n.has_method("apply_state"):
				shadow = n
				return
 
 
func _sync_shadow_sprite() -> void:
	if shadow == null:
		return
	var ss := shadow.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if ss == null:
		return
	var extra = shadow.get("extra_y")
	if extra == null:
		extra = 0.0
	ss.position = sprite.position + Vector2(0.0, extra)
	ss.offset = sprite.offset
	ss.scale = sprite.scale
	ss.centered = sprite.centered
 
 
func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
		return
 
	var dir := Input.get_axis("move_left", "move_right")
	if not is_on_floor():
		velocity.y += 1000.0 * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = -420.0
	velocity.x = dir * 200.0
	if teleport_timer > 0.0 or (attack_timer > 0.0 and is_on_floor()):
		velocity.x = 0.0
	if dir != 0.0 and attack_timer <= 0.0:
		facing = 1 if dir > 0.0 else -1
		sprite.flip_h = facing < 0   
	move_and_slide()
 
	teleport_timer = max(teleport_timer - delta, 0.0)
	if Input.is_action_just_pressed("attack") and attack_timer <= 0.0 and teleport_timer <= 0.0:
		var frames := sprite.sprite_frames
		attack_len = frames.get_frame_count("attack") / max(frames.get_animation_speed("attack"), 1.0)
		attack_timer = attack_len
		sprite.stop()
		sprite.play("attack")
	if attack_timer > 0.0:
		attack_timer -= delta
		var progress := 1.0 - attack_timer / attack_len
		if progress >= 0.25 and progress <= 0.85:   
			_swing()
 
	if teleport_timer <= 0.0 and attack_timer <= 0.0:
		var anim := "idle"
		if not is_on_floor():
			anim = "jump"
		elif dir != 0.0:
			anim = "move"
		if sprite.animation != anim or not sprite.is_playing():
			sprite.play(anim)
 
	var had_shadow := shadow != null
	_find_shadow()
	if shadow == null:
		return
	if not had_shadow:
		_sync_shadow_sprite()
	time += delta
	history.append({"t": time, "pos": global_position, "anim": sprite.animation, "flip": sprite.flip_h})
	if time < 5.0:
		shadow.set_active(false)
	else:
		while history.size() > 1 and history[1].t <= time - 5.0:
			history.pop_front()
		if time - delta < 5.0:
			print("SHADOW ON at ", history[0].pos)
		shadow.set_active(true)
		shadow.apply_state(history[0])
 
	if Input.is_action_just_pressed("teleport") and shadow.visible:
		var target := shadow.global_position
		var found := false
		for lift in [0.0, 4.0, 8.0, 12.0, 16.0, 24.0, 32.0]:
			var t: Vector2 = shadow.global_position + Vector2(0.0, -lift)
			if not test_move(Transform2D(0.0, t), Vector2.ZERO):
				target = t
				found = true
				break
		if not found:
			return  
		global_position = target
		velocity = Vector2.ZERO
		attack_timer = 0.0
		history.clear()
		time = 0.0
		shadow.set_active(false)
		teleport_timer = 0.25
		sprite.play("teleport")
 
 
func _swing() -> void:
	var q := PhysicsShapeQueryParameters2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(44.0, 32.0)   
	q.shape = box
	q.transform = Transform2D(0.0, global_position + Vector2(24.0 * facing, 0.0))   
	q.exclude = [get_rid()]
	for r in get_world_2d().direct_space_state.intersect_shape(q):
		var body = r.collider
		if body != null and body.has_method("take_damage"):
			print("ضربت: ", body)   
			body.take_damage(1)
 
 
func die() -> void:
	get_tree().reload_current_scene()
