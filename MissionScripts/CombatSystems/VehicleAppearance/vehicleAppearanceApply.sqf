/*
 * Author: WaldoTheWarfighter
 * Recolors a vehicle (via its config-declared hiddenSelections texture slots) and/or shows/hides a
 * named model selection - custom vehicle appearance without hand-writing setObjectTextureGlobal/
 * hideSelection calls. A genuinely separate Arma system from weapon/ammo content
 * (Waldo_fnc_VehicleWeaponLoadoutApply): this is cosmetic model state only, never touches turrets,
 * magazines or pylons. No MissionConfig file; this is a call/ZEN-only feature. Server-authoritative -
 * callable from an object's own Eden init field with no isServer wrapper, same convention as
 * Waldo_fnc_Jammer/Waldo_fnc_VehicleWeaponLoadoutApply.
 *
 * There is no engine query for "what textures fit this selection" (same epistemic gap
 * Waldo_fnc_VehicleWeaponLoadoutApply documents for weapon/magazine classnames) - a texture value is
 * either an arbitrary bitmap path, or the built-in procedural syntax
 * "#(rgb,8,8,3)color(R,G,B,A)" for a flat solid colour with no texture asset required at all (a "pink
 * tank" needs nothing but this string - confirmed against Bohemia's own Procedural Textures page).
 * Passing an [R,G,B,A] ARRAY instead of a STRING is converted automatically via the engine's own
 * BIS_fnc_colorRGBAtoTexture, so a mission maker never has to hand-write the procedural syntax.
 *
 * Arguments:
 * 0: Vehicle <OBJECT>
 * 1: Rows <ARRAY> - each row: [targetType, selector, action, value]
 *      targetType "TEXTURE": selector <NUMBER> - 0-based index into this vehicle's own
 *        hiddenSelections[] config array (discover with
 *        getArray (configFile >> "CfgVehicles" >> typeOf vehicle >> "hiddenSelections")).
 *        action "SET": value <STRING texture path/procedural texture, or ARRAY [R,G,B,A]>.
 *        action "CLEAR": value ignored - reverts that slot to the vehicle's own default texture.
 *      targetType "SELECTION": selector <STRING> - a named model selection, validated against
 *        selectionNames vehicle (the live, authoritative list of selections that model exposes).
 *        action "HIDE" or "SHOW": value ignored.
 *
 * Return Value:
 * Array [[ok, detail], ...] - one entry per row, in order. A bad row (out-of-range texture index,
 * unknown selection name, unknown targetType/action) is reported per-row and never blocks the others.
 *
 * Example:
 * // Paint slot 0 pink using the built-in solid-colour syntax, no texture asset needed:
 * [this, [["TEXTURE", 0, "SET", [1, 0, 1, 1]]]] call Waldo_fnc_VehicleAppearanceApply;
 * // Hide a named turret-cupola model selection (find real names with Vehicle Appearance - Inspect):
 * [this, [["SELECTION", "turret_base", "HIDE", ""]]] call Waldo_fnc_VehicleAppearanceApply;
 *
 * Current callers: mission-maker vehicle init fields, scripts, Waldo_fnc_VehicleComponentRemove, and
 * the ZEN "Vehicle Appearance - Set Texture" / "Vehicle Appearance - Remove/Restore Component"
 * modules (via their respective curator-authenticated server bridges).
 */

params [["_vehicle", objNull, [objNull]], ["_rows", [], [[]]]];

// Same AllVehicles-minus-Man gate as Waldo_fnc_VehicleWeaponLoadoutApply - Man also inherits from
// AllVehicles in Arma 3's own CfgVehicles tree, so it must be excluded explicitly.
if (isNull _vehicle || {!(_vehicle isKindOf "AllVehicles")} || {_vehicle isKindOf "Man"}) exitWith {
    diag_log "[WMP VEHAPP] Waldo_fnc_VehicleAppearanceApply called with an invalid vehicle - ignored.";
    []
};

if !(isServer) exitWith {
    [_vehicle, _rows] remoteExec ["Waldo_fnc_VehicleAppearanceApply", 2];
    []
};

private _hiddenSelections = getArray (configFile >> "CfgVehicles" >> (typeOf _vehicle) >> "hiddenSelections");
private _liveSelections = selectionNames _vehicle;

private _results = [];
{
    _x params [["_targetType", "", [""]], ["_selector", "", [0, ""]], ["_action", "", [""]], ["_value", "", [0, "", []]]];
    private _ok = false;
    private _detail = "";
    switch (toUpperANSI _targetType) do {
        case "TEXTURE": {
            private _index = if (_selector isEqualType 0) then {round _selector} else {-1};
            if (_index < 0 || {_index >= count _hiddenSelections}) then {
                _detail = format ["texture index %1 out of range (vehicle has %2 hiddenSelections slot(s))", _selector, count _hiddenSelections];
            } else {
                switch (toUpperANSI _action) do {
                    case "CLEAR": {
                        _vehicle setObjectTextureGlobal [_index, ""];
                        _ok = true;
                        _detail = format ["cleared texture slot %1 to default", _index];
                    };
                    case "SET": {
                        private _texture = if (_value isEqualType []) then {
                            if (count _value == 4) then {_value call BIS_fnc_colorRGBAtoTexture} else {""}
                        } else {_value};
                        if (_texture == "") then {
                            _detail = "SET requires a texture path/procedural string or a valid [R,G,B,A] colour array";
                        } else {
                            _vehicle setObjectTextureGlobal [_index, _texture];
                            _ok = true;
                            _detail = format ["set texture slot %1 to %2", _index, _texture];
                        };
                    };
                    default { _detail = format ["unknown TEXTURE action '%1' (expected SET or CLEAR)", _action]; };
                };
            };
        };
        case "SELECTION": {
            private _name = if (_selector isEqualType "") then {_selector} else {""};
            if (_name == "" || {!(_name in _liveSelections)}) then {
                _detail = format ["selection '%1' not found on this vehicle's model - check selectionNames or Vehicle Appearance - Inspect", _selector];
            } else {
                switch (toUpperANSI _action) do {
                    case "HIDE": { _vehicle hideSelection [_name, true]; _ok = true; _detail = format ["hid selection '%1'", _name]; };
                    case "SHOW": { _vehicle hideSelection [_name, false]; _ok = true; _detail = format ["restored selection '%1'", _name]; };
                    default { _detail = format ["unknown SELECTION action '%1' (expected HIDE or SHOW)", _action]; };
                };
            };
        };
        default { _detail = format ["unknown targetType '%1' (expected TEXTURE or SELECTION)", _targetType]; };
    };
    _results pushBack [_ok, _detail];
} forEach _rows;

diag_log format ["[WMP VEHAPP] vehicle=%1 rows=%2 results=%3", typeOf _vehicle, count _rows, _results];
_results
