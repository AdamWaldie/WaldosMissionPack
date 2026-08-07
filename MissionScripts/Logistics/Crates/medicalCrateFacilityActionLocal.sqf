/*
 * Author: WaldoTheWarfighter
 * Installs (or removes) a simple informational interaction on a field hospital-enabled medical
 * crate. ACE Interact ("Field Hospital Info") is used when available; a vanilla addAction is
 * installed alongside it (or instead of it, on a mission without ACE) so the same information -
 * that this crate grants ACE medical's locational treatment boost - is always reachable without a
 * persistent 3D marker cluttering the world. Repeated calls reconcile a stale action instead of
 * duplicating one.
 *
 * Arguments:
 * 0: crate <OBJECT>
 * 1: enabled <BOOL> (default true) - false removes any previously installed action.
 *
 * Return Value:
 * Boolean - true once this client has processed the request.
 *
 * Example:
 * [_crate, true] remoteExec ["Waldo_fnc_MedicalCrateFacilityActionLocal", 0, _crate];
 *
 * Current callers: Waldo_fnc_MedicalCratePopulate.
 */

params [["_crate", objNull, [objNull]], ["_enabled", true]];
if (!hasInterface || {isNull _crate}) exitWith {false};

private _oldAcePath = _crate getVariable ["Waldo_FieldHospital_AceActionPath", []];
if (count _oldAcePath > 0 && {!(isNil "ace_interact_menu_fnc_removeActionFromObject")}) then {
    [_crate, 0, _oldAcePath] call ace_interact_menu_fnc_removeActionFromObject;
};
_crate setVariable ["Waldo_FieldHospital_AceActionPath", []];

private _oldVanillaId = _crate getVariable ["Waldo_FieldHospital_VanillaActionId", -1];
if (_oldVanillaId != -1) then {_crate removeAction _oldVanillaId;};
_crate setVariable ["Waldo_FieldHospital_VanillaActionId", -1];

if !(_enabled) exitWith {true};

// The ACE/vanilla callbacks below are stored and invoked later (when the player actually triggers
// the action) rather than called immediately - SQF's dynamic scoping means a private variable from
// this script's frame is not visible to them by then, so the message text is inlined into each
// callback rather than referenced from a local here.
private _icon = "\z\ACE\addons\medical_gui\ui\cross.paa";
private _infoTitle = "Field Hospital Info";

if (isClass (configFile >> "CfgPatches" >> "ace_interact_menu")) then {
    private _action = [
        "Waldo_FieldHospital_Info", _infoTitle, _icon,
        {
            params ["_target"];
            [
                "FIELD HOSPITAL",
                "This crate grants ACE medical's locational treatment boost to casualties treated nearby.",
                "INFO",
                format ["FIELD_HOSPITAL_INFO_%1", netId _target],
                6
            ] call Waldo_fnc_FeatureNotifyLocal;
        },
        {true}
    ] call ace_interact_menu_fnc_createAction;
    private _actionPath = [_crate, 0, ["ACE_MainActions"], _action] call ace_interact_menu_fnc_addActionToObject;
    _crate setVariable ["Waldo_FieldHospital_AceActionPath", _actionPath];
};

// Installed alongside ACE (not only as a fallback) - the same dual-surface policy used elsewhere
// in the pack (loadout-save points, party tables): the vanilla entry is also a useful
// discoverability cue for players who haven't opened the ACE interact menu on this crate yet.
private _vanillaId = _crate addAction [
    _infoTitle,
    {
        params ["_target"];
        [
            "FIELD HOSPITAL",
            "This crate grants ACE medical's locational treatment boost to casualties treated nearby.",
            "INFO",
            format ["FIELD_HOSPITAL_INFO_%1", netId _target],
            6
        ] call Waldo_fnc_FeatureNotifyLocal;
    },
    [], 1.5, false, true, "",
    "alive _this", 6
];
_crate setVariable ["Waldo_FieldHospital_VanillaActionId", _vanillaId];
true
