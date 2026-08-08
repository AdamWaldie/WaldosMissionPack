# Tactical display

A registered world object (map board/whiteboard style, not an arbitrary
infostand) opens a proximity- and line-of-sight-gated local tactical map:
friendly units plus only enemies already known to the player's group.
Closes on destruction of the display or leaving range. "Register" pattern —
config supplies access/knowledge defaults, an object must be registered.

## Config (`MissionConfig\interfaceConfig.sqf` — player local)

```sqf
["Waldo_TacticalDisplay_AccessDistance", 4],         // metres: interaction appears within this range
["Waldo_TacticalDisplay_MaximumOpenDistance", 8],    // metres: display auto-closes beyond this
["Waldo_TacticalDisplay_MinimumKnowledge", 1.5]      // knowsAbout 0-4: contacts below this are omitted
```

## Registering (`initServer.sqf`)

```sqf
if (isServer) then {
    [mapBoard, west, 2000, true] call Waldo_fnc_TacticalDisplayRegister;
};
```

## Optional authentication gate

```sqf
private _interaction = createHashMapFromArray [
    ["enabled", true], ["challengeId", "commandinput"], ["difficulty", "standard"]
];
[mapBoard, west, 2000, true, _interaction] call Waldo_fnc_TacticalDisplayRegister;
```

Semantic default when unspecified is `commandinput / standard`; script/ZEN
setup can select `keypad` or a physical-lock bypass procedure and another
difficulty instead. Unlock state is server-authored and JIP-broadcast; with
the option disabled, access is immediate as before.

## Zeus

Registration is available via ZEN where a suitable display object is
selected — see `wiki/Optional-Feature-Extensions.md`'s tactical display
section for exact module wording if the user needs it; the script call
above is the documented reference.

## Eden composition (beginner drop-in)

`WMP_Compositions/[WMP]Tactical_Display_Example_Minimal` is a pre-placed
map board with just `[this] call Waldo_fnc_TacticalDisplayRegister;` —
side defaults to `sideUnknown` (follows the viewer), radius 2000m, known
enemies shown, no authentication gate. `_Full` shows every parameter
including the optional authentication gate set explicitly.

## Gotchas

- Use a map board/whiteboard-style object, not a generic infostand or data
  terminal — Arma can't reliably project an interactive map control onto
  arbitrary object materials, so the supported implementation uses the
  world object as an authenticated terminal that opens a normal client map
  display, not a texture-on-object map.
