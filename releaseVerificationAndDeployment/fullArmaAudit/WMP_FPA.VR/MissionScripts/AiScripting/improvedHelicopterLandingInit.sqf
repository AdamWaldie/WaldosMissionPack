/*
 * Author: WaldoTheWarfighter
 * Installs the repeat-safe event-driven handlers for improved AI helicopter landings. It mirrors
 * the AI skill system: a CBA class-init event catches editor, Zeus and scripted helicopters, while
 * an engine Local event adopts the aircraft whenever ownership migrates between server, headless
 * client and player machines. Only the owning machine runs a tracker.
 *
 * Arguments: None.
 *
 * Return Value: BOOL - true when the handlers are installed or were already present.
 *
 * Example: [] call Waldo_fnc_ImprovedHelicopterLandingInit;
 * Current caller: init.sqf on every machine, including JIP and headless clients.
 */

if (missionNamespace getVariable ["Waldo_ImprovedHelicopterLanding_HandlerInstalledLocal", false]) exitWith {true};
missionNamespace setVariable ["Waldo_ImprovedHelicopterLanding_HandlerInstalledLocal", true];

private _install = {
    params [["_helicopter", objNull, [objNull]]];
    if (isNull _helicopter || {!(_helicopter isKindOf "Helicopter")} || {getNumber (configOf _helicopter >> "isUav") != 0}) exitWith {};
    if !(_helicopter getVariable ["Waldo_ImprovedHelicopterLanding_LocalHandlerInstalled", false]) then {
        _helicopter setVariable ["Waldo_ImprovedHelicopterLanding_LocalHandlerInstalled", true];
        _helicopter addEventHandler ["Local", {
            params ["_helicopter", "_isLocal"];
            if (_isLocal && {!(_helicopter getVariable ["Waldo_ImprovedHelicopterLanding_TrackedLocal", false])}) then {
                if (_helicopter getVariable ["Waldo_ImprovedHelicopterLanding_Active", false]) then {
                    [_helicopter, false] call Waldo_fnc_ImprovedHelicopterLandingRestoreLocal;
                };
                _helicopter setVariable ["Waldo_ImprovedHelicopterLanding_TrackedLocal", true];
                [_helicopter] spawn Waldo_fnc_ImprovedHelicopterLandingTrackLocal;
            };
        }];
    };
    if (local _helicopter && {!(_helicopter getVariable ["Waldo_ImprovedHelicopterLanding_TrackedLocal", false])}) then {
        _helicopter setVariable ["Waldo_ImprovedHelicopterLanding_TrackedLocal", true];
        [_helicopter] spawn Waldo_fnc_ImprovedHelicopterLandingTrackLocal;
    };
};
missionNamespace setVariable ["Waldo_ImprovedHelicopterLanding_InstallLocal", _install];
["Helicopter", "init", {
    params ["_helicopter"];
    [_helicopter] call (missionNamespace getVariable ["Waldo_ImprovedHelicopterLanding_InstallLocal", {}]);
}, true, [], true] call CBA_fnc_addClassEventHandler;
{[_x] call _install;} forEach (vehicles select {_x isKindOf "Helicopter"});
true
