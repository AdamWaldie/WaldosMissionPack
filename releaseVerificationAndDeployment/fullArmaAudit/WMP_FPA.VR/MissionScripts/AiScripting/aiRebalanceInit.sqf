/*
 * Author: Waldo
 * Configures AI skill profiles once per machine and reapplies the selected profile to local AI.
 *
 * Arguments:
 * 0: mode <STRING> - DAY or NIGHT
 * 1: profile <STRING> - built-in or mission-defined profile key
 *
 * Return Value:
 * Boolean - true when the selected profile exists
 *
 * Example:
 * ["NIGHT", "PUBLIC"] call Waldo_fnc_AIRebalanceInit;
 */

params [
    ["_mode", "DAY", [""]],
    ["_profile", "LEGACY", [""]]
];
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {false};
if (!isServer && {!(missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false])}) exitWith {
    [_mode, _profile] spawn {
        params ["_mode", "_profile"];
        waitUntil {
            missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false]
            || {missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotFailed", false]}
        };
        if (missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false]) then {
            [_mode, _profile] call Waldo_fnc_AIRebalanceInit;
        };
    };
    true
};

private _defaultProfiles = createHashMapFromArray [
        ["LEGACY", createHashMapFromArray [
            ["aimingSpeed", 0.42], ["aimingAccuracy", 0.83], ["aimingShake", 0.36],
            ["spotTime", 0.80], ["spotDistance", 1.00], ["commanding", 1.00],
            ["general", 1.00], ["courage", 0.90], ["reloadSpeed", 0.90]
        ]],
        ["PUBLIC", createHashMapFromArray [
            ["aimingSpeed", 0.32], ["aimingAccuracy", 0.33], ["aimingShake", 0.56],
            ["spotTime", 0.50], ["spotDistance", 0.60], ["commanding", 0.80],
            ["general", 0.40], ["courage", 0.65], ["reloadSpeed", 0.65]
        ]],
        ["STANDARD", createHashMapFromArray [
            ["aimingSpeed", 0.45], ["aimingAccuracy", 0.40], ["aimingShake", 0.48],
            ["spotTime", 0.65], ["spotDistance", 0.70], ["commanding", 0.75],
            ["general", 0.70], ["courage", 0.75], ["reloadSpeed", 0.75]
        ]],
        ["VETERAN", createHashMapFromArray [
            ["aimingSpeed", 0.62], ["aimingAccuracy", 0.58], ["aimingShake", 0.32],
            ["spotTime", 0.85], ["spotDistance", 0.90], ["commanding", 0.90],
            ["general", 0.90], ["courage", 0.90], ["reloadSpeed", 0.90]
        ]]
    ];
private _storedProfiles = missionNamespace getVariable ["Waldo_AI_Profiles", createHashMap];
{
    if !(_x in (keys _storedProfiles)) then {_storedProfiles set [_x, _defaultProfiles get _x]};
} forEach keys _defaultProfiles;
missionNamespace setVariable ["Waldo_AI_Profiles", _storedProfiles];

_mode = toUpperANSI _mode;
_profile = toUpperANSI _profile;
private _profiles = missionNamespace getVariable ["Waldo_AI_Profiles", createHashMap];
if !(_profile in (keys _profiles)) exitWith {
    if (isServer) then {diag_log format ["[WMP AI] Unknown profile '%1'; AI rebalance was not changed.", _profile]};
    false
};

missionNamespace setVariable ["Waldo_AI_Mode", _mode, isServer];
missionNamespace setVariable ["Waldo_AI_Profile", _profile, isServer];
missionNamespace setVariable ["Waldo_AI_RebalanceActive", true, isServer];
if (isServer) then {
    missionNamespace setVariable ["Waldo_AIRebalance_Enable", true, true];
    if (remoteExecutedOwner == 0) then {
        [_mode, _profile] remoteExecCall ["Waldo_fnc_AIRebalanceInit", -2, "Waldo_AIRebalance_RuntimeInit"];
    };
};

if !(missionNamespace getVariable ["Waldo_AI_HandlerInstalled", false]) then {
    missionNamespace setVariable ["Waldo_AI_HandlerInstalled", true];
    ["CAManBase", "init", {
        params ["_unit"];
        if !(_unit getVariable ["Waldo_AI_LocalHandlerInstalled", false]) then {
            _unit setVariable ["Waldo_AI_LocalHandlerInstalled", true];
            _unit addEventHandler ["Local", {
                params ["_unit", "_isLocal"];
                if (_isLocal && {missionNamespace getVariable ["Waldo_AI_RebalanceActive", false]}) then {[_unit] call Waldo_fnc_AIApplyProfile};
            }];
        };
        if (local _unit && {!isPlayer _unit} && {toUpperANSI (missionNamespace getVariable ["Waldo_AI_ApplyMode", "BOTH"]) != "EXISTING"}) then {
            [_unit] call Waldo_fnc_AIApplyProfile;
        };
    }, true, [], true] call CBA_fnc_addClassEventHandler;
};

if (toUpperANSI (missionNamespace getVariable ["Waldo_AI_ApplyMode", "BOTH"]) != "NEW") then {
    {
        if !(_x getVariable ["Waldo_AI_LocalHandlerInstalled", false]) then {
            _x setVariable ["Waldo_AI_LocalHandlerInstalled", true];
            _x addEventHandler ["Local", {
                params ["_unit", "_isLocal"];
                if (_isLocal && {missionNamespace getVariable ["Waldo_AI_RebalanceActive", false]}) then {[_unit] call Waldo_fnc_AIApplyProfile};
            }];
        };
        if (local _x && {!isPlayer _x}) then {[_x] call Waldo_fnc_AIApplyProfile};
    } forEach allUnits;
};

if (isServer) then {diag_log format ["[WMP AI] %1 profile active in %2 mode.", _profile, _mode]};
true
