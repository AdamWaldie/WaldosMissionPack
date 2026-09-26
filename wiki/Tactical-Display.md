# Tactical Display

> **Use this page when:** players should inspect friendly positions and known enemy contacts at a physical map board.

Tactical Display opens a local map from a registered world object. It shows friendlies and enemies already known to the player's group within the configured radius. It is not a live enemy-location cheat: unknown contacts stay hidden.

## Set up a board

1. Place a map board or whiteboard-style object in Eden, such as `Land_MapBoard_F`.
2. Put this in the object's **Init** field:

   ```sqf
   [this] call Waldo_fnc_TacticalDisplayRegister;
   ```

3. Start the mission and approach the board. The interaction opens a map. Walk away to confirm the display closes.

The registration call forwards to the server when needed. Clients, including late joiners, receive the interaction state. A generic prop cannot reliably display an interactive map on its own material, so use a suitable board.

## Change access and range

The full call is `[board, side, radius, showKnownEnemies, interaction] call Waldo_fnc_TacticalDisplayRegister`:

| Position | Type | Default | What to supply |
|---|---|---|---|
| 0 | Object | Required | Existing map board, whiteboard or suitable terminal. |
| 1 | Side or string | `"VIEWER"` | `"VIEWER"` follows each player's side. Use `west`, `east`, `independent`, `civilian`, or a recognized side string for one fixed side. |
| 2 | Number | `2000` | Map radius in metres. WMP clamps values below `100` to `100`. |
| 3 | Boolean | `true` | Show enemy contacts the viewer's group knows about. |
| 4 | HashMap or array of `[key, value]` rows | Empty | Optional access gate. Keys are `enabled` (Boolean, default `false`), `challengeId` (string, default `"commandinput"`) and `difficulty` (string, default `"standard"`). |

The optional interaction HashMap can require a shared equipment procedure before opening the map. For example:

```sqf
private _gate = createHashMapFromArray [
    ["enabled", true], ["challengeId", "commandinput"], ["difficulty", "standard"]
];
[this, west, 2000, true, _gate] call Waldo_fnc_TacticalDisplayRegister;
```

The one-argument call leaves the gate off. When you enable it, the default procedure is `commandinput / standard`. The call returns `true` when the server registers the object. Client copies of an Eden Init call do no work. WMP publishes the board state and action for joining clients. Zeus can register a board through the Tactical Display module.

Edit the existing rows in `MissionConfig/interfaceConfig.sqf` for mission-wide distances:

| Setting | Type | Shipped value | Effect |
|---|---|---:|---|
| `Waldo_TacticalDisplay_AccessDistance` | Number, metres | `4` | Distance at which the action appears. |
| `Waldo_TacticalDisplay_MaximumOpenDistance` | Number, metres | `8` | Distance beyond which an open map closes. |
| `Waldo_TacticalDisplay_MinimumKnowledge` | Number, Arma `knowsAbout` value 0–4 | `1.5` | Minimum group knowledge needed to show an enemy contact. |

## If the board does not work

Check that the target is a map board or whiteboard, the registration call ran on the placed object, and the player is inside the access distance. If the map opens but enemies are absent, the group may not know about them or the knowledge threshold may be too high. Destroying the object or leaving range closes the display.

## See also

- [Interaction Procedures](Waldos-Mini-Games-Interaction-Challenges) for the optional access gate
- [Optional Feature Extensions](Optional-Feature-Extensions) for the advanced display options

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
