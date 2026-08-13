/*
 * Author: WaldoTheWarfighter
 * Installs optional, repeat-safe locality handlers for AI helicopter cruise-deceleration correction.
 * The current vehicle owner alone samples and corrects an aircraft. A Local event restarts tracking
 * after server/headless-client migration; JIP machines do not become a second authority.
 *
 * Improved Helicopter Landing always has priority. The tracker stands down for any supported landing
 * waypoint and the correction loop releases immediately if the landing controller becomes active.
 *
 * Arguments: None.
 * Return Value: BOOL - true when installed/already installed; false while disabled.
 *
 * Example: Set Waldo_HelicopterDeceleration_Enable=true in MissionConfig\aiConfig.sqf; WMP calls
 * [] call Waldo_fnc_HelicopterDecelerationInit automatically from init.sqf.
 * Current caller: init.sqf on server, interface clients and headless clients after shared settings.
 */

if !(missionNamespace getVariable ["Waldo_HelicopterDeceleration_Enable", false]) exitWith {false};
if (missionNamespace getVariable ["Waldo_HelicopterDeceleration_HandlerInstalledLocal", false]) exitWith {true};
missionNamespace setVariable ["Waldo_HelicopterDeceleration_HandlerInstalledLocal", true];

private _install = {
    params [["_aircraft", objNull, [objNull]]];
    if (isNull _aircraft) exitWith {};
    private _eligibleClass = _aircraft isKindOf "Helicopter"
        || {(missionNamespace getVariable ["Waldo_HelicopterDeceleration_IncludeVTOL", false]) && {_aircraft isKindOf "VTOL_Base_F"}};
    if (!_eligibleClass || {getNumber (configOf _aircraft >> "isUav") != 0}) exitWith {};

    if !(_aircraft getVariable ["Waldo_HelicopterDeceleration_LocalHandlerInstalled", false]) then {
        _aircraft setVariable ["Waldo_HelicopterDeceleration_LocalHandlerInstalled", true];
        _aircraft addEventHandler ["Local", {
            params ["_aircraft", "_isLocal"];
            if (_isLocal && {!(_aircraft getVariable ["Waldo_HelicopterDeceleration_TrackedLocal", false])}) then {
                _aircraft setVariable ["Waldo_HelicopterDeceleration_TrackedLocal", true];
                [_aircraft] spawn Waldo_fnc_HelicopterDecelerationTrackLocal;
            };
        }];
    };
    if (local _aircraft && {!(_aircraft getVariable ["Waldo_HelicopterDeceleration_TrackedLocal", false])}) then {
        _aircraft setVariable ["Waldo_HelicopterDeceleration_TrackedLocal", true];
        [_aircraft] spawn Waldo_fnc_HelicopterDecelerationTrackLocal;
    };
};
missionNamespace setVariable ["Waldo_HelicopterDeceleration_InstallLocal", _install];

["Helicopter", "init", {
    params ["_aircraft"];
    [_aircraft] call (missionNamespace getVariable ["Waldo_HelicopterDeceleration_InstallLocal", {}]);
}, true, [], true] call CBA_fnc_addClassEventHandler;
if (missionNamespace getVariable ["Waldo_HelicopterDeceleration_IncludeVTOL", false]) then {
    ["VTOL_Base_F", "init", {
        params ["_aircraft"];
        [_aircraft] call (missionNamespace getVariable ["Waldo_HelicopterDeceleration_InstallLocal", {}]);
    }, true, [], true] call CBA_fnc_addClassEventHandler;
};
{[_x] call _install} forEach (vehicles select {
    _x isKindOf "Helicopter"
    || {(missionNamespace getVariable ["Waldo_HelicopterDeceleration_IncludeVTOL", false]) && {_x isKindOf "VTOL_Base_F"}}
});
true

