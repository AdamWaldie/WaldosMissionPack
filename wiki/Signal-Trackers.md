# Signal Trackers

> **Use this page when:** one side should follow a unit or vehicle on the map without revealing the marker to the target.

A signal tracker follows its target and draws a side-private map marker. Players can plant one through ACE, Zeus can attach one to a selected object, and scripts can register one directly. The renderer starts only while a tracker exists.

## Plant a tracker

As a player, approach a unit or vehicle and choose **Plant Signal Tracker** in ACE interaction. The planting player's side sees the marker. In Zeus, place **Tracker - Attach to Selected Object** directly on the intended unit or vehicle under **WMP Electronic Warfare**. Empty-ground placement is rejected. Choose the tracking side, label and starting state in the dialog.

For a scripted mission, call:

```sqf
[enemyTruck, west, "Convoy Lead"] call Waldo_fnc_Tracker;
```

Arguments are `[target object, tracking side, label]`. The function returns the tracker ID, which you can keep for removal. The side may be an Arma side such as `west`, a recognized side string such as `"BLUFOR"`, or `"ALL"`. `Waldo_fnc_TrackerAttach` attaches a tracker to the player's current cursor target for their side.

## Remove or inspect it

Use `[enemyTruck] call Waldo_fnc_TrackerRemove` to remove by object, or pass the returned tracker ID. WMP also removes a tracker when its target dies or someone deletes it. Markers update every few seconds and follow the target's position and facing. The server owns the tracker registry. Clients, including late joiners, draw only markers they may see.

## If the marker is missing

Check that the target still exists, the tracker is active, and the viewing player belongs to the chosen side. A tracker on an enemy does not give that enemy the side-private marker. In Zeus, place the module on the intended object rather than nearby empty ground.

## See also

- [EMP Burst](EMP-Burst)
- [Radio Jamming](Radio-Jamming)
- [WMP Zeus Modules](Waldos-Mission-Pack-Zeus-Modules)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
