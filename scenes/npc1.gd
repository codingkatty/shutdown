extends Area3D

@export var dialog_path: NodePath
var dialog = null

func _ready() -> void:
	dialog = get_node(dialog_path)

func _process(_delta: float) -> void:
	pass

func _on_body_entered(body:Node3D) -> void:
	if Input.is_key_pressed(KEY_E) and body.is_in_group("player"):
		dialog.start()
