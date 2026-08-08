# Custom 3D world markers

Server-owned icon+text markers over objects or world positions, broadcast
to every client and JIP-immediate. All markers share one local `Draw3D`
handler — no per-marker permanent loop. No `MissionConfig` file — this is a
pure call API, no enable flag or config needed.

## Create or update

```sqf
[
    "generator_alpha",
    generator_1,   // anchor: object OR an ATL position
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

Calling again with the same ID updates the existing marker. Calls from a
client forward to the server automatically.

| Option | Default | Purpose |
|---|---|---|
| `text` | `""` | Accessible label drawn with the icon |
| `icon` | vanilla dot | Vanilla or mission-local PAA path |
| `colour` | WMP blue | RGBA tint — don't rely on colour alone |
| `offset` | `[0,0,0]` | Position offset from the anchor |
| `width`, `height` | `0.8` | Icon dimensions |
| `angle` | `0` | Icon rotation, degrees |
| `shadow` | `2` | Arma `drawIcon3D` shadow mode |
| `textSize` | `0.032` | Label size |
| `font` | `RobotoCondensedBold` | Arma font name |
| `align` | `"center"` | Text alignment |
| `sideArrows` | `true` | Off-screen direction arrows |
| `distance` | `75` | Max render distance, metres |
| `sides` | `["ALL"]` | Visible sides, e.g. `["WEST","GUER"]` |
| `enabled` | `true` | Temporarily hide without deleting |

## Remove

```sqf
["generator_alpha"] call Waldo_fnc_Remove3DMarker;
```

## Eden composition (beginner drop-in)

`WMP_Compositions/[WMP]Custom_3D_Marker_Example_Minimal` is a pre-placed
object with just `["signal_relay", this] call Waldo_fnc_Create3DMarker;` —
every option above at its default (text, icon, colour, distance, sides).
`_Full` shows the options HashMap set explicitly for a mission maker
learning what each key changes.

## Gotchas

- Use stable, mission-specific IDs — reusing one updates rather than
  duplicates.
- Always pair colour with meaningful text and an appropriate icon so the
  marker stays understandable for colourblind players (same accessibility
  principle as `ui-themes.md`'s colour-vision profiles).
