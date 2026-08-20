/*
 * Author: WaldoTheWarfighter
 * Opens a small FAC/JTAC dialog letting a gunship's assigned controller live-adjust its loiter
 * radius and altitude, pre-filled with the aircraft's current published values.
 *
 * Locality and authority: runs only on the requesting interface client and builds a modal child
 * prompt display via Waldo_fnc_EcoCore_createZeusPromptDisplay (shared, Economy-agnostic chrome).
 * Submitting sends the new values to server authority as
 * ["id", "SET_ORBIT_PARAMS", [radius, altitude], player] remoteExecCall
 * ["Waldo_fnc_GunshipServerHandle", 2] - the exact same direct-remoteExecCall convention this
 * feature's other controller actions already use (Designate Orbit, Return for Service, Take
 * Control). Waldo_fnc_GunshipServerHandle performs the real validation and the 300m floors; this
 * dialog only collects input and never mutates gunship state itself.
 *
 * Arguments:
 * 0: gunship system id <STRING> - registered Waldo_Gunship_PublicSystems key.
 *
 * Return Value:
 * Boolean - true when the prompt was created; false without an interface, id or known system.
 *
 * Current callers: the assigned controller's "Configure Orbit" ACE/vanilla action created by
 * Waldo_fnc_GunshipSetupLocal.
 *
 * Example:
 * ["EXAMPLE_GUNSHIP"] call Waldo_fnc_GunshipPromptOrbitConfig;
 * Result: a small dialog opens showing the gunship's current radius/altitude, editable and
 * submittable back to server authority.
 */

params [["_id", "", [""]]];
if !(hasInterface) exitWith {false};
if (_id == "") exitWith {false};

private _systems = missionNamespace getVariable ["Waldo_Gunship_PublicSystems", []];
private _matches = _systems select {(_x select 0) == _id};
if (count _matches == 0) exitWith {false};
private _entry = _matches select 0;
private _callsign = _entry param [7, _id];
private _currentRadius = _entry param [12, 1500];
private _currentAltitude = _entry param [13, 700];

private _disp = ["  WALDOS MISSION PACK  |  GUNSHIP ORBIT CONFIG"] call Waldo_fnc_EcoCore_createZeusPromptDisplay;
if (isNull _disp) exitWith {false};

private _bg = _disp ctrlCreate ["RscText", -1];
_bg ctrlSetPosition [0.32, 0.32, 0.36, 0.32];
_bg ctrlSetBackgroundColor [0, 0, 0, 0.86];
_bg ctrlCommit 0;

private _title = _disp ctrlCreate ["RscText", -1];
_title ctrlSetPosition [0.34, 0.34, 0.32, 0.04];
_title ctrlSetText format ["Configure Orbit: %1", _callsign];
_title ctrlCommit 0;

private _radiusLabel = _disp ctrlCreate ["RscText", -1];
_radiusLabel ctrlSetPosition [0.34, 0.40, 0.32, 0.03];
_radiusLabel ctrlSetText "Loiter Radius (metres, minimum 300)";
_radiusLabel ctrlCommit 0;

private _radiusEdit = _disp ctrlCreate ["RscEdit", -1];
_radiusEdit ctrlSetPosition [0.34, 0.43, 0.32, 0.045];
_radiusEdit ctrlSetText str _currentRadius;
_radiusEdit ctrlCommit 0;

private _altitudeLabel = _disp ctrlCreate ["RscText", -1];
_altitudeLabel ctrlSetPosition [0.34, 0.49, 0.32, 0.03];
_altitudeLabel ctrlSetText "Orbit Altitude (metres, minimum 300)";
_altitudeLabel ctrlCommit 0;

private _altitudeEdit = _disp ctrlCreate ["RscEdit", -1];
_altitudeEdit ctrlSetPosition [0.34, 0.52, 0.32, 0.045];
_altitudeEdit ctrlSetText str _currentAltitude;
_altitudeEdit ctrlCommit 0;

private _submit = _disp ctrlCreate ["RscButtonMenu", -1];
_submit ctrlSetPosition [0.34, 0.59, 0.15, 0.045];
_submit ctrlSetText "Submit";
_submit ctrlCommit 0;

private _cancel = _disp ctrlCreate ["RscButtonMenu", -1];
_cancel ctrlSetPosition [0.51, 0.59, 0.15, 0.045];
_cancel ctrlSetText "Cancel";
_cancel ctrlCommit 0;

_disp setVariable ["Waldo_Gunship_OrbitConfigId", _id];
_disp setVariable ["Waldo_Gunship_OrbitConfigRadiusEdit", _radiusEdit];
_disp setVariable ["Waldo_Gunship_OrbitConfigAltitudeEdit", _altitudeEdit];

_submit ctrlAddEventHandler ["ButtonClick", {
    params ["_ctrl"];
    private _disp = ctrlParent _ctrl;
    private _submitId = _disp getVariable ["Waldo_Gunship_OrbitConfigId", ""];
    private _radiusEdit = _disp getVariable ["Waldo_Gunship_OrbitConfigRadiusEdit", controlNull];
    private _altitudeEdit = _disp getVariable ["Waldo_Gunship_OrbitConfigAltitudeEdit", controlNull];
    if (_submitId != "" && {!isNull _radiusEdit} && {!isNull _altitudeEdit}) then {
        private _radius = parseNumber (ctrlText _radiusEdit);
        private _altitude = parseNumber (ctrlText _altitudeEdit);
        [_submitId, "SET_ORBIT_PARAMS", [_radius, _altitude], player] remoteExecCall ["Waldo_fnc_GunshipServerHandle", 2];
    };
    [_disp] call Waldo_fnc_EcoCore_closePromptDisplayIfDedicated;
}];

_cancel ctrlAddEventHandler ["ButtonClick", {
    params ["_ctrl"];
    [ctrlParent _ctrl] call Waldo_fnc_EcoCore_closePromptDisplayIfDedicated;
}];

true
