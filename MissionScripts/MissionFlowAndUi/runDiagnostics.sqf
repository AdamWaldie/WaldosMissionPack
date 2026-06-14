/*
 * Author: Waldo
 * Server-side configuration sanity check for mission makers. Inspects the most
 * common WMP misconfigurations (missing mods, empty loadout scrapes, invalid
 * crate/chute classnames, bad paradrop thresholds) and reports them to the RPT
 * log and to admins via systemChat. Purely diagnostic - it never changes state
 * and never throws.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Number <NUMBER> - count of warnings raised
 *
 * Example:
 * [] spawn Waldo_fnc_RunDiagnostics;
 */

if !(isServer) exitWith {};

// Wait for the mission.sqm loadout scan so the per-side arrays exist.
waitUntil { missionNamespace getVariable ["Logi_MissionScanComplete", false] };

private _warnings = 0;
private _log = {
    params ["_level", "_msg"];
    private _line = format ["[WMP DIAG] %1: %2", _level, _msg];
    diag_log _line;
    // Surface warnings to admins/host only; INFO stays in the RPT to avoid spam.
    if (_level == "WARN" && {hasInterface}) then { systemChat _line; };
};

["INFO", "Running WaldosMissionPack configuration diagnostics..."] call _log;

// 1. Required mods --------------------------------------------------------
{
    _x params ["_patch", "_name"];
    if !(isClass (configFile >> "CfgPatches" >> _patch)) then {
        ["WARN", format ["Required mod not detected: %1 (CfgPatches >> %2)", _name, _patch]] call _log;
        _warnings = _warnings + 1;
    };
} forEach [["cba_main", "CBA_A3"], ["ace_main", "ACE3"]];

// 2. Per-side loadout scrape ----------------------------------------------
// A side with playable slots but an empty scrape usually means vanilla
// loadouts were used (not ACE Arsenal) or the mission.sqm is binarized.
private _flattenReal = {
    params ["_arr"];
    private _flat = [];
    {
        if (_x isEqualType []) then { _flat append _x } else { _flat pushBack _x };
    } forEach _arr;
    _flat select { _x isEqualType "" && {_x != "" && {_x != "EMPTY"}} }
};

{
    _x params ["_side", "_suffix", "_label"];
    private _hasSlots = ({ side group _x == _side } count playableUnits) > 0;
    private _arr = missionNamespace getVariable [format ["Logi_MissionSQMArray_%1", _suffix], []];
    private _realCount = count ([_arr] call _flattenReal);
    if (_hasSlots && {_realCount == 0}) then {
        ["WARN", format ["%1 has playable units but its scraped loadout is empty. Edit unit loadouts with ACE Arsenal and disable mission binarization.", _label]] call _log;
        _warnings = _warnings + 1;
    } else {
        ["INFO", format ["%1 loadout pool: %2 unique items.", _label, _realCount]] call _log;
    };
} forEach [
    [west, "West", "BLUFOR"],
    [east, "East", "OPFOR"],
    [independent, "Ind", "INDEP"],
    [civilian, "Civ", "CIV"]
];

if (count playableUnits == 0) then {
    ["WARN", "No playable units found in the mission. The loadout/logistics system needs playable slots to populate crates."] call _log;
    _warnings = _warnings + 1;
};

// 3. Crate classnames -----------------------------------------------------
{
    _x params ["_var", "_label"];
    private _class = missionNamespace getVariable [_var, ""];
    if (_class != "" && {!isClass (configFile >> "CfgVehicles" >> _class)}) then {
        ["WARN", format ["%1 classname '%2' (%3) is not a valid CfgVehicles class.", _label, _class, _var]] call _log;
        _warnings = _warnings + 1;
    };
} forEach [
    ["Logi_SupplyBoxClass", "Supply box"],
    ["Logi_MedicalBoxClass", "Medical box"]
];

// 4. Paradrop thresholds & chutes -----------------------------------------
private _minAlt = missionNamespace getVariable ["WALDO_STATIC_MINALTITUDE", 180];
private _maxAlt = missionNamespace getVariable ["WALDO_STATIC_MAXALTITUDE", 350];
private _maxSpd = missionNamespace getVariable ["WALDO_STATIC_MAXSPEED", 310];
if (_minAlt >= _maxAlt) then {
    ["WARN", format ["Static-line WALDO_STATIC_MINALTITUDE (%1) is not below WALDO_STATIC_MAXALTITUDE (%2).", _minAlt, _maxAlt]] call _log;
    _warnings = _warnings + 1;
};
if (_maxSpd <= 0) then {
    ["WARN", format ["Static-line WALDO_STATIC_MAXSPEED (%1) should be greater than 0.", _maxSpd]] call _log;
    _warnings = _warnings + 1;
};
{
    _x params ["_var", "_label"];
    private _chute = missionNamespace getVariable [_var, ""];
    if (_chute != "" && {!isClass (configFile >> "CfgVehicles" >> _chute)}) then {
        ["WARN", format ["%1 parachute class '%2' (%3) is not a valid CfgVehicles class (mod not loaded?).", _label, _chute, _var]] call _log;
        _warnings = _warnings + 1;
    };
} forEach [
    ["WALDO_STATIC_STATICCHUTE", "Static-line"],
    ["WALDO_PARA_HALOCHUTE", "HALO"]
];

// 5. ACRE2 long-range channel arrays --------------------------------------
// Only meaningful if ACRE2 is loaded; channel arrays are populated in init.sqf.
if (isClass (configFile >> "CfgPatches" >> "acre_main")) then {
    {
        _x params ["_var", "_label"];
        private _channels = missionNamespace getVariable [_var, []];
        if (_channels isEqualTo []) then {
            ["INFO", format ["%1 LR channel array (%2) is empty or not yet set.", _label, _var]] call _log;
        };
    } forEach [
        ["Waldo_ACRE2Setup_LRChannels_BLUFOR", "BLUFOR"],
        ["Waldo_ACRE2Setup_LRChannels_OPFOR", "OPFOR"],
        ["Waldo_ACRE2Setup_LRChannels_IND", "INDEP"],
        ["Waldo_ACRE2Setup_LRChannels_CIV", "CIV"]
    ];
};

// Summary -----------------------------------------------------------------
if (_warnings == 0) then {
    ["INFO", "Diagnostics complete - no configuration issues detected."] call _log;
} else {
    private _summary = format ["[WMP DIAG] %1 configuration warning(s) raised - see RPT log for details.", _warnings];
    diag_log _summary;
    if (hasInterface) then { systemChat _summary; };
};

_warnings
