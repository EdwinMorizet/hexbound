class_name BattleScene
extends Node3D

@onready var _board: HexGridGenerator3D = %BattleBoard
@onready var _status_label: Label = %StatusLabel


func _ready() -> void:
	if _board != null:
		_board.enable_card_targeting_demo = true
		_board.regenerate()
	_update_status_text()


func _on_regenerate_pressed() -> void:
	if _board == null:
		return
	_board.regenerate()
	_update_status_text()


func _on_new_seed_pressed() -> void:
	if _board == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	_board.world_seed = rng.randi()
	_board.regenerate()
	_update_status_text()


func _update_status_text() -> void:
	if _board == null:
		_status_label.text = "Board unavailable"
		return
	_status_label.text = "Seed %d | Side %d" % [_board.world_seed, _board.side_length]
