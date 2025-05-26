class_name PlayerState extends State

const IDLE = "Idle"
const WALKING = "Walking"
const AIR = "Air"
const ATTACK = "Attack"
#const FALLING = "Falling" 
const GRAPPLE = "Grapple"
const GUARD = "Guard"
const DASH = "Dashing"

var player: Player


func _ready() -> void:
	player = find_parent("Player")
	if player:
		await player.ready
	assert(player != null, "The PlayerState state type must be used only in the player scene. It needs the owner to be a Player node.")
