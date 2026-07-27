/*
 * Author: WaldoTheWarfighter
 * Installs a deployable command post on a vehicle or static object.
 *
 * The setup is repeat-safe. The server owns deployment state, synchronized-part visibility,
 * respawn positions, markers and vehicle locking. ACE actions are installed locally on every
 * client (including JIP); vanilla actions are installed only when ACE Interact is unavailable.
 *
 * Arguments:
 * 0: target <OBJECT>
 * 1: modern construction audio <BOOL> (default false)
 * 2: enable logistics quartermaster <BOOL> (default false)
 * 3: logistics direction <NUMBER> (default 180)
 * 4: logistics distance <NUMBER> (default 4)
 *
 * Example:
 * [this, true, true, 180, 4] call Waldo_fnc_MHQSetup;
 */

params [
    ["_target", objNull, [objNull]],
    ["_constructionAudio", false, [true]],
    ["_logistics", false, [true]],
    ["_logisticsDirection", 180, [0]],
    ["_logisticsDistance", 4, [0]]
];

if (isNull _target) exitWith {false};

private _audioPath = [
    "MissionScripts\Logistics\MHQ\Audio\Audio_Deploy_Old.ogg",
    "MissionScripts\Logistics\MHQ\Audio\Audio_Deploy_New.ogg"
] select _constructionAudio;

if (isServer && {!(_target getVariable ["Waldo_MHQ_ServerConfigured", false])}) then {
    _target setVariable ["Waldo_MHQ_ServerConfigured", true, true];
    _target setVariable ["Waldo_MHQ_Status", false, true];
    _target setVariable ["Waldo_MHQ_Transition", false, true];
    _target setVariable ["Waldo_MHQ_Config", [_audioPath, _logistics], true];
    _target setVariable ["Waldo_MHQ_OriginalDamageAllowed", isDamageAllowed _target];

    private _syncLogic = objNull;
    {
        if (isNull _syncLogic && {_x isKindOf "Logic"}) then {_syncLogic = _x;};
    } forEach synchronizedObjects _target;
    // Backward compatibility for older compositions that place the helper logic
    // beside the MHQ without synchronizing it directly to the vehicle.
    if (isNull _syncLogic) then {_syncLogic = nearestObject [_target, "Logic"];};
    private _deployParts = if (isNull _syncLogic) then {[]} else {synchronizedObjects _syncLogic};
    _deployParts = _deployParts select {!isNull _x && {_x != _target}};
    _target setVariable ["Waldo_MHQ_DeployParts", _deployParts, true];

    if (!isNull _syncLogic) then {
        [_syncLogic, _target] call BIS_fnc_attachToRelative;
    };
    {
        [_x, _target] call BIS_fnc_attachToRelative;
        hideObjectGlobal _x;
    } forEach _deployParts;

    [_target, 50, -1] call Waldo_fnc_SetCargoAttributes;
    if (_logistics) then {
        _target setVariable ["Waldo_LogisticsQM_CurrentStatus", false, true];
    };
};

if (isServer) then {
    // ACE object actions are local UI state. Persist this call against the MHQ object so every
    // current client and future JIP client installs exactly one appropriate interaction surface.
    [_target, _logisticsDirection, _logisticsDistance] remoteExecCall ["Waldo_fnc_MHQSetupLocal", 0, _target];
} else {
    [_target, _logisticsDirection, _logisticsDistance] call Waldo_fnc_MHQSetupLocal;
};

true
