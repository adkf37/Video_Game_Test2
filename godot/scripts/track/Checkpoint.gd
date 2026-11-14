extends Area3D
@export var checkpoint_index := 0
var forward := Vector3.FORWARD

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	collision_layer = 0
	collision_mask = 2

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("racers") and body.velocity.dot(forward) > 0.5:
		var manager := get_tree().get_first_node_in_group("race")
		if manager:
			manager.checkpoint_hit(checkpoint_index, body)
