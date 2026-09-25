/*
 * Author: WaldoTheWarfighter
 * Sets which fire missions a battery takes: squads' support calls, counter-battery, or both.
 *
 * "SUPPORT" guns only answer squads' fire requests (and retreat smoke screens), "COUNTER" guns only
 * answer enemy artillery, "BOTH" (the default) do either. Given a group, every artillery piece its
 * soldiers crew is set, and the group keeps the role for guns it mans later. The role is broadcast,
 * so it survives a headless-client handover.
 * Locality and authority: callable anywhere, including a gun's Eden init field.
 *
 * Arguments:
 * 0: battery <OBJECT, GROUP> - artillery vehicle or static weapon, or the group crewing it
 * 1: role <STRING> - "SUPPORT", "COUNTER" or "BOTH"
 *
 * Return Value:
 * Boolean - true when the role was set (for a group: when it crews at least one artillery piece; the
 * group keeps the role either way)
 *
 * Example:
 * [this, "COUNTER"] call Waldo_fnc_AIPassSetArtilleryRole;
 * Result: from the gun's init field, this mortar only fires counter-battery.
 *
 * Current callers: mission init fields and scripts, and the AI Orders ZEN module.
 */

params [["_battery", objNull, [objNull, grpNull]], ["_role", "BOTH", [""]]];
_role = toUpperANSI _role;
if !(_role in ["SUPPORT", "COUNTER", "BOTH"]) exitWith {false};
if (_battery isEqualType grpNull) exitWith {
    if (isNull _battery) exitWith {false};
    _battery setVariable ["Waldo_AIPass_ArtilleryRole", _role, true];
    private _guns = 0;
    {
        private _vehicle = vehicle _x;
        if (_vehicle != _x && {getNumber (configOf _vehicle >> "artilleryScanner") == 1}) then {
            _vehicle setVariable ["Waldo_AIPass_ArtilleryRole", _role, true];
            _guns = _guns + 1;
        };
    } forEach units _battery;
    _guns > 0
};
if (isNull _battery) exitWith {false};
_battery setVariable ["Waldo_AIPass_ArtilleryRole", _role, true];
true
