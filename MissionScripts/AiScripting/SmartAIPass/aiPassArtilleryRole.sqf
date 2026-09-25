/*
 * Author: WaldoTheWarfighter
 * Returns which fire missions a battery takes: squads' support calls, counter-battery, or both.
 *
 * Read from the battery's Waldo_AIPass_ArtilleryRole, then its gun crew's group, then
 * Waldo_AIPass_Artillery_DefaultRole (default "BOTH"). Set it with Waldo_fnc_AIPassSetArtilleryRole,
 * from the gun's init field, or with the AI Orders Zeus module.
 * Locality and authority: read-only; callable anywhere.
 *
 * Arguments:
 * 0: battery <OBJECT> - artillery vehicle or static weapon
 * 1: mission <STRING> (optional, default: "") - "SUPPORT" or "COUNTER" to test that mission instead
 *
 * Return Value:
 * String - "SUPPORT", "COUNTER" or "BOTH"; or, when a mission is given, Boolean - true when the
 * battery takes that mission
 *
 * Example:
 * if ([_gun, "COUNTER"] call Waldo_fnc_AIPassArtilleryRole) then {...};
 * Result: only guns allowed to do counter-battery answer enemy artillery.
 *
 * Current callers: Waldo_fnc_AIPassArtilleryRequest, Waldo_fnc_AIPassCounterBattery and
 * Waldo_fnc_AIPassRetreat.
 */

params [["_battery", objNull, [objNull]], ["_mission", "", [""]]];
private _default = toUpperANSI (missionNamespace getVariable ["Waldo_AIPass_Artillery_DefaultRole", "BOTH"]);
private _role = toUpperANSI (_battery getVariable ["Waldo_AIPass_ArtilleryRole",
    (group gunner _battery) getVariable ["Waldo_AIPass_ArtilleryRole", _default]]);
if !(_role in ["SUPPORT", "COUNTER", "BOTH"]) then {_role = "BOTH"};
if (_mission == "") exitWith {_role};
_role == "BOTH" || {_role == toUpperANSI _mission}
