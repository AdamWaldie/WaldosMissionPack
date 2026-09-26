/*
 * Author: WaldoTheWarfighter
 * Resolves mission switches and per-group compatibility exclusions without enabling a globally disabled feature.
 * Locality/authority: read-only on the requesting owner unless stated below.
 * Repeat/JIP: no side effects; runtime gates are read again on every call.
 * Arguments: 0: group <GROUP>, grpNull; 1: setting name <STRING>, empty; 2: fallback <BOOL>, false.
 * Return Value: Boolean.
 * Current callers: AI behaviours, convoy controller and shared passenger checks.
 * Example: [_group, "Waldo_AIPass_Reinforce_Enable", true] call Waldo_fnc_AIPassFeatureEnabled;
 */
params [["_group", grpNull, [grpNull]], ["_setting", "", [""]], ["_default", false, [true]]];
if !(missionNamespace getVariable [_setting, _default]) exitWith {false};
if (isNull _group) exitWith {true};
private _disabled = _group getVariable ["Waldo_AIPass_DisabledFeatures", []];
!(_group getVariable ["Waldo_AI_ExternalControl", false]) && {!("ALL" in _disabled)} && {!(_setting in _disabled)}
