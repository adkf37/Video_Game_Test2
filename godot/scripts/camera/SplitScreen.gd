extends CanvasLayer
## Two views share one World3D and one physics simulation.
var containers: Array[SubViewportContainer] = []
var cameras: Array[Camera3D] = []
var manager: Node
var main_camera: Camera3D
var active := false

func _ready() -> void:
	layer = 0
	process_mode = Node.PROCESS_MODE_ALWAYS
	manager = get_parent().get_node("RaceManager")
	main_camera = get_parent().get_node("ChaseCamera")
	call_deferred("_setup")

func _setup() -> void:
	if manager.players.size() != 2:
		return
	for i in range(2):
		var holder := SubViewportContainer.new()
		holder.stretch = true
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(holder)
		var viewport := SubViewport.new()
		viewport.world_3d = get_viewport().world_3d
		viewport.handle_input_locally = false
		viewport.gui_disable_input = true
		viewport.msaa_3d = Viewport.MSAA_2X
		holder.add_child(viewport)
		var camera := Camera3D.new()
		camera.set_script(preload("res://scripts/camera/ChaseCamera.gd"))
		camera.target = manager.players[i]
		camera.player_index = i
		camera.attributes = main_camera.attributes
		viewport.add_child(camera)
		camera.make_current()
		containers.append(holder)
		cameras.append(camera)
	_layout()
	get_viewport().size_changed.connect(_layout)
	_set_active(false)

func _layout() -> void:
	var dimensions := get_viewport().get_visible_rect().size
	for i in range(containers.size()):
		containers[i].position = Vector2(0, dimensions.y * 0.5 * i)
		containers[i].size = Vector2(dimensions.x, dimensions.y * 0.5)

func _set_active(value: bool) -> void:
	active = value
	for holder in containers:
		holder.visible = active
		var viewport: SubViewport = holder.get_child(0)
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if active else SubViewport.UPDATE_DISABLED
	if active:
		main_camera.clear_current(false)
		for camera in cameras:
			camera.snap()
	else:
		main_camera.make_current()

func _process(_delta: float) -> void:
	if containers.is_empty():
		return
	var desired: bool = manager.state != manager.RaceState.MENU
	if desired != active:
		_set_active(desired)
