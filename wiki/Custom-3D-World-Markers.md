# Custom 3D World Markers

> **Use this page when:** you need JIP-safe world-space labels or icons attached to objects or positions.

_Associated Files: `MissionScripts\MissionFlowAndUi\create3DMarker.sqf`, `init3DMarkers.sqf`, `remove3DMarker.sqf`, `3DMarkerApplyDeltaLocal.sqf`, `3DMarkerRequestStateServer.sqf`, `3DMarkerReceiveStateLocal.sqf`, `zenCreate3DMarker.sqf`, `zenRemove3DMarker.sqf`, `Waldo_fnc_Create3DMarker`, `Waldo_fnc_Remove3DMarker`_


WMP can place custom icon-and-text markers directly over objects or world
positions. Markers are server-owned and immediately available to JIP players. Current clients
receive one-row create/update/remove deltas; a joining client requests one complete revisioned
snapshot. All markers share one local `Draw3D` handler, avoiding one permanent loop per marker.

## Fastest setup in Zeus

Place **WMP Mission Tools > Create Custom 3D Marker**. Drop it directly on an object when the marker
should follow that object, or place it on empty ground for a fixed marker. The dialog provides named
icons such as Objective, Warning, Infantry, Vehicle and Supply, plus readable colour, side audience,
placement, size and maximum-distance choices. An object marker defaults directly to the object's
anchor. Enable **Place above object** to derive an offset from that particular object's model bounds;
**Extra vertical offset** adds further height only when deliberately requested. You do not need to know a texture path or config
classname. The script API below remains available when a mission needs a custom image or a stable ID
that another script updates later.

Both entry points use the same renderer. Object offsets are converted with Arma's visual-time AGL
command, and fixed array anchors remain ATL/AGL because `drawIcon3D` expects PositionAGL. Do not
pre-convert an array anchor to ASL: that would add the terrain's elevation to the displayed height.
With **Place above object** off and **Extra vertical offset** at zero, the marker is locked to the
object's model origin rather than a guessed bounding-box height.

## Create or update a marker

Smallest working call — a stable ID and an anchor, everything else takes its default:

```sqf
["generator_alpha", generator_1] call Waldo_fnc_Create3DMarker;
```

The anchor can be an object or an ATL position. Calling the function again with
the same ID updates the existing marker in place. Calls made on clients are forwarded to
the server automatically.

| Position | Type | Default | What to supply |
|---:|---|---|---|
| 0 `id` | String | Auto-generated | Stable ID for later updates or removal; choose your own when another script needs to find the marker. |
| 1 `anchor` | Object or ATL position Array `[x, y, z]` | `[0,0,0]` | Object to follow or fixed position. Supply this explicitly for normal use. |
| 2 `options` | HashMap or Array of `[key, value]` pairs | Empty | Presentation settings below. |

The return value is the marker ID String, or an empty String if the server rejects an invalid
anchor. A client receives the generated/chosen ID as soon as it forwards the request; that is not
confirmation the server accepted it. Reusing an ID replaces that marker without creating another.

## Network and JIP behaviour

The server keeps the authoritative registry and a monotonically increasing revision. It sends only
the changed marker row—or the removed marker IDs—to clients already in the mission. A client that
joins later requests one `[revision, registry]` snapshot after installing its renderer. If a client
ever observes a revision gap, it requests the same snapshot again instead of applying uncertain
state. Consequently, creating 35 markers transmits 35 individual rows to current clients rather
than successively retransmitting registries containing 1, 2, 3 through 35 rows.

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

| Option | Type | Default | Purpose |
|---|---|---|---|
| `text` | String | `""` | Accessible label drawn with the icon. |
| `icon` | String (PAA texture path) | Vanilla dot icon | Vanilla or mission-local PAA path. |
| `colour` | Array of 4 numbers (RGBA, 0–1) | `[0.49,0.78,1,0.95]` | Icon/text tint; do not rely on colour alone. |
| `offset` | Array of 3 numbers (metres) | `[0,0,0]` | Exact `[sideways, forwards, vertical]` offset from an object, or `[east, north, up]` from an ATL position. |
| `width`, `height` | Number | `0.8` | Icon dimensions. |
| `angle` | Number (degrees) | `0` | Icon rotation. |
| `shadow` | Number | `2` | Arma `drawIcon3D` shadow mode. |
| `textSize` | Number | `0.032` | Label size. |
| `font` | String | `"RobotoCondensedBold"` | Arma font name. |
| `align` | String | `"center"` | Text alignment. |
| `sideArrows` | Boolean | `true` | Show off-screen direction arrows. |
| `distance` | Number (metres) | `75` | Maximum render distance. |
| `sides` | Array of side-name Strings | `["ALL"]` | Visible audiences, such as `["WEST","GUER"]`. |
| `enabled` | Boolean | `true` | Temporarily hide without deleting. |

For vanilla icon paths, use Bohemia's official
[Arma 3 CfgMarkers reference](https://community.bohemia.net/wiki/Arma_3%3A_CfgMarkers). Its **Icon
Path** column can be copied into WMP's `icon` setting. WMP draws that texture in the world rather
than creating a map marker, so the marker class name itself (for example `b_air`) is not the value
this setting needs. Bohemia's [drawIcon3D reference](https://community.bohemia.net/wiki/drawIcon3D)
documents the underlying engine texture requirements and rendering behaviour. A path from a mod is
only safe when every player has that mod; vanilla paths or mission-local `.paa` files are the most
portable choices.

## Remove a marker

### Zeus Enhanced

Place **WMP Mission Tools > Remove Custom 3D Marker** near the marker. The closest active marker is
preselected, and the dialog lists every live marker by label, stable ID and distance. Placing the
module directly on a marker's anchor object sorts that object's markers first. Removal affects only
the selected WMP world marker; it never deletes the anchor object, an Eden map marker or a Zeus map
marker.

The server rechecks the marker ID after confirmation. If another curator or script already removed
it, Zeus receives a clear warning instead of affecting another nearby marker.

### Script

Remove a marker by its stable ID:

```sqf
["generator_alpha"] call Waldo_fnc_Remove3DMarker;
```

Remove every WMP 3D marker attached to an object:

```sqf
[generator_1] call Waldo_fnc_Remove3DMarker;
```

Or remove the nearest WMP 3D marker within 50 metres of a position:

```sqf
[[1200, 800, 0], 50] call Waldo_fnc_Remove3DMarker;
```

`Waldo_fnc_Remove3DMarker` accepts a marker ID String, anchor Object or ATL position Array at
position 0 (required; an empty String is rejected). Position 1 is a Number radius in metres,
default `25`, used only for a position search and clamped to 0–10000 m. On the server it returns
`true` if it removed at least one marker and `false` if nothing matched. A valid client call returns
`true` when forwarded, before the server has searched. Removing by object removes all WMP markers
on that exact object; removing by position removes only the nearest match within the radius.

Use stable, mission-specific IDs. Always pair colour with meaningful text and
an appropriate icon so the marker remains understandable for colourblind
players.

## If a marker is missing

Check the marker ID, visible sides, maximum distance and anchor object. A deleted anchor cannot keep an object-following marker in place. When replacing a marker, reuse its ID so WMP updates the existing entry instead of leaving two labels.

## See also

- [Eden Compositions](Eden-Compositions) — the `[WMP]Custom_3D_Marker_Example` Minimal/Full pair
- [Optional Feature Systems](Optional-Feature-Systems)
- [Mission Configuration Reference](Mission-Configuration-Reference)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
