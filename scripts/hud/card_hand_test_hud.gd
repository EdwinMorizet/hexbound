class_name CardHandTestHud
extends CanvasLayer

const CARD_UI_SCENE: PackedScene = preload("res://scenes/card/card_ui.tscn")
const TEST_CARD_PATHS: Array[String] = [
	"res://data/card/fire/flame_jolt.tres",
	"res://data/card/water/tide_step.tres",
	"res://data/card/earth/stone_rampart.tres",
	"res://data/card/wind/gale_push.tres",
]

@onready var _count_label: Label = %CountLabel
@onready var _hand_row: HBoxContainer = %HandRow
@onready var _button_row: HBoxContainer = get_node("Root/MarginContainer/VBoxContainer/ButtonRow") as HBoxContainer

var _test_cards: Array[CardDefinition] = []
var _hand_size: int = 0


func _ready() -> void:
	_wire_count_buttons()
	_build_test_cards()
	_set_hand_size(0)


func _wire_count_buttons() -> void:
	if _button_row == null:
		return
	for child: Node in _button_row.get_children():
		var button := child as Button
		if button == null:
			continue
		var count := int(button.text)
		var callback := _on_count_button_pressed.bind(count)
		if not button.pressed.is_connected(callback):
			button.pressed.connect(callback)


func _on_count_button_pressed(count: int) -> void:
	_set_hand_size(count)


func _set_hand_size(count: int) -> void:
	_hand_size = clampi(count, 0, 5)
	_count_label.text = "Hand size: %d / 5" % _hand_size
	_refresh_hand_row()


func _refresh_hand_row() -> void:
	for child: Node in _hand_row.get_children():
		child.queue_free()

	if _hand_size == 0:
		var empty_label := Label.new()
		empty_label.text = "Hand empty"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		empty_label.custom_minimum_size = Vector2(240.0, 340.0)
		_hand_row.add_child(empty_label)
		return

	var cards_to_render: int = mini(_hand_size, _test_cards.size())
	if cards_to_render == 0:
		var missing_label := Label.new()
		missing_label.text = "No test card resources loaded"
		missing_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		missing_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		missing_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		missing_label.custom_minimum_size = Vector2(240.0, 340.0)
		_hand_row.add_child(missing_label)
		return

	for index: int in range(cards_to_render):
		var card_ui := CARD_UI_SCENE.instantiate() as CardUi
		if card_ui == null:
			continue
		card_ui.set_card_definition(_test_cards[index])
		_hand_row.add_child(card_ui)


func _build_test_cards() -> void:
	_test_cards.clear()
	for card_path: String in TEST_CARD_PATHS:
		var card_definition := load(card_path) as CardDefinition
		if card_definition != null:
			_test_cards.append(card_definition)
