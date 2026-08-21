/*
 * Author: WaldoTheWarfighter
 * Read-only helper: reports a vehicle's exact texture-slot indices/names/current textures and every
 * named model selection its model actually exposes - the beginner-friendly answer to "what selection
 * name do I hide to visually remove this vehicle's turret?" and "which index do I recolor?". There is
 * no engine query that flags a selection as "this is a removable part" - selectionNames is simply
 * every named piece the model's original author gave it, valid or not for hiding, so this is a
 * starting point to test against the real vehicle (hidden selections can be re-shown with no lasting
 * effect), not a guaranteed "this one is a physical component" list. Never mutates anything; safe to
 * call on any machine, no server hop, no authorisation needed.
 *
 * Arguments:
 * 0: Vehicle <OBJECT> - the vehicle to inspect.
 *
 * Return Value:
 * Array [textureSlots, selectionNames, reportText, pasteReadyText]:
 *   textureSlots: Array of [index, hiddenSelectionName, currentTexture] - one per hiddenSelections[]
 *     config entry, in order (this is also the index Waldo_fnc_VehicleAppearanceApply's TEXTURE rows
 *     use). currentTexture is "" when unset (the model's original baked-in texture is in use).
 *   selectionNames: Array of every named model selection (STRING), from the live selectionNames
 *     command - the full candidate list for a SELECTION row's selector.
 *   reportText: STRING - the same data as one multi-line, hint-ready, HUMAN-READABLE report - for
 *     reading, not for pasting whole into an Eden init field or a script (it has no "current texture
 *     state" worth reproducing elsewhere the way weapon Inspect's rows do, only an illustrative pink
 *     example).
 *   pasteReadyText: STRING - just the comma-joined selection names, comment-free and safe to paste
 *     directly (e.g. into Vehicle Appearance - Register Component's Selection Name field, or a script)
 *     - this is what gets copied to the clipboard, not reportText.
 *
 * Example:
 * [cursorObject] call Waldo_fnc_VehicleAppearanceInspect;
 * hint ((cursorObject call Waldo_fnc_VehicleAppearanceInspect) select 2);
 *
 * Current caller: the ZEN "Vehicle Appearance - Inspect" module.
 */

params [["_vehicle", objNull, [objNull]]];

if (isNull _vehicle || {!(_vehicle isKindOf "AllVehicles")} || {_vehicle isKindOf "Man"}) exitWith {
    [[], [], "Not a valid vehicle to inspect.", ""]
};

private _displayName = getText (configFile >> "CfgVehicles" >> (typeOf _vehicle) >> "displayName");
private _lines = [format ["--- %1 (%2) ---", _displayName, typeOf _vehicle]];

private _hiddenSelections = getArray (configFile >> "CfgVehicles" >> (typeOf _vehicle) >> "hiddenSelections");
// getObjectTextures (not "hiddenSelectionsTextures", which does not exist) queried by explicit
// numeric index - the same indices hiddenSelections[]/Waldo_fnc_VehicleAppearanceApply's TEXTURE
// rows use - so this reads back exactly the slots this feature can set, regardless of engine version
// (the command's older unary form, current-object-only, predates 2.20's indexed selections form).
private _currentTextures = if (count _hiddenSelections > 0) then {_vehicle getObjectTextures (_hiddenSelections apply {_forEachIndex})} else {[]};
private _textureSlots = [];
if (count _hiddenSelections == 0) then {
    _lines pushBack "Texture slots: none (this vehicle has no hiddenSelections[] entries).";
} else {
    _lines pushBack "Texture slots:";
    for "_i" from 0 to ((count _hiddenSelections) - 1) do {
        private _name = _hiddenSelections select _i;
        private _current = _currentTextures param [_i, ""];
        _textureSlots pushBack [_i, _name, _current];
        _lines pushBack format ["  slot %1 (%2): %3", _i, _name, if (_current == "") then {"default"} else {_current}];
        _lines pushBack "  example row to paint this slot pink (edit the colour, or SET a texture path/procedural string instead):";
        _lines pushBack format ['  ["TEXTURE", %1, "SET", [1, 0, 1, 1]],', _i];
    };
};

private _selectionNames = selectionNames _vehicle;
private _selectionNamesText = _selectionNames joinString ", ";
_lines pushBack "";
_lines pushBack format ["Model selections (%1) - candidates for a SELECTION row's selector to HIDE/SHOW:", count _selectionNames];
_lines pushBack _selectionNamesText;

[_textureSlots, _selectionNames, (_lines joinString "\n"), _selectionNamesText]
