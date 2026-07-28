/*
 * Author: Waldo
 * Starts a repeat-safe local monitor for destroyed or overturned vehicle emergency exits.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Boolean - true when active or already running
 *
 * Example:
 * [] call Waldo_fnc_EmergencyDismountInit;
 */

if !(hasInterface) exitWith {false};
if !(missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", isServer]) exitWith {
    [] spawn {
        waitUntil {
            missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false]
            || {missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotFailed", false]}
        };
        if (missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false]) then {[] call Waldo_fnc_EmergencyDismountInit};
    };
    true
};
if !(missionNamespace getVariable ["Waldo_EmergencyDismount_Enable", false]) exitWith {false};
if (missionNamespace getVariable ["Waldo_EmergencyDismount_ClientStarted", false]) exitWith {true};

missionNamespace setVariable ["Waldo_EmergencyDismount_ClientStarted", true];
private _handle = [] spawn {
    while {missionNamespace getVariable ["Waldo_EmergencyDismount_ClientStarted", false]} do {
        private _vehicle = vehicle player;
        private _allowedKinds = missionNamespace getVariable ["Waldo_EmergencyDismount_AllowedKinds", ["LandVehicle", "Ship"]];
        if (_vehicle != player && {_allowedKinds findIf {_vehicle isKindOf _x} >= 0}) then {
            private _profiles = missionNamespace getVariable ["Waldo_EmergencyDismount_VehicleProfiles", createHashMap];
            private _profile = _profiles getOrDefault [typeOf _vehicle, createHashMap];
            private _setting = {
                params ["_name", "_fallback"];
                _profile getOrDefault [_name, missionNamespace getVariable [format ["Waldo_EmergencyDismount_%1", _name], _fallback]]
            };
            private _overturned = (vectorUp _vehicle select 2) < (["UpThreshold", 0.15] call _setting);
            private _destroyed = !alive _vehicle;
            private _clearExit = true;
            if (["RequireClearExit", false] call _setting) then {
                _clearExit = [objNull, "VIEW"] checkVisibility [eyePos player, AGLToASL (player modelToWorld [0, 0, 2.2])] > 0;
            };
            private _overturnState = player getVariable ["Waldo_EmergencyDismount_OverturnState", [objNull, -1]];
            if (_overturned) then {
                if ((_overturnState select 0) != _vehicle) then {
                    _overturnState = [_vehicle, diag_tickTime];
                    player setVariable ["Waldo_EmergencyDismount_OverturnState", _overturnState];
                };
            } else {
                player setVariable ["Waldo_EmergencyDismount_OverturnState", [objNull, -1]];
            };
            private _overturnDelayMet = _overturned && {diag_tickTime - (_overturnState select 1) >= (["MinimumOverturnSeconds", 1] call _setting)};
            private _shouldExit =
                (_overturnDelayMet && {_clearExit} && {["OnOverturn", true] call _setting})
                || {_destroyed && {["OnDestroyed", true] call _setting}};
            if (_shouldExit && {diag_tickTime >= (player getVariable ["Waldo_EmergencyDismount_Next", 0])}) then {
                player setVariable ["Waldo_EmergencyDismount_ActiveProfile", _profile];
                [player, _vehicle, _destroyed] spawn Waldo_fnc_EmergencyDismountExecute;
            };
        };
        sleep (missionNamespace getVariable ["Waldo_EmergencyDismount_Interval", 0.5] max 0.1);
    };
};
missionNamespace setVariable ["Waldo_EmergencyDismount_ClientLoop", _handle];
true
