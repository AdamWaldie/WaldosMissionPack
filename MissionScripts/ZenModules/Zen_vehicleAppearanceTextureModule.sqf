/*
 * Author: WaldoTheWarfighter
 * Zeus module handler: recolors one texture slot of the vehicle the module was placed directly on, via
 * Waldo_fnc_VehicleAppearanceApply. Placement anywhere but directly on a real vehicle is rejected with
 * a notice, same convention as Waldo_fnc_ZenVehicleWeaponLoadout. The texture-slot list is discovered
 * live from the actual placed vehicle's hiddenSelections[] config array - never hand-typed, so only
 * slots that vehicle genuinely has are ever offered, and each slot's label shows its current texture.
 *
 * Solid Color mode needs no texture asset at all - it builds the value via the engine's own
 * BIS_fnc_colorRGBAtoTexture from four 0..1 sliders (the classic "pink tank" case). Custom Texture
 * Path mode accepts any bitmap path or hand-written procedural texture string for camo patterns etc.
 *
 * Arguments:
 * 0: modulePos <ARRAY> - position the curator placed the module
 * 1: objectPos <OBJECT> - the vehicle the module was dropped on
 *
 * Return Value:
 * Nothing - the dialog forwards an authorised texture-change request to the server.
 *
 * Current caller: the ZEN "Vehicle Appearance - Set Texture" module registered by
 * Waldo_fnc_ZenInitModules.
 */

if !(isClass (configFile >> "CfgPatches" >> "zen_main")) exitWith {};

params ["_modulePos", "_objectPos"];

if (isNull _objectPos || {!(_objectPos isKindOf "AllVehicles")} || {_objectPos isKindOf "Man"}) exitWith {
    ["VEHICLE APPEARANCE", "Place this module directly on the vehicle you want to recolor.", "WARNING", "VEHAPP_ZEN", 8]
        call Waldo_fnc_FeatureNotifyLocal;
};

private _hiddenSelections = getArray (configFile >> "CfgVehicles" >> (typeOf _objectPos) >> "hiddenSelections");
if (count _hiddenSelections == 0) exitWith {
    ["VEHICLE APPEARANCE", "This vehicle has no texture slots (hiddenSelections[]) to recolor.", "WARNING", "VEHAPP_ZEN", 8]
        call Waldo_fnc_FeatureNotifyLocal;
};
// getObjectTextures (not "hiddenSelectionsTextures", which does not exist), queried by explicit
// numeric index - see Waldo_fnc_VehicleAppearanceInspect for the same pattern.
private _currentTextures = _objectPos getObjectTextures (_hiddenSelections apply {_forEachIndex});
private _slotValues = [];
private _slotLabels = [];
for "_i" from 0 to ((count _hiddenSelections) - 1) do {
    private _current = _currentTextures param [_i, ""];
    _slotValues pushBack (str _i);
    _slotLabels pushBack format ["Slot %1 (%2) - %3", _i, _hiddenSelections select _i, if (_current == "") then {"default"} else {_current}];
};

[
    "Vehicle Appearance - Set Texture",
    [
        ["LIST", ["Texture Slot", "Which hiddenSelections[] slot to change."], [_slotValues, _slotLabels, 0, 6]],
        ["TOOLBOX:WIDE", ["Mode", "Solid Color needs no texture asset. Custom Texture Path accepts a bitmap path or a hand-written procedural string. Restore Default reverts the slot."], [0, 1, 3, ["Solid Color", "Custom Texture Path", "Restore Default"]]],
        ["SLIDER", ["Red", "0..1"], [0, 1, 1, 2], false],
        ["SLIDER", ["Green", "0..1"], [0, 1, 0, 2], false],
        ["SLIDER", ["Blue", "0..1"], [0, 1, 1, 2], false],
        ["SLIDER", ["Alpha", "0..1"], [0, 1, 1, 2], false],
        ["EDIT", ["Custom Texture Path", "Exact bitmap path (e.g. \\myaddon\\data\\camo.paa) or a hand-written procedural texture string."], ""]
    ],
    {
        params ["_args", "_pos"];
        _args params ["_slotKey", "_modeIndex", "_r", "_g", "_b", "_a", "_texturePath"];
        _pos params ["_vehicle"];
        if (isNull _vehicle) exitWith {
            ["VEHICLE APPEARANCE", "That vehicle no longer exists.", "WARNING", "VEHAPP_ZEN", 8] call Waldo_fnc_FeatureNotifyLocal;
        };
        private _index = parseNumber _slotKey;
        private _row = switch (_modeIndex) do {
            case 0: { ["TEXTURE", _index, "SET", [_r, _g, _b, _a]] };
            case 1: { ["TEXTURE", _index, "SET", _texturePath] };
            default { ["TEXTURE", _index, "CLEAR", ""] };
        };
        diag_log format ["[WMP ZEN] invoked module=Vehicle Appearance - Set Texture curator=%1 vehicle=%2 row=%3", name player, typeOf _vehicle, _row];
        [_vehicle, [_row], player] remoteExecCall ["Waldo_fnc_ZenVehicleAppearanceTextureServer", 2];
    },
    {},
    [_objectPos]
] call zen_dialog_fnc_create;
