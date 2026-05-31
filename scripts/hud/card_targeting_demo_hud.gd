class_name CardTargetingDemoHud
extends CanvasLayer

signal card_pick_requested(card: CardDefinition)
signal cancel_requested()
signal height_delta_choice_requested(delta_height: int)

var _root_margin: MarginContainer
var _panel: PanelContainer
var _title_label: Label
var _selected_card_label: Label
var _step_label: Label
var _elements_label: Label
var _cards_box: VBoxContainer
var _result_label: Label
var _height_mode_row: HBoxContainer
var _height_mode_label: Label
var _raise_button: Button
var _lower_button: Button
var _current_selected_card_id: String = ""


func _ready() -> void:
	layer = 5
	_build_ui()


func set_selectable_cards(cards: Array[CardDefinition]) -> void:
	if _cards_box == null:
		return
	for child: Node in _cards_box.get_children():
		child.queue_free()

	if cards.is_empty():
		var empty := Label.new()
		empty.text = "No payable cards"
		_cards_box.add_child(empty)
		return

	for index: int in range(cards.size()):
		var card: CardDefinition = cards[index]
		if card == null:
			continue
		var button := Button.new()
		button.text = "%d. %s (%s)" % [index + 1, card.get_title(), card.get_element_cost_summary()]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_on_card_button_pressed.bind(card))
		if not _current_selected_card_id.is_empty() and card.card_id == _current_selected_card_id:
			button.modulate = Color(1.0, 0.96, 0.72)
		_cards_box.add_child(button)


func set_selected_card(card: CardDefinition) -> void:
	if card == null:
		_current_selected_card_id = ""
		_selected_card_label.text = "Selected: none"
		return
	_current_selected_card_id = card.card_id
	_selected_card_label.text = "Selected: %s" % card.get_title()


func set_targeting_progress(chosen_steps: Array[Vector2i], required_steps: int) -> void:
	if required_steps <= 0:
		_step_label.text = "Targeting: idle"
		return
	_step_label.text = "Targeting steps: %d / %d" % [chosen_steps.size(), required_steps]


func set_element_pool_text(element_pool: Dictionary[ElementSystem.ElementType, int]) -> void:
	var fire: int = element_pool.get(ElementSystem.ElementType.FIRE, 0)
	var water: int = element_pool.get(ElementSystem.ElementType.WATER, 0)
	var earth: int = element_pool.get(ElementSystem.ElementType.EARTH, 0)
	var wind: int = element_pool.get(ElementSystem.ElementType.WIND, 0)
	_elements_label.text = "Elements: F %d | W %d | E %d | A %d" % [fire, water, earth, wind]


func set_resolution_text(message: String) -> void:
	_result_label.text = message


func set_height_mode_visible(should_show: bool) -> void:
	if _height_mode_row == null:
		return
	_height_mode_row.visible = should_show


func set_height_mode(delta_height: int) -> void:
	if _height_mode_label == null:
		return
	var mode_text: String = "Raise" if delta_height >= 0 else "Lower"
	_height_mode_label.text = "Height mode: %s" % mode_text
	if _raise_button != null:
		_raise_button.modulate = Color(1.0, 0.95, 0.75) if delta_height >= 0 else Color(1, 1, 1)
	if _lower_button != null:
		_lower_button.modulate = Color(1.0, 0.95, 0.75) if delta_height < 0 else Color(1, 1, 1)


func _on_card_button_pressed(card: CardDefinition) -> void:
	emit_signal("card_pick_requested", card)


func _build_ui() -> void:
	_root_margin = MarginContainer.new()
	_root_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root_margin.add_theme_constant_override("margin_left", 12)
	_root_margin.add_theme_constant_override("margin_top", 12)
	_root_margin.add_theme_constant_override("margin_right", 12)
	_root_margin.add_theme_constant_override("margin_bottom", 12)
	add_child(_root_margin)

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_root_margin.add_child(row)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(440.0, 220.0)
	row.add_child(_panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	_panel.add_child(content)

	_title_label = Label.new()
	_title_label.text = "Card Targeting Demo"
	content.add_child(_title_label)

	_selected_card_label = Label.new()
	_selected_card_label.text = "Selected: none"
	content.add_child(_selected_card_label)

	_step_label = Label.new()
	_step_label.text = "Targeting: idle"
	content.add_child(_step_label)

	_elements_label = Label.new()
	_elements_label.text = "Elements:"
	content.add_child(_elements_label)

	var hint_label := Label.new()
	hint_label.text = "Left click hex to confirm. Right click to cancel targeting."
	content.add_child(hint_label)

	_cards_box = VBoxContainer.new()
	_cards_box.add_theme_constant_override("separation", 4)
	content.add_child(_cards_box)

	_height_mode_row = HBoxContainer.new()
	_height_mode_row.visible = false
	_height_mode_row.add_theme_constant_override("separation", 6)
	content.add_child(_height_mode_row)

	_height_mode_label = Label.new()
	_height_mode_label.text = "Height mode: Raise"
	_height_mode_row.add_child(_height_mode_label)

	_raise_button = Button.new()
	_raise_button.text = "Raise"
	_raise_button.pressed.connect(_on_raise_pressed)
	_height_mode_row.add_child(_raise_button)

	_lower_button = Button.new()
	_lower_button.text = "Lower"
	_lower_button.pressed.connect(_on_lower_pressed)
	_height_mode_row.add_child(_lower_button)

	_result_label = Label.new()
	_result_label.text = "Last resolve: none"
	content.add_child(_result_label)

	var controls_row := HBoxContainer.new()
	content.add_child(controls_row)

	var cancel_button := Button.new()
	cancel_button.text = "Cancel Targeting"
	cancel_button.pressed.connect(_on_cancel_pressed)
	controls_row.add_child(cancel_button)


func _on_cancel_pressed() -> void:
	emit_signal("cancel_requested")


func _on_raise_pressed() -> void:
	emit_signal("height_delta_choice_requested", 1)


func _on_lower_pressed() -> void:
	emit_signal("height_delta_choice_requested", -1)
