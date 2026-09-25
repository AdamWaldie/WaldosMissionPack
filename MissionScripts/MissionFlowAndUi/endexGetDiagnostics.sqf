/*
 * Author: WaldoTheWarfighter
 * Purpose: report the current ENDEX authority, AAR ledger, and local interface protection.
 * Locality/authority: read-only on the calling machine. Client protection is reported only
 * on interface clients; the server's own AAR counters remain server-local.
 * Repeat/JIP: repeat-safe and does not install handlers. A JIP client reads its current
 * ENDEX state after WMP's ordered state replay.
 * Arguments: none.
 * Return Value: HASHMAP - normalized diagnostic feature report.
 * Current callers: Waldo_fnc_RunDiagnostics and mission-maker diagnostic scripts.
 * Example: private _report = [] call Waldo_fnc_ENDEXGetDiagnostics;
 * Result: _report contains the current ENDEX and AAR diagnostic checks on this machine.
 */
private _active = missionNamespace getVariable ["Waldo_ENDEX_Active", false];
private _aar = missionNamespace getVariable ["Waldo_AAR_Initialised", false];
private _checks = [
    ["mission-flow", "endex-authority", if (_active) then {"ACTIVE"} else {"LOADED"}, format ["active=%1 reportDuration=%2", _active, missionNamespace getVariable ["Waldo_ENDEX_ReportDuration", 45]]],
    ["mission-flow", "aar-ledger", if (_aar) then {"ACTIVE"} else {"UNCONFIGURED"}, format ["initialised=%1 startTime=%2 KIA=%3 vehicleKIA=%4 friendlyFire=%5", _aar, missionNamespace getVariable ["Waldo_AAR_StartTime", -1], missionNamespace getVariable ["Waldo_AAR_KIA", [0,0,0,0]], missionNamespace getVariable ["Waldo_AAR_VehKIA", [0,0,0,0]], missionNamespace getVariable ["Waldo_AAR_FF", 0]]]
];

if (hasInterface) then {
    private _fired = !isNil "Waldo_PreventWeaponsFireEventHandler";
    private _protected = _fired && {!(isDamageAllowed player)};
    private _detail = format ["firedHandler=%1 damageAllowed=%2 safetyClaims=%3", _fired, isDamageAllowed player, player getVariable ["Waldo_WMPProtection_SafetyClaims", []]];
    if (_active && {!_protected}) then {_detail = [_detail, "ENDEX is active but this client's weapon-safety protection isn't in place - check the RPT for errors from Waldo_fnc_ENDEX, or rejoin."] call Waldo_fnc_DiagnosticFoldHint;};
    _checks pushBack ["mission-flow", "endex-client-protection", if (_active && {!_protected}) then {"ERROR"} else {if (_active) then {"ACTIVE"} else {"LOADED"}}, _detail];
};

["endex-aar", _checks] call Waldo_fnc_DiagnosticFeatureReport
