class_name CardUi
extends PanelContainer

const DEFAULT_CARD_SIZE: Vector2 = Vector2(240.0, 340.0)

@onready var _accent_bar: ColorRect = %AccentBar
@onready var _art: TextureRect = %Art
@onready var _title_label: Label = %TitleLabel
@onready var _cost_label: Label = %CostLabel
@onready var _breakdown_label: Label = %BreakdownLabel
@onready var _description_label: Label = %DescriptionLabel

var _card_definition: CardDefinition


func _ready() -> void:
	custom_minimum_size = DEFAULT_CARD_SIZE
	_render_card()


func set_card_definition(card_definition: CardDefinition) -> void:
	_card_definition = card_definition
	if is_node_ready():
		_render_card()


func _render_card() -> void:
	if _card_definition == null:
		_accent_bar.color = Color(0.25, 0.25, 0.28)
		_art.texture = null
		_title_label.text = "Empty"
		_cost_label.text = "Total 0"
		_breakdown_label.text = "No element breakdown"
		_description_label.text = "No card data assigned."
		return

	_accent_bar.color = _card_definition.accent_color
	_art.texture = _card_definition.icon
	_title_label.text = _card_definition.get_title()
	_cost_label.text = "Total %d" % _card_definition.get_total_element_cost()
	_breakdown_label.text = _card_definition.get_element_cost_summary()
	_description_label.text = _card_definition.description if not _card_definition.description.is_empty() else "No rules text."
