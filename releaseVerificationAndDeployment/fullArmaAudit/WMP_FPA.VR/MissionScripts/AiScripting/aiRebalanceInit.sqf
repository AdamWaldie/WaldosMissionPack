/*
 * Author: WaldoTheWarfighter
 * Configures AI skill profiles once per machine and applies the selected profile to local AI.
 *
 * Existing local AI are processed immediately. A CBA CAManBase init handler catches newly created
 * units, including Zeus placements, and a per-unit Local event handler reapplies the active profile
 * after server/headless-client ownership changes. Players are never modified. WMP Line is the
 * default baseline; its established values are intentionally retained rather than made harder.
 * Locality and authority: run on every AI-owning machine. Server/JIP runtime state selects the
 * profile; each server or headless-client owner applies skills only to its local AI.
 *
 * Arguments:
 * 0: mode <STRING> - DAY or NIGHT
 * 1: profile <STRING> - built-in or mission-defined profile key (default LINE)
 *
 * Return Value:
 * Boolean - true when the selected profile exists
 *
 * Example:
 * ["NIGHT", "LINE"] call Waldo_fnc_AIRebalanceInit;
 * Result: eligible existing and newly local AI use WMP Line's low-light skill values.
 *
 * Current callers: AITweak startup wrapper, AI ZEN runtime control and JIP runtime replay.
 */

params [
    ["_mode", "DAY", [""]],
    ["_profile", "LINE", [""]]
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
            ["aimingSpeed", 0.35], ["aimingAccuracy", 0.20], ["aimingShake", 0.38],
            ["spotTime", 0.45], ["spotDistance", 0.55], ["commanding", 0.65],
            ["general", 0.60], ["courage", 0.65], ["reloadSpeed", 0.65]
        ]],
        ["MILITIA", createHashMapFromArray [
            ["aimingSpeed", 0.35], ["aimingAccuracy", 0.20], ["aimingShake", 0.38],
            ["spotTime", 0.45], ["spotDistance", 0.55], ["commanding", 0.65],
            ["general", 0.60], ["courage", 0.65], ["reloadSpeed", 0.65]
        ]],
        ["STANDARD", createHashMapFromArray [
            ["aimingSpeed", 0.48], ["aimingAccuracy", 0.30], ["aimingShake", 0.52],
            ["spotTime", 0.62], ["spotDistance", 0.70], ["commanding", 0.75],
            ["general", 0.72], ["courage", 0.78], ["reloadSpeed", 0.78]
        ]],
        ["LINE", createHashMapFromArray [
            ["aimingSpeed", 0.48], ["aimingAccuracy", 0.30], ["aimingShake", 0.52],
            ["spotTime", 0.62], ["spotDistance", 0.70], ["commanding", 0.75],
            ["general", 0.72], ["courage", 0.78], ["reloadSpeed", 0.78]
        ]],
        ["VETERAN", createHashMapFromArray [
            ["aimingSpeed", 0.62], ["aimingAccuracy", 0.42], ["aimingShake", 0.65],
            ["spotTime", 0.78], ["spotDistance", 0.84], ["commanding", 0.88],
            ["general", 0.88], ["courage", 0.90], ["reloadSpeed", 0.88]
        ]],
        ["ELITE", createHashMapFromArray [
            ["aimingSpeed", 0.72], ["aimingAccuracy", 0.52], ["aimingShake", 0.76],
            ["spotTime", 0.88], ["spotDistance", 0.92], ["commanding", 0.95],
            ["general", 0.95], ["courage", 0.96], ["reloadSpeed", 0.94]
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

missionNamespace setVariable ["Waldo_AIRebalance_Mode", _mode, isServer];
missionNamespace setVariable ["Waldo_AIRebalance_Profile", _profile, isServer];
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
