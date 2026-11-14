
extends CharacterBody2D
 
@export var patrol_speed := 50.0       
@export var chase_speed := 110.0       
@export var sight_range := 180.0      
@export var sight_height := 48.0       
@export var sprite_faces_right := true 
 
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
 
var dir := 1
var player: Node2D = null
var chasing := false
var dead := false
 
 
func _ready() -> void:
	hitbox.body_entered.connect(_on_hitbox_body_entered)
 
 
func _physics_process(delta: float) -> void:
	if dead:
		return
	if player == null:
		player = get_tree().get_first_node_in_group("player") as Node2D
 
	if not is_on_floor():
		velocity.y += 1000.0 * delta
 
	chasing = _can_see_player()
 
	if chasing:
		dir = 1 if player.global_position.x > global_position.x else -1
		velocity.x = dir * chase_speed
		_play("attack")
	else:
		velocity.x = dir * patrol_speed
		_play("idle")
 
	move_and_slide()
 
	if is_on_wall() and not chasing:
		dir = -dir
 
	sprite.flip_h = (dir < 0) if sprite_faces_right else (dir > 0)
 
 
func _can_see_player() -> bool:
	if player == null:
		return false
	var d := player.global_position - global_position
	if absf(d.x) > sight_range or absf(d.y) > sight_height:
		return false
	if not chasing and signf(d.x) != float(dir):
		return false
	var q := PhysicsRayQueryParameters2D.create(global_position, player.global_position, 1)
	q.exclude = [get_rid()]
	var hit := get_world_2d().direct_space_state.intersect_ray(q)
	return hit.is_empty() or hit.get("collider") == player
 
 
func _play(anim: String) -> void:
	if sprite.animation != anim or not sprite.is_playing():
		sprite.play(anim)
 
 
func _on_hitbox_body_entered(body: Node) -> void:
	if dead:
		return
	if body.has_method("die"):
		body.call_deferred("die")
 
 
func take_damage(_amount: int = 1, _from: Vector2 = Vector2.ZERO) -> void:
	if dead:
		return
	dead = true
	velocity = Vector2.ZERO
	hitbox.set_deferred("monitoring", false)
	collision_layer = 0
	var tw := create_tween()
	tw.tween_property(sprite, "modulate:a", 0.0, 0.3)
	await tw.finished
	queue_free()
