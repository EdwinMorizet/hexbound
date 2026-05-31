class_name ElementSystem
extends RefCounted

enum ElementType {
	FIRE,
	WATER,
	EARTH,
	WIND,
}

const ELEMENT_LABELS: Array[String] = ["Fire", "Water", "Earth", "Wind"]
const ELEMENT_COLORS: Array[Color] = [
	Color(0.87, 0.37, 0.21),
	Color(0.22, 0.52, 0.88),
	Color(0.52, 0.40, 0.24),
	Color(0.42, 0.78, 0.71),
]


static func element_type_to_label(element_type: ElementType) -> String:
	if element_type >= 0 and element_type < ELEMENT_LABELS.size():
		return ELEMENT_LABELS[element_type]
	return "Unknown"


static func element_type_to_color(element_type: ElementType) -> Color:
	if element_type >= 0 and element_type < ELEMENT_COLORS.size():
		return ELEMENT_COLORS[element_type]
	return Color.MAGENTA


static func get_total_element_cost(cost_entries: Array[ElementCostEntry]) -> int:
	var total_cost: int = 0
	for cost_entry: ElementCostEntry in cost_entries:
		if cost_entry != null:
			total_cost += max(0, cost_entry.amount)
	return total_cost


static func get_element_cost_summary(cost_entries: Array[ElementCostEntry]) -> String:
	if cost_entries.is_empty():
		return "0"

	var parts: PackedStringArray = []
	for cost_entry: ElementCostEntry in cost_entries:
		if cost_entry == null or cost_entry.amount <= 0:
			continue
		parts.append("%d %s" % [cost_entry.amount, element_type_to_label(cost_entry.element_type)])

	if parts.is_empty():
		return "0"
	return " + ".join(parts)
