/*
 * Author: WaldoTheWarfighter
 * Installs the repeat-safe event-driven handlers for improved AI helicopter landings. It mirrors
 * the AI skill system: a CBA class-init event catches editor, Zeus and scripted helicopters, while
 * client and player machines. On the server, every non-UAV helicopter is excluded from automatic
 * ACE/WMP headless-client transfer before its crew is considered for balancing. Dedicated testing
 * showed airborne helicopters losing stable flight immediately after an ACE `setGroupOwner`
 * transition, before this landing controller ever activated. Keeping the aircraft group on the
 * server avoids that engine/locality transition while still allowing WMP AI skill values to be
 * applied to its crew. Only the machine owning an aircraft runs its tracker.
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
    // ACE Headless checks this public vehicle flag before every automatic transfer. Set it on the
    // aircraft itself so it is already effective when an empty helicopter receives crew later.
    // The server is authoritative for this compatibility boundary; clients only install locality
    // handlers and never publish competing values.
    if (isServer) then {
        _helicopter setVariable ["acex_headless_blacklist", true, true];
        _helicopter setVariable ["Waldo_Headless_HelicopterPinned", true, true];
        {
            private _crewGroup = group _x;
            if !(isNull _crewGroup) then {
                _crewGroup setVariable ["Waldo_Headless_ExcludeGroup", true, true];
                _crewGroup setVariable ["acex_headless_blacklist", true, true];
            };
        } forEach crew _helicopter;
    };
    if !(_helicopter getVariable ["Waldo_ImprovedHelicopterLanding_LocalHandlerInstalled", false]) then {
        _helicopter setVariable ["Waldo_ImprovedHelicopterLanding_LocalHandlerInstalled", true];
        if (isNil {_helicopter getVariable "Waldo_ImprovedHelicopterLanding_GroundAnchored"}) then {
            _helicopter setVariable ["Waldo_ImprovedHelicopterLanding_GroundAnchored", false, true];
        };
        if (isNil {_helicopter getVariable "Waldo_ImprovedHelicopterLanding_ControlRevision"}) then {
            _helicopter setVariable ["Waldo_ImprovedHelicopterLanding_ControlRevision", 0, true];
        };
        _helicopter addEventHandler ["Local", {
            params ["_helicopter", "_isLocal"];
            if (!_isLocal) then {
                // This flag is deliberately machine-local. Clear it immediately so a rapid return
                // to this machine cannot race the old tracker's scheduled loop cleanup.
                _helicopter setVariable ["Waldo_ImprovedHelicopterLanding_TrackedLocal", false];
            };
            if (_isLocal && {!(_helicopter getVariable ["Waldo_ImprovedHelicopterLanding_TrackedLocal", false])}) then {
                if (_helicopter getVariable ["Waldo_ImprovedHelicopterLanding_Active", false]) then {
                    [_helicopter, false, "", true] call Waldo_fnc_ImprovedHelicopterLandingRestoreLocal;
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
