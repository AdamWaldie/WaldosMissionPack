/*
 * Author: WaldoTheWarfighter
 * Installs a repeat-safe ACE detonation bridge for configurable server-side breaching profiles.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Boolean - true when installed
 *
 * Example:
 * [] call Waldo_fnc_BreachingInit;
 * Locality and authority: Installs the explosive event listener on each relevant machine;
 * the server validates and applies actual breaches. Repeated init avoids duplicate handlers;
 * joining clients install their own local listener.
 * Current caller: feature startup when breaching is enabled.
 * Result: Breaching events can be detected and forwarded for server validation.
 */

if (!isServer && {!(missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false])}) exitWith {
    [] spawn {
        waitUntil {
            missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false]
            || {missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotFailed", false]}
        };
        if (missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false]) then {[] call Waldo_fnc_BreachingInit};
    };
    true
};
if !(missionNamespace getVariable ["Waldo_Breaching_Enable", false]) exitWith {false};
if !(isClass (configFile >> "CfgPatches" >> "ace_explosives")) exitWith {
    if (isServer) then {diag_log "[WMP BREACHING] Disabled: ACE explosives is unavailable."};
    false
};
if (missionNamespace getVariable ["Waldo_Breaching_HandlerInstalled", false]) exitWith {true};

missionNamespace setVariable ["Waldo_Breaching_HandlerInstalled", true];
[{
    params ["_unit", "_range", "_explosive"];
    if !(missionNamespace getVariable ["Waldo_Breaching_Enable", false]) exitWith {true};
    if (isNull _explosive) exitWith {true};
    if (!isNull _unit && {local _unit}) then {
        [_unit, getPosWorld _explosive, typeOf _explosive] remoteExecCall ["Waldo_fnc_BreachingServerHandle", 2];
    } else {
        if (isNull _unit && {isServer}) then {
            [_unit, getPosWorld _explosive, typeOf _explosive] call Waldo_fnc_BreachingServerHandle;
        };
    };
    true
}] call ace_explosives_fnc_addDetonateHandler;
true
