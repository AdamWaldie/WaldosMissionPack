/*
 * Author: WaldoTheWarfighter
 * Returns normalized Obituary / confirmed-death reporting diagnostics: mission-maker config state,
 * the ACE medical/ACE interact-menu dependency the medic-only "Pronounce Dead" action needs, the
 * broadcast confirmed-death ledger (entries/version/AAR tally), and - on an interface client only -
 * whether this machine actually finished installing the action and its diary render loop.
 * Locality and authority: read-only, safe on server or client. The first two checks read only
 * broadcast/config state (Waldo_Obituary_Enable/Entries/Version/Text, Waldo_AAR_Obituary) so they
 * report identically wherever they are called from. The third check is interface-only: it reads
 * Waldo_Obituary_Started/RenderRunning, which Waldo_fnc_ObituaryInit only ever sets on the machine
 * that ran it, matching the client-local rows added by Waldo_fnc_SafeStartGetDiagnostics /
 * Waldo_fnc_ENDEXGetDiagnostics.
 *
 * Arguments: None
 * Return Value: HashMap - the Waldo_fnc_DiagnosticFeatureReport shape for area "obituary"
 * Example: [] call Waldo_fnc_ObituaryGetDiagnostics;
 * Current callers: Waldo_fnc_RunDiagnostics, Waldo_fnc_RunDiagnosticsClient.
 * Wiki: https://github.com/AdamWaldie/WaldosMissionPack/wiki/Mission-Diagnostics
 */

private _enabled = missionNamespace getVariable ["Waldo_Obituary_Enable", true];
private _aceMedical = isClass (configFile >> "CfgPatches" >> "ace_medical");
private _aceInteract = isClass (configFile >> "CfgPatches" >> "ace_interact_menu");
private _dependenciesOk = _aceMedical && _aceInteract;
private _entries = missionNamespace getVariable ["Waldo_Obituary_Entries", []];
private _version = missionNamespace getVariable ["Waldo_Obituary_Version", 0];
private _obitTally = missionNamespace getVariable ["Waldo_AAR_Obituary", []];

private _checks = [
    ["medical", "obituary-dependencies", if (!_enabled) then {"DISABLED"} else {if (_dependenciesOk) then {"LOADED"} else {"ERROR"}}, format ["enabled=%1 aceMedical=%2 aceInteractMenu=%3", _enabled, _aceMedical, _aceInteract]],
    ["medical", "obituary-ledger", if (!_enabled) then {"DISABLED"} else {if (count _entries > 0) then {"ACTIVE"} else {"LOADED"}}, format ["entries=%1 version=%2 confirmedVictims=%3 chatAnnounce=%4", count _entries, _version, count _obitTally, missionNamespace getVariable ["Waldo_Obituary_ChatAnnounce", true]]]
];

if (hasInterface) then {
    private _started = missionNamespace getVariable ["Waldo_Obituary_Started", false];
    private _rendering = missionNamespace getVariable ["Waldo_Obituary_RenderRunning", false];
    _checks pushBack ["medical", "obituary-client-action", if (!_enabled) then {"DISABLED"} else {if (!_dependenciesOk) then {"UNAVAILABLE"} else {if (_started && {_rendering}) then {"LOADED"} else {"ERROR"}}}, format ["actionInstalled=%1 diaryRenderLoop=%2", _started, _rendering]];
};

["obituary", _checks] call Waldo_fnc_DiagnosticFeatureReport
