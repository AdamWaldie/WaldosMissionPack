# Custom 3D World Markers

> **Use this page when:** you need JIP-safe world-space labels or icons attached to objects or positions.

_Associated Files: `MissionScripts\MissionFlowAndUi\create3DMarker.sqf`, `init3DMarkers.sqf`, `remove3DMarker.sqf`, `Waldo_fnc_Create3DMarker`, `Waldo_fnc_Remove3DMarker`_


WMP can place custom icon-and-text markers directly over objects or world
positions. Markers are server-owned, broadcast to every client and immediately
available to JIP players. All markers share one local `Draw3D` handler, avoiding
one permanent loop per marker.

## Create or update a marker

Smallest working call — a stable ID and an anchor, everything else takes its default:

```sqf
["generator_alpha", generator_1] call Waldo_fnc_Create3DMarker;
```

The anchor can be an object or an ATL position. Calling the function again with
the same ID updates the existing marker in place. Calls made on clients are forwarded to
the server automatically.

Add an options HashMap as the third argument to override any default:

```sqf
[
    "generator_alpha",
    generator_1,
    createHashMapFromArray [
        ["text", "GENERATOR ALPHA | OFFLINE"],
        ["icon", "\a3\ui_f\data\map\markers\military\warning_CA.paa"],
        ["colour", [1, 0.75, 0.2, 1]],
        ["offset", [0, 0, 2.5]],
        ["distance", 80],
        ["sides", ["WEST"]]
    ]
] call Waldo_fnc_Create3DMarker;
```

| Option | Default | Purpose |
|---|---|---|
| `text` | `""` | Accessible label drawn with the icon. |
| `icon` | Vanilla dot icon | Vanilla or mission-local PAA path. |
| `colour` | WMP blue | RGBA icon/text tint; do not rely on colour alone. |
| `offset` | `[0,0,0]` | Position offset from the anchor. |
| `width`, `height` | `0.8` | Icon dimensions. |
| `angle` | `0` | Icon rotation in degrees. |
| `shadow` | `2` | Arma `drawIcon3D` shadow mode. |
| `textSize` | `0.032` | Label size. |
| `font` | `RobotoCondensedBold` | Arma font name. |
| `align` | `"center"` | Text alignment. |
| `sideArrows` | `true` | Show off-screen direction arrows. |
| `distance` | `75` | Maximum render distance in metres. |
| `sides` | `["ALL"]` | Visible sides, such as `["WEST","GUER"]`. |
| `enabled` | `true` | Temporarily hide without deleting. |

## Remove a marker

```sqf
["generator_alpha"] call Waldo_fnc_Remove3DMarker;
```

Use stable, mission-specific IDs. Always pair colour with meaningful text and
an appropriate icon so the marker remains understandable for colourblind
players.

## See also

- [Eden Compositions](Eden-Compositions) — the `[WMP]Custom_3D_Marker_Example` Minimal/Full pair
- [Optional Feature Systems](Optional-Feature-Systems)
- [Mission Configuration Reference](Mission-Configuration-Reference)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
