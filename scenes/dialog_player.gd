extends CanvasLayer

var dialogue = []
var current_dialogue_id = 0
var d_active = false

@export var hide_player_ui_path : NodePath
var player_ui = null

func load_dialogue():
	var file = FileAccess.open("res://assets/dialog/danny.json", FileAccess.READ)
	var content = JSON.parse_string(file.get_as_text())
	return content

func _ready():
	player_ui = get_node(hide_player_ui_path)
	$NinePatchRect.visible = false
	$Name.text = ""
	$Contents.text = ""

func _process(_delta):
	if $Contents.get_visible_characters() < len($Contents.text):
		$Contents.set_visible_characters($Contents.get_visible_characters() + 1)

func start():
	if d_active:
		return
	d_active = true
	$NinePatchRect.visible = true
	dialogue = load_dialogue()
	player_ui.visible = false

	$Name.text = dialogue[0]["name"]
	$Contents.text = dialogue[0]["chat"]

func _input(event):
	if event.is_action_pressed("ui_accept"):
		if $Contents.get_visible_characters() < len($Contents.text):
			$Contents.set_visible_characters(len($Contents.text))
		else:
			$Contents.set_visible_characters(0)
			next_script()
	
	if Input.is_key_pressed(KEY_E) and not d_active:
		current_dialogue_id = 0
		start()

func next_script():
	current_dialogue_id += 1

	if current_dialogue_id >= len(dialogue):
		d_active = false
		$NinePatchRect.visible = false
		$Name.text = ""
		$Contents.text = ""
		player_ui.visible = true
		return

	$Name.text = dialogue[current_dialogue_id]["name"]
	$Contents.text = dialogue[current_dialogue_id]["chat"]
