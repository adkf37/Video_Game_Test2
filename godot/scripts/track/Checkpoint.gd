extends Area3D
## A single checkpoint trigger volume.
## When the player drives through, it notifies the RaceManager.
## Flashes green when activated.

@export var checkpoint_index: int = 0

var _gate_mesh: MeshInstance3D = null
var _flash_timer: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	monitoring = true
	monitorable = false
	# Find the gate mesh child for visual feedback
	_gate_mesh = get_node_or_null("Gate")

func _process(delta: float) -> void:
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0 and _gate_mesh:
			# Restore original blue-ish look
			var mat = _gate_mesh.get_surface_override_material(0)
			if mat:
				_gate_mesh.set_surface_override_material(0, null)

func _on_body_entered(body: Node3D) -> void:
	if body.name == "PlayerSled" or body.is_in_group("player"):
		var race_mgr = get_tree().root.find_child("RaceManager", true, false)
		if race_mgr and race_mgr.has_method("checkpoint_hit"):
			race_mgr.checkpoint_hit(checkpoint_index)
			_flash_green()

func _flash_green() -> void:
	if not _gate_mesh:
		return
	var flash_mat = StandardMaterial3D.new()
	flash_mat.albedo_color = Color(0.0, 1.0, 0.3, 0.6)
	flash_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flash_mat.emission_enabled = true
	flash_mat.emission = Color(0.0, 0.8, 0.2, 1.0)
	flash_mat.emission_energy_multiplier = 1.5
	_gate_mesh.set_surface_override_material(0, flash_mat)
	_flash_timer = 0.5
