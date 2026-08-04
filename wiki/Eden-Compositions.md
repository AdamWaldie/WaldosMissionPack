# Eden compositions

> **Use this page when:** you want a pre-placed, editable example instead of building a supported
> WMP setup from individual Eden objects.

WMP compositions are shipped as a separate archive. They accelerate mission authoring but do not
include the feature scripts themselves. Install the matching WMP release in the mission first.

The catalogue is split into Foundation, Logistics, Air Operations, Combat Systems, Interface,
Mission Systems and Mission Tools so Eden does not present one undifferentiated list.

## Newly covered systems

- **Bomb Defusal Example:** an editable electronic device with the standard wire-cutting challenge
  and explosive failure consequence.
- **Construction Objects Example:** an ACE construction supply crate using the modern construction
  audio profile.
- **Electronic Warfare Examples:** one EMP-immune vehicle and one WEST-tracked vehicle, spaced for
  immediate testing.
- **Object Scaling Example:** a decorative object converted to a supported Simple Object at 175%
  scale. The comment warns that conversion replaces the original object reference.
- **Custom 3D Marker Example:** a signal relay with labelled marker options written as readable
  key/value pairs in its init field.

- **Vehicle Recovery Workshop Example:** a safely spaced workshop, recoverable MRAP and generic
  `AUTO` carrier. All share workshop key `MAIN`; the workshop includes optional area and point
  markers.
- **Field Resupply Hub Example:** an unlimited, all-side hub. Assign portable crates to infantry
  with Zeus or `[unit, currentCrates, maximumCrates] call Waldo_fnc_FieldResupplyAssignCarrier`.
- **Radio Jammer Example:** a 300 m omnidirectional jammer affecting all sides and bands. It starts
  active, is curator-visible, and uses the mission's configured disable/reactivate interaction.
- **Hazardous Zone Example:** a fixed 15 m toxic leak with entry/exit notification, staged damage and
  fatal exposure. Its inline profile is deliberately visible so it can be rewritten for scenario RP.
- **Tactical Display Example:** a supported map board that opens the client Tactical Display. It
  follows the viewer's side, uses a 2000 m radius and may show known enemy contacts.
- **Loadout Save Point Example:** a laptop with both the ACE interaction and WMP-blue vanilla action;
  the save includes supported ACRE radio state and is restored for that player only.
- **Explosive Wall Breaching Example:** an explicit 8 m wall profile whose demolition-charge result
  leaves two 4 m sections and a clearly visible central gap.
- **Emergency Dismount Vehicle Example:** an upright, simulated MRAP that enables the feature without
  risking a startup collision; overturn or destroy it during play to expose the action.

## Locality rule

Composition init fields call the public feature API directly. Each API routes authority to the
server and publishes local/JIP setup where required; beginners should not need to add repetitive
`isServer` wrappers. Local-only Eden actions, such as teleport boarding points, run on each
interface through their repeat-safe setup path. Do not add a locality guard unless that function's
wiki article explicitly requires one.

Every WMP Eden comment includes the direct URL of the matching wiki article. Keep that link when
copying or adapting the example so the next mission maker can recover the parameter and locality
guidance from inside Eden.

## Why some features have no composition

Generated AO/AA systems, airborne gunships and dynamic drop zones must be created once by the server;
an Eden init runs on every machine, so their safe beginner path is `initServer.sqf` or Zeus rather
than a misleading composition. Player accessibility, treatment feedback, persistence, UI themes,
rally state, terrain-tree felling and automatic AI handlers likewise do not become clearer or safer
when represented by a decorative Eden object. Use their `MissionConfig` settings, documented public
setup call, full audit station or focused Zeus module instead.

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature setup](Feature-Setup-and-Activation)
