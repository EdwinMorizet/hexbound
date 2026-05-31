---
description: "Use when implementing or refactoring HEXBOUND gameplay systems, including hex map generation, terrain states, movement, combat, elements, shrines, units, and cards. Enforces the game design document as source of truth for mechanics."
name: "HEXBOUND Game Design Guardrails"
applyTo: "**"
---
# HEXBOUND Game Design Guardrails

Use this document as the mechanical source of truth for HEXBOUND implementation work.
Prefer deterministic, testable systems and preserve tactical clarity.

## Core Pillars

- Tactical skirmish on a compact 3D flat-topped hex grid.
- Alternating unit activation: each turn is one unit activation plus up to one card play.
- Terrain is mutable through elemental cards and must meaningfully affect movement, line of sight, and combat outcomes.
- Combat outcomes are deterministic, with no random hit or damage rolls.
- Victory comes from eliminating the enemy Commander or controlling key shrine economy long enough to secure board dominance.

## Map And Grid Constraints

- Map is one large hex with side length 5 (61 tiles total).
- Grid orientation is flat-topped.
- Every hex tracks:
  - Height (0 to 5)
  - Biome (Water, Desert, Plain, Forest, Rocky, Mountain Peak)
  - State overlay (Normal, Frozen, Muddy, Mist, Chasm, On Fire, and future overlays)
- Height generation uses two noise passes:
  - Elevation noise maps values to heights 0 to 5.
  - Moisture noise disambiguates Height 1 to 2 into Desert or Plain patches.

## Height, Biome, And Traversal Rules

- Height 0 is Water and is impassable for standard ground units.
- Height 5 is Mountain Peak and is impassable for standard ground units.
- Standard movement:
  - Adjacent flat move costs 1 MOV.
  - Ascend or descend by 1 height requires CLM >= 1.
  - Ascend by 1 costs 2 MOV.
  - Descend by 1 costs 1 MOV.
- Height delta >= 2 is a cliff wall for normal movement unless a special trait or card bypasses it.
- Preserve biome movement and tactical traits:
  - Forest gives ranged cover effect and can burn down into Plain.
  - Rocky is stable and hard to overgrow.

## Terrain State Rules

- Frozen: is a formal terrain state. Units entering a Frozen hex slide in a straight line to the next valid stop, and lose their attack action if movement is interrupted by an obstruction.
- Muddy: consumes all remaining movement when entered.
- Mist: blocks line of sight through or out of affected hexes for ranged attacks.
- Chasm: impassable and lethal to non-flying units if forced into it; cannot be placed on height 0 or 5.
- On Fire: damages units entering or starting turn on tile; can spread each turn using biome-sensitive chances.
- Forest tiles on fire degrade to Plain after 2 turns.

## Turn, Round, And Economy Rules

- Start of round: controlled Shrines generate elements, including prior Pray bonus.
- Commander generates personal base elements at the start of its own activation.
- End of round: both players draw 1 card.
- Hand limit is 5.
- Elements do not decay and stack across turns and rounds.
- Shrine capture happens when a unit ends movement on shrine hex.
- Capturing player assigns shrine element (Fire, Water, Earth, or Wind).
- Pray action spends full activation and grants +1 extra element from that shrine at next round start.

## Combat Rules

- Melee (range 1): defender counter-attacks if still alive and able.
- A unit that used Pray cannot counter-attack.
- Ranged attacks require line of sight and do not trigger counter-attacks.
- High ground advantage:
  - +1 ATK when attacking from higher elevation.
  - Ranged attacks may gain +1 RNG from higher elevation.
- Low ground restriction formula:
  - Target is valid only if defender_height - attacker_height <= attacker_range + 1.
  - Target is invalid if defender_height - attacker_height > attacker_range + 1.

## Unit And Card System Guardrails

- Army composition uses a fixed point cap (example baseline: 100 points).
- Deck size cap is 20 cards; opening hand is 3.
- Keep baseline roster behavior intact:
  - Foot Soldier has adjacency-based Phalanx bonus.
  - Skirmisher has superior climb profile.
  - Crossbowman cannot attack after moving.
  - Guardian applies adjacent movement lockdown behavior.
- Preserve elemental visual identity for cards:
  - Earth: terrain shaping and obstruction.
  - Water: conversion, mud, and flooding control.
  - Fire: damage over terrain and spread pressure.
  - Wind: displacement and positioning disruption.
- Scalable cards must scale cost, area, and impact consistently by invested elements.

## Cards

### Specifications

- Cards can have multiple elements with multiple costs.
- Cards have a hex range.
- Hex ranges can be : line, A* like, circle with inner circle mask, t-shape, l-shape.
- With the A* like, player choose first hex then another one after one with A* cost based on specific conditions.

### Examples

- **Raise / Lower (1 Earth):** Adjust the height of 1 adjacent hex by !.  
- **Irrigate (1 Water):** Transform a Desert hex to a Plain biome, or a Plain hex to a Forest biome.  
- **Ignite (1 Fire):** Apply the **On Fire** state to a Plain or Forest hex. Forest biomes will burn down into Plains after 2 turns.  
- **Zephyr (1 Wind):** Move a friendly or enemy unit 1 hex, ignoring height restrictions.

## Implementation Guidance For The Agent

- When mechanics conflict, follow this order:
  - Explicit card text
  - Core combat and movement rules
  - Terrain state rules
  - Biome defaults
- Favor data-driven definitions (resources/tables) over hardcoded branching when adding units, cards, and states.
- Keep systems modular so new units/cards can be added without rewriting core resolution.
- Any intentional rule deviation must be called out in task output with reason and downstream impact.
