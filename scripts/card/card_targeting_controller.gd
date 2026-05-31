class_name CardTargetingController
extends Node

enum TargetingState {
	IDLE,
	CARD_SELECTED,
	TARGETING_STEP_1,
	TARGETING_STEP_2,
}

signal selectable_cards_changed(selectable_cards: Array[CardDefinition])
signal selection_denied(card: CardDefinition, reason: String)
signal card_selected(card: CardDefinition)
signal preview_area_changed(preview_hexes: Array[Vector2i])
signal targeting_state_changed(state: TargetingState)
signal chosen_steps_changed(chosen_steps: Array[Vector2i], required_steps: int)
signal effect_resolved(card: CardDefinition, affected_hexes: Array[Vector2i], operations: Array[Dictionary], chosen_steps: Array[Vector2i])

var _hand_cards: Array[CardDefinition] = []
var _player_elements: Dictionary[ElementSystem.ElementType, int] = {}
var _selected_card: CardDefinition
var _origin_hex: Vector2i = Vector2i.ZERO
var _chosen_steps: Array[Vector2i] = []
var _state: TargetingState = TargetingState.IDLE
var _effect_context: Dictionary = {}


func set_hand_cards(cards: Array[CardDefinition]) -> void:
	_hand_cards = cards
	emit_signal("selectable_cards_changed", get_selectable_cards())


func set_player_elements(element_pool: Dictionary[ElementSystem.ElementType, int]) -> void:
	_player_elements = element_pool
	emit_signal("selectable_cards_changed", get_selectable_cards())


func get_selected_card() -> CardDefinition:
	return _selected_card


func get_chosen_steps() -> Array[Vector2i]:
	return _chosen_steps.duplicate()


func get_required_target_steps() -> int:
	if _selected_card == null:
		return 0
	return _selected_card.get_required_target_steps()


func set_effect_context(effect_context: Dictionary) -> void:
	_effect_context = effect_context.duplicate(true)


func get_effect_context() -> Dictionary:
	return _effect_context.duplicate(true)


func get_selectable_cards() -> Array[CardDefinition]:
	var selectable: Array[CardDefinition] = []
	for card: CardDefinition in _hand_cards:
		if card == null:
			continue
		if card.can_be_paid_by(_player_elements):
			selectable.append(card)
	return selectable


func try_select_card(card: CardDefinition, origin_hex: Vector2i) -> bool:
	if card == null:
		emit_signal("selection_denied", card, "Card is null")
		return false
	if not card.can_be_paid_by(_player_elements):
		emit_signal("selection_denied", card, "Not enough elements")
		return false
	if not card.is_targeting_ready():
		emit_signal("selection_denied", card, "Card missing area or effect definitions")
		return false

	_selected_card = card
	_origin_hex = origin_hex
	_chosen_steps.clear()
	_effect_context.clear()
	_state = TargetingState.TARGETING_STEP_1
	emit_signal("card_selected", card)
	emit_signal("targeting_state_changed", _state)
	emit_signal("chosen_steps_changed", _chosen_steps.duplicate(), _selected_card.get_required_target_steps())
	return true


func update_hover_hex(hover_hex: Vector2i) -> void:
	if _selected_card == null or _selected_card.area_pattern == null:
		var empty_preview: Array[Vector2i] = []
		emit_signal("preview_area_changed", empty_preview)
		return
	var preview: Array[Vector2i] = _selected_card.area_pattern.build_hover_preview_hexes(_origin_hex, hover_hex, _chosen_steps)
	emit_signal("preview_area_changed", preview)


func confirm_target_hex(target_hex: Vector2i) -> bool:
	if _selected_card == null or _selected_card.area_pattern == null:
		return false
	if not _is_hex_in_cast_range(target_hex):
		return false
	if not _selected_card.area_pattern.is_step_valid(_origin_hex, target_hex, _chosen_steps):
		return false

	_chosen_steps.append(target_hex)
	emit_signal("chosen_steps_changed", _chosen_steps.duplicate(), _selected_card.get_required_target_steps())
	var required_steps := _selected_card.get_required_target_steps()
	if _chosen_steps.size() < required_steps:
		_state = TargetingState.TARGETING_STEP_2
		emit_signal("targeting_state_changed", _state)
		return true

	var affected_hexes: Array[Vector2i] = _selected_card.area_pattern.resolve_affected_hexes(_origin_hex, _chosen_steps)
	var context_snapshot: Dictionary = _effect_context.duplicate(true)
	var operations: Array[Dictionary] = _selected_card.effect_definition.apply(context_snapshot, affected_hexes, _chosen_steps)
	emit_signal("effect_resolved", _selected_card, affected_hexes, operations, _chosen_steps.duplicate())
	_reset_targeting()
	return true


func cancel_targeting() -> void:
	_reset_targeting()


func _is_hex_in_cast_range(target_hex: Vector2i) -> bool:
	if _selected_card == null:
		return false
	var distance: int = CardHexMath.axial_distance(_origin_hex, target_hex)
	return distance >= _selected_card.cast_range_min and distance <= _selected_card.cast_range_max


func _reset_targeting() -> void:
	_selected_card = null
	_chosen_steps.clear()
	_effect_context.clear()
	_state = TargetingState.IDLE
	var empty_preview: Array[Vector2i] = []
	var empty_steps: Array[Vector2i] = []
	emit_signal("preview_area_changed", empty_preview)
	emit_signal("targeting_state_changed", _state)
	emit_signal("chosen_steps_changed", empty_steps, 0)
