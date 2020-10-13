extends Node2D

onready var camera : Camera2D = Camera2D.new()
var tween = Tween.new()
onready var viewport = get_viewport()
onready var screen_size = get_viewport_rect().size
onready var static_pos = Vector2(screen_size.x/2,screen_size.y/2)

enum State {OnParty, Sequenced, Static}
var state = null

var y_cutoff := 0
var vp_scale = 1





func _ready():
	camera.process_mode = Camera2D.CAMERA2D_PROCESS_PHYSICS
	add_child(camera)
	camera.current = true
	
	tween.playback_process_mode = Tween.TWEEN_PROCESS_PHYSICS
	add_child(tween)
	
	#Disbale if Fullscreen Stretch is allowed
	screen_resize()
	get_tree().connect("screen_resized", self, "screen_resize")


func screen_resize():
	var window_size = OS.get_window_size()
	#Disable x cutoff
	var scale_x = floor(window_size.x / viewport.size.x)
	#Minimizes y cutoff
	var scale_y = round(window_size.y / viewport.size.y)
	#Diable Y Cutoff
	#var scale_y = floor(window_size.y / viewport.size.y)
	#Allow Y Cutoff
	#var scale_y = round(window_size.y / viewport.size.y)
	var scale = max(1, min(scale_x, scale_y))

	# find the coordinate we will use to center the viewport inside the window
	var diff = window_size - (viewport.size * scale)
	var diffhalf = (diff * 0.5).floor()
	# attach the viewport to the rect we calculated
	
	
	#print("Window Size: %s" % str(window_size))
	#print("Viewport Scaled To: %s"  % str(viewport.size * scale))
	#print(Scale X: %s , Scale Y: %s" % [  str(scale_x), str(scale_y)]   )
	#print(y_cutoff)	
	y_cutoff = abs(min(0,window_size.y - viewport.size.y * scale))
	vp_scale = scale

	
	viewport.set_attach_to_screen_rect(Rect2(diffhalf, viewport.size * scale))
	
	
	
	
	
#Run camera movement in physics process?
# Use signals for state changes rather than process constant checks
func _physics_process(delta):
	
	var party = get_tree().get_nodes_in_group("Party")
	if party.size() != 1:
		if state != State.Static and state != State.Sequenced: state_to_static()
	else:
		if state != State.OnParty and state != State.Sequenced: state_to_party()
	
	
	if state == State.Static:
		return
	elif state == State.OnParty:
		var party_pos = party[0].active_player.get_global_position()
		position = Vector2(party_pos.x, party_pos.y)
		if "camera_bounds" in SceneManager.current_scene:
			var bounds = SceneManager.current_scene.camera_bounds
			
			if(bounds["is_static"]):
				position = static_pos
				return
			
			var cuttoff_in_viewport = round(y_cutoff/(2 * vp_scale))
			var screen_offset_y_min = bounds["min_y"] - (screen_size.y/2 - cuttoff_in_viewport)
			var screen_offset_y_max = bounds["max_y"] + (screen_size.y/2 - cuttoff_in_viewport)
			
			if bounds["min_x"] + screen_size.x/2 <= bounds["max_x"] - screen_size.x/2:
				position.x = clamp(position.x, bounds["min_x"] + screen_size.x/2, bounds["max_x"] - screen_size.x/2)
			if screen_offset_y_max <= screen_offset_y_min:
				position.y = clamp(position.y, screen_offset_y_max, screen_offset_y_min)
			
			
		#position = Vector2(round(position.x), round(position.y))
		camera.align()
	elif state == State.Sequenced:
		position = Vector2(round(position.x), round(position.y))
		camera.align()
		return
	else:
		Debugger.dprint("ERROR: Invalid Camera Manager State")
	
	
func move_to_position(destination : Vector2, time : float):
	tween.interpolate_property(self, "position", position, destination, time)
	tween.start()
	yield(tween, "tween_completed")
	
	
func move_to_party(time : float):
	var destination = Vector2(0,0)
	var party = get_tree().get_nodes_in_group("Party")
	if party.size() == 1:
		destination = party[0].active_player.get_global_position()
	move_to_position(destination, time)


func release_camera():
	state = State.Static
	
func grab_camera():
	if state != State.Sequenced:
		state = State.Sequenced
		return true
	else:
		return false
		


func state_to_party():
	state = State.OnParty

func state_to_static():
	state = State.Static
	position = static_pos
	
func state_to_sequenced():
	state = State.Sequenced

