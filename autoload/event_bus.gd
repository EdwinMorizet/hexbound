class_name EventBus
extends Node

## Terrain and board lifecycle.
signal hex_grid_generated(tile_count: int)
signal terrain_state_applied(q: int, r: int, state_name: String)

## Turn and economy lifecycle.
signal round_started(round_index: int)
signal unit_activation_started(player_id: int, unit_id: int)
signal unit_prayed(player_id: int, unit_id: int, shrine_q: int, shrine_r: int)
signal mana_changed(player_id: int, current_mana: int, delta: int)
signal shrine_captured(player_id: int, unit_id: int, shrine_q: int, shrine_r: int, shrine_element: String)

## Combat lifecycle.
signal attack_resolved(attacker_id: int, defender_id: int, dealt_damage: int, was_counter_attack: bool)
signal unit_defeated(unit_id: int)
signal commander_defeated(player_id: int, commander_unit_id: int)

## Card lifecycle.
signal card_played(player_id: int, card_id: String, spent_mana: int)
signal card_drawn(player_id: int, card_id: String)
