/*
 * Author: Waldo
 * Applies the active base, night-sensor, faction, and role skill layers to one local AI unit.
 *
 * Arguments:
 * 0: unit <OBJECT>
 *
 * Return Value:
 * Boolean - true when skills were applied
 *
 * Example:
 * [_unit] call Waldo_fnc_AIApplyProfile;
 */

params [["_unit", objNull, [objNull]]];
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {false};
if (isNull _unit || {!local _unit} || {isPlayer _unit}) exitWith {false};
if !(missionNamespace getVariable ["Waldo_AI_RebalanceActive", false]) exitWith {false};
if (_unit getVariable ["Waldo_AI_Exclude", false]) exitWith {false};

private _includedSides = missionNamespace getVariable ["Waldo_AI_IncludedSides", []];
private _includedFactions = missionNamespace getVariable ["Waldo_AI_IncludedFactions", []];
private _excludedFactions = missionNamespace getVariable ["Waldo_AI_ExcludedFactions", []];
private _excludedClasses = missionNamespace getVariable ["Waldo_AI_ExcludedClasses", []];
if (count _includedSides > 0 && {!(side group _unit in _includedSides)}) exitWith {false};
if (count _includedFactions > 0 && {!(faction _unit in _includedFactions)}) exitWith {false};
if (faction _unit in _excludedFactions || {typeOf _unit in _excludedClasses}) exitWith {false};

private _skillNames = ["aimingSpeed", "aimingAccuracy", "aimingShake", "spotTime", "spotDistance", "commanding", "general", "courage", "reloadSpeed"];
if (isNil {_unit getVariable "Waldo_AI_OriginalSkills"}) then {
    private _original = createHashMap;
    {_original set [_x, _unit skill _x]} forEach _skillNames;
    _unit setVariable ["Waldo_AI_OriginalSkills", _original];
};
if !(_unit getVariable ["Waldo_AI_LocalHandlerInstalled", false]) then {
    _unit setVariable ["Waldo_AI_LocalHandlerInstalled", true];
    _unit addEventHandler ["Local", {
        params ["_unit", "_isLocal"];
        if (_isLocal && {missionNamespace getVariable ["Waldo_AI_RebalanceActive", false]}) then {
            [_unit] call Waldo_fnc_AIApplyProfile;
        };
    }];
};

private _applySkills = {
    params ["_target", "_skills"];
    {_target setSkill [_x, ((_skills get _x) max 0) min 1]} forEach keys _skills;
};

private _profiles = missionNamespace getVariable ["Waldo_AI_Profiles", createHashMap];
private _profileKey = missionNamespace getVariable ["Waldo_AI_Profile", "LEGACY"];
private _mode = missionNamespace getVariable ["Waldo_AI_Mode", "DAY"];
[_unit, _profiles getOrDefault [_profileKey, createHashMap]] call _applySkills;

private _roleText = toUpperANSI (getText (configFile >> "CfgVehicles" >> typeOf _unit >> "textSingular"));
private _role = [_roleText, "ABCDEFGHIJKLMNOPQRSTUVWXYZ"] call BIS_fnc_filterString;

