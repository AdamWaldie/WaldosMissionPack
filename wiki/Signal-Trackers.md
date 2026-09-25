# Signal Trackers

> **Use this page when:** one side should follow a unit or vehicle on the map without revealing the marker to the target.

A signal tracker follows its target and draws a side-private map marker. Players can plant one through ACE, Zeus can attach one to a selected object, and scripts can register one directly. The renderer starts only while a tracker exists.

## Plant a tracker

As a player, approach a unit or vehicle and choose **Plant Signal Tracker** in ACE interaction. The planting player's side sees the marker. In Zeus, place **Tracker - Attach to Selected Object** directly on the intended unit or vehicle under **WMP Electronic Warfare**. Empty-ground placement is rejected. Choose the tracking side, label and starting state in the dialog.

For a scripted mission, call:

```sqf
[enemyTruck, west, "Convoy Lead"] call Waldo_fnc_Tracker;
```

`Waldo_fnc_Tracker` accepts these arguments:

| Position | Type | Default | What to supply |
|---|---|---|---|
| 0 | Object | Required | Existing unit or vehicle to follow. |
| 1 | Side or string | `"ALL"` | `west`, `east`, `independent`, `civilian`, a recognized side name such as `"BLUFOR"`, or `"ALL"`. The server resolves an omitted side to `"ALL"`. |
| 2 | String | `"TRK-<id>"` | Text shown with the marker. Leave empty for the generated label. |
| 3 | Boolean | `true` | Whether the tracker begins active. |

The server returns a numeric tracker ID. A call made on a client forwards the request but returns `-1`, not the new ID. Run the call on the server if a later script needs that ID. The server publishes the tracker registry to joining clients; each client draws only the markers its side may see.

For a player-facing placement action, `[_target, _side, _label] call Waldo_fnc_TrackerAttach` uses the player's cursor target, side and an automatic label when arguments are omitted. Its arguments have the same object, side and string types as positions 0–2 above, and it returns no useful value.

## Remove or inspect it

Use `[enemyTruck] call Waldo_fnc_TrackerRemove` to remove by object, or pass an ID returned by a server-side creation call. The one required argument is an `OBJECT` or numeric tracker ID. The server returns `true` if it removed an entry and `false` if none matched. A client call forwards the request and returns `false` before the server finishes. WMP also removes a tracker when its target dies or someone deletes it. Markers update every few seconds and follow the target's position and facing.

## If the marker is missing

Check that the target still exists, the tracker is active, and the viewing player belongs to the chosen side. A tracker on an enemy does not give that enemy the side-private marker. In Zeus, place the module on the intended object rather than nearby empty ground.

## See also

- [EMP Burst](EMP-Burst)
- [Radio Jamming](Radio-Jamming)
- [WMP Zeus Modules](Waldos-Mission-Pack-Zeus-Modules)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
