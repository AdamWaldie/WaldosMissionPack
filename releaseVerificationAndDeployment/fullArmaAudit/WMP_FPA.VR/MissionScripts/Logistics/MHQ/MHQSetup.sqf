/*
 * Author: WaldoTheWarfighter, Val
 * Installs a deployable command post on a vehicle or static object.
 *
 * The setup is repeat-safe. The server owns deployment state, synchronized-part visibility,
 * respawn positions, markers and vehicle locking. ACE actions are installed locally on every
 * client (including JIP); vanilla actions are installed only when ACE Interact is unavailable.
 * Locality and authority: Safe from an Eden object Init field on every machine. The server owns
 * state/world mutation and publishes one object-keyed JIP action setup; interface clients install UI.
 *
 * Arguments:
 * 0: target <OBJECT>
 * 1: modern construction audio <BOOL> (default false)
 * 2: enable logistics quartermaster <BOOL> (default false)
 * 3: logistics direction <NUMBER> (default 180)
 * 4: logistics distance <NUMBER> (default 4)
 *
 * Return Value: Boolean - true when a non-null target was accepted.
 *
 * Example:
 * [this, true, true, 180, 4] call Waldo_fnc_MHQSetup;
 * Result: Configures this object as a repeat-safe deployable MHQ with an optional quartermaster.
 * Current callers: Eden object Init fields, compositions and mission scripts registering an MHQ.
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
    // A synchronization helper can also be linked to modules or other logic objects. Those are not
    // deployable scenery and attaching them to the MHQ can drag unrelated state graphs into the
    // vehicle hierarchy. Keep only unique physical objects and reject any object already above the
    // MHQ in an attachment chain, which would create a recursive attachment cycle.
    _deployParts = _deployParts select {!isNull _x && {_x != _target} && {!(_x isKindOf "Logic")}};
    _deployParts = _deployParts arrayIntersect _deployParts;
    _deployParts = _deployParts select {
        private _candidate = _x;
        private _cursor = _target;
        private _cycle = false;
        while {!isNull _cursor && {!_cycle}} do {
            if (_cursor isEqualTo _candidate) then {_cycle = true} else {_cursor = attachedTo _cursor};
        };
        !_cycle
    };
    _target setVariable ["Waldo_MHQ_DeployParts", _deployParts, true];

    {
        detach _x;
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
