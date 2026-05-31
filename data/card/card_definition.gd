class_name CardDefinition
extends Resource

enum TargetingMode {
	SINGLE_STEP,
	MULTI_STEP,
}

@export_group("Identity")
@export var card_id: String = ""
@export var display_name: String = ""

@export_group("Costs")
@export var element_costs: Array[ElementCostEntry] = []

@export_group("Targeting")
@export var cast_range_min: int = 0
@export var cast_range_max: int = 3
@export var targeting_mode: TargetingMode = TargetingMode.SINGLE_STEP
@export var area_pattern: Resource
@export var effect_definition: Resource
@export var can_target_units: bool = true
@export var can_target_empty_hexes: bool = true
@export var requires_line_of_sight: bool = false
@export var show_full_pattern_on_hover: bool = true

@export_group("Presentation")
@export var accent_color: Color = Color(0.85, 0.35, 0.2)
@export_multiline var description: String = ""
@export var icon: Texture2D


func get_title() -> String:
	if display_name.is_empty():
		return card_id
	return display_name


func get_total_element_cost() -> int:
	return ElementSystem.get_total_element_cost(element_costs)


func get_element_cost_summary() -> String:
	return ElementSystem.get_element_cost_summary(element_costs)


func can_be_paid_by(element_pool: Dictionary[ElementSystem.ElementType, int]) -> bool:
	for cost_entry: ElementCostEntry in element_costs:
		if cost_entry == null or cost_entry.amount <= 0:
			continue
		if element_pool.get(cost_entry.element_type, 0) < cost_entry.amount:
			return false
	return true


func get_required_target_steps() -> int:
	if area_pattern == null or not area_pattern.has_method("get_required_input_steps"):
		return 1
	return maxi(1, area_pattern.get_required_input_steps())


func is_targeting_ready() -> bool:
	return (
		area_pattern != null
		and area_pattern.has_method("resolve_affected_hexes")
		and area_pattern.has_method("build_hover_preview_hexes")
		and effect_definition != null
		and effect_definition.has_method("apply")
	)

