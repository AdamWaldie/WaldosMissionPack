/*
 * Author: Waldo (Waldos Economy Systems)
 * Applies mission-maker editor/script-time configuration for Waldos Economy Systems
 * at mission start, so an economy can be set up from the editor/initServer.sqf with
 * no need to open Zeus.
 *
 * Reads (all optional, set them in initServer.sqf or a composition object's init):
 *   Waldo_Economy_ConfigString  - STRING - a full configuration captured from the Zeus
 *                                 "Export" tool. Takes precedence over a preset.
 *   Waldo_Economy_Preset        - STRING - "LOW" | "MEDIUM" | "HIGH" (a bundled preset).
 *   Waldo_Economy_PresetSides   - ARRAY  - [[sideKey, catalogKey], ...] overriding which
 *                                 faction catalogue each side gets. sideKey is
 *                                 "WEST"/"EAST"/"GUER"/"CIV"; catalogKey is
 *                                 "NATO"/"CSAT"/"AAF"/"SYNDIKAT"/"GENERIC".
 *                                 Default: [["WEST","NATO"],["EAST","CSAT"],["GUER","AAF"]].
 *   Waldo_Economy_CommitmentMode - BOOL - turn Commitment mode on/off at start.
 *
 * JIP-safe: runs on the server authority once only (guarded by a broadcast flag).
 * Every catalogue/state write it triggers is broadcast, so JIP / rejoining players
 * inherit the configured economy automatically. It performs no work on clients.
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_EcoCore_applyMakerConfig;  // called from economyInit.sqf
 */

if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
if (missionNamespace getVariable ["WaldoEcoCore_MakerConfigApplied", false]) exitWith {};
missionNamespace setVariable ["WaldoEcoCore_MakerConfigApplied", true, true];

private _applied = false;

// 1) Full unified configuration string (captured from the Zeus Export tool) - wins if set.
private _configString = missionNamespace getVariable ["Waldo_Economy_ConfigString", ""];
if ((_configString isEqualType "") && {_configString isNotEqualTo ""}) then {
    // parseSimpleArray returns [] for invalid text rather than erroring.
    private _payload = parseSimpleArray _configString;
    if ((_payload isEqualType []) && {(count _payload) > 0}) then {
        if ([_payload, "Mission Setup", false] call Waldo_fnc_EcoCore_importUnifiedSavePayload) then {
            _applied = true;
            diag_log "[WMP ECO] Applied Waldo_Economy_ConfigString.";
        } else {
            diag_log "[WMP ECO] Waldo_Economy_ConfigString was not a valid unified config payload - ignored.";
        };
    } else {
        diag_log "[WMP ECO] Waldo_Economy_ConfigString could not be parsed as a config string - ignored.";
    };
};

// 2) Bundled preset (only when no full config string was applied).
if (!_applied) then {
    private _preset = toUpper (missionNamespace getVariable ["Waldo_Economy_Preset", ""]);
    if (_preset in ["LOW", "MEDIUM", "HIGH"]) then {
        private _sides = missionNamespace getVariable ["Waldo_Economy_PresetSides", []];
        if (!(_sides isEqualType []) || {(count _sides) <= 0}) then {
            _sides = [["WEST", "NATO"], ["EAST", "CSAT"], ["GUER", "AAF"]];
        };
        private _result = [_preset, _sides, "Mission Setup"] call Waldo_fnc_EcoCore_applyPresetSelections;
        _applied = true;
        diag_log format ["[WMP ECO] Applied %1 preset. %2", _preset, _result];
    };
};

// 3) Commitment mode (independent of config source) - only when the maker set it.
if !(isNil { missionNamespace getVariable "Waldo_Economy_CommitmentMode" }) then {
    private _commit = missionNamespace getVariable ["Waldo_Economy_CommitmentMode", false];
    [_commit, false] call Waldo_fnc_EcoCore_setCommitmentModeEnabled;
    diag_log format ["[WMP ECO] Commitment mode set to %1 by mission config.", _commit];
};

// 4) Hand-authored economy file (economyConfig.sqf -> Waldo_fnc_EcoMakerSetup). Runs last so it
// can build on a preset/config string or define an economy from scratch, and place world objects.
if !(isNil "Waldo_fnc_EcoMakerSetup") then {
    call Waldo_fnc_EcoMakerSetup;
};
