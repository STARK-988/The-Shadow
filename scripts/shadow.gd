
extends Area2D
 
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
 
 
func _enter_tree() -> void:
	add_to_group("shadow")   
 
 
func _ready() -> void:
	z_index = 10  
	sprite.modulate = Color(0.1, 0.1, 0.15, 0.7)   
	if sprite.sprite_frames == null:
		push_error("الظل: الـ AnimatedSprite2D مفيهوش Sprite Frames!")
	visible = false
	monitoring = false
	monitorable = false
 
 
func set_active(on: bool) -> void:
	if visible == on:
		return
	visible = on
	set_deferred("monitorable", on)
	set_deferred("monitoring", on)
 
 
func apply_state(s: Dictionary) -> void:
	global_position = s.pos
	sprite.flip_h = s.flip
	var anim: String = s.anim
	if anim == "" or sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(anim):
		return
	if sprite.animation != anim or not sprite.is_playing():
		sprite.play(anim)