// Preserve the established night combat tiers while correcting the old inverted NVG sensing values.
if (_profileKey == "LEGACY" && {_mode == "NIGHT"}) then {
    private _eliteFactions = missionNamespace getVariable ["Waldo_AI_LegacyEliteFactions", [
        "rhs_faction_msv", "rhs_faction_rva", "rhs_faction_tv", "rhs_faction_vdv_45",
        "rhs_faction_vdv", "rhs_faction_vmf", "rhs_faction_vpvo", "rhs_faction_vv",
        "rhs_faction_vvs_c", "rhs_faction_vvs", "LIB_US_101AB", "LIB_US_82AB",
        "NORTH_FIN", "NORTH_NOR", "EAW_ROC", "EAW_ROC_Early", "EAW_ROC_Ger",
        "EAW_ROC_Southern", "EAW_ROC_West", "EAW_ROC_Winter", "LIB_UK_AB_w",
        "LIB_UK_ARMY_w", "LIB_US_ARMY_w", "IND_F", "JMSSA_britain_fact", "CSA38_GB",
        "JMSSA_britain_des_fact", "JMSSA_britain_sicily_fact", "JMSSA_britain_BEF_fact",
        "CSA38_CSA38", "CSA38_CSOB", "LIB_FFI", "LIB_GUER", "sab_nl_faction_green",
        "CSA38_PL", "CSA38_SLOV", "CSA38_spol", "LIB_UK_AB", "LIB_UK_ARMY",
        "LIB_UK_DR", "LIB_US_ARMY", "LIB_NAC", "EAW_IRA", "NORTH_SOV", "LIB_RKKA",
        "EAW_IJA", "LIB_WEHRMACHT_w", "CSA38_GERM", "JMSSA_italy_fact", "SG_STURM",
        "SG_STURMPANZER", "LIB_WEHRMACHT", "UK3CB_ADA_O", "OPTRE_Ins", "dev_flood",
        "MEU_Covenant", "OPTRE_FC_Covenant", "LM_OPCAN_FRI", "LM_OPCAN_FRI_DES",
        "LM_OPCAN_FRI_WDL", "LM_OPCAN_URA"
    ]];
    private _nightSkills = if (faction _unit in _eliteFactions) then {
        createHashMapFromArray [
            ["general", 1], ["commanding", 0.95], ["courage", 1], ["aimingSpeed", 0.72],
            ["aimingAccuracy", 0.92], ["aimingShake", 0.26], ["reloadSpeed", 1]
        ]
    } else {
        createHashMapFromArray [
            ["general", 0.9], ["commanding", 0.75], ["courage", 0.75], ["aimingSpeed", 0.62],
            ["aimingAccuracy", 0.83], ["aimingShake", 0.36], ["reloadSpeed", 0.75]
        ]
    };
    [_unit, _nightSkills] call _applySkills;

    private _legacyRoleSkills = switch (_role) do {
        case "MACHINEGUNNER": {createHashMapFromArray [["aimingSpeed", 0.82], ["aimingAccuracy", 0.82], ["aimingShake", 0.35], ["reloadSpeed", 0.8]]};
        case "SNIPER": {createHashMapFromArray [["aimingSpeed", 0.6], ["aimingAccuracy", 0.95], ["aimingShake", 0.1], ["reloadSpeed", 0.8]]};
        default {createHashMap};
    };
    [_unit, _legacyRoleSkills] call _applySkills;
};

private _factionOverrides = missionNamespace getVariable ["Waldo_AI_FactionOverrides", createHashMap];
[_unit, _factionOverrides getOrDefault [faction _unit, createHashMap]] call _applySkills;

private _roleOverrides = missionNamespace getVariable ["Waldo_AI_RoleOverrides", createHashMap];
[_unit, _roleOverrides getOrDefault [_role, createHashMap]] call _applySkills;

if (_mode == "NIGHT" && {(getLighting select 1) <= (missionNamespace getVariable ["Waldo_AI_DarknessThreshold", 5])}) then {
    private _spot = if (hmd _unit != "") then {
        missionNamespace getVariable ["Waldo_AI_NightSpotWithNVG", 0.55]
    } else {
        missionNamespace getVariable ["Waldo_AI_NightSpotWithoutNVG", 0.12]
    };
    _unit setSkill ["spotTime", _spot];
    _unit setSkill ["spotDistance", _spot];
};
private _variance = ((missionNamespace getVariable ["Waldo_AI_SkillVariance", 0]) max 0) min 0.25;
if (_variance > 0) then {
    {
        private _current = _unit skill _x;
        _unit setSkill [_x, ((_current + random [-_variance, 0, _variance]) max 0) min 1];
    } forEach _skillNames;
};
true
