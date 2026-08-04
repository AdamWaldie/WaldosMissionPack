# Eden compositions

> **Use this page when:** you want a pre-placed, editable example instead of building a supported
> WMP setup from individual Eden objects.

WMP compositions are shipped as a separate archive. They accelerate mission authoring but do not
include the feature scripts themselves. Install the matching WMP release in the mission first.

The catalogue is split into Foundation, Logistics, Air Operations, Combat Systems, Interface,
Mission Systems and Mission Tools so Eden does not present one undifferentiated list.

## Newly covered systems

- **Vehicle Recovery Workshop Example:** a safely spaced workshop, recoverable MRAP and generic
  `AUTO` carrier. All share workshop key `MAIN`; the workshop includes optional area and point
  markers.
- **Field Resupply Hub Example:** an unlimited, all-side hub. Assign portable crates to infantry
  with Zeus or `[unit, currentCrates, maximumCrates] call Waldo_fnc_FieldResupplyAssignCarrier`.
- **Radio Jammer Example:** a 300 m omnidirectional jammer affecting all sides and bands. It starts
  active, is curator-visible, and uses the mission's configured disable/reactivate interaction.
- **Hazardous Emitter Example:** a 15 m toxic leak with entry/exit notification, staged damage and
  fatal exposure. Its inline profile is deliberately visible so it can be rewritten for scenario RP.
- **Tactical Display Example:** a supported map board that opens the client Tactical Display. It
  follows the viewer's side, uses a 2000 m radius and may show known enemy contacts.

## Locality rule

Composition init fields that register shared state or change global cargo use an `isServer` guard.
The public function then publishes actions/settings for connected players and JIP. Local-only Eden
actions, such as teleport boarding points, run on each interface through their repeat-safe setup
path. Do not remove these boundaries when editing examples.

## Why some features have no composition

Generated AO/AA systems, player accessibility, treatment feedback, persistence, UI themes, rally
state and automatic AI handlers do not become clearer or safer when represented by a decorative
Eden object. Use their `MissionConfig` settings, public setup call or focused Zeus module instead.

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature setup](Feature-Setup-and-Activation)
