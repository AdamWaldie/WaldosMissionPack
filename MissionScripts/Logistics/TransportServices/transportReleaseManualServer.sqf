/*
 * Author: WaldoTheWarfighter
 * Hands a manually-controlled transport back to its original AI pilot. Callable by the current
 * manual driver, an assigned curator, or internally with a null requester for automatic recovery
 * when the manual pilot disconnects, dies or otherwise leaves the driver's seat.
 * Locality and authority: server-authoritative. Non-server calls forward themselves. The actual seat
 * swap runs on the vehicle's AI-owning machine through Waldo_fnc_TransportManualLocal.
 *
 * Arguments:
 * 0: vehicle <OBJECT> - a vehicle registered by Waldo_fnc_TransportRegister.
 * 1: requester <OBJECT> (default objNull) - the player releasing control, or objNull for the
 *    internal automatic-recovery path (never notifies, since there is no single player to notify).
 *
 * Return Value: Boolean - true when control was handed back.
 *
 * Example:
 * [cursorObject, player] remoteExecCall ["Waldo_fnc_TransportReleaseManualServer", 2];
 *
 * Current callers: the "Release Manual Control" ACE/vanilla action installed on every registered
 * transport by Waldo_fnc_TransportSetupVehicleLocal, and Waldo_fnc_TransportMonitorServer's automatic
 * abandonment recovery.
 * Wiki: https://github.com/AdamWaldie/WaldosMissionPack/wiki/Transport-Services
 */
params [["_vehicle", objNull, [objNull]], ["_requester", objNull, [objNull]]];
if (!isServer) exitWith {[_vehicle, _requester] remoteExecCall ["Waldo_fnc_TransportReleaseManualServer", 2]; true};
if (remoteExecutedOwner > 0 && {isNull _requester || {owner _requester != remoteExecutedOwner}}) exitWith {false};
if (isNull _vehicle) exitWith {false};

private _id = _vehicle getVariable ["Waldo_TransportService_Id", ""];
private _services = missionNamespace getVariable ["Waldo_Transport_Services", createHashMap];
private _entry = _services getOrDefault [_id, createHashMap];
private _notify = {
    params ["_message", ["_severity", "WARNING"]];
    if (!isNull _requester) then {
        [_vehicle getVariable ["Waldo_TransportService_Type", "GROUND"], _message, _severity, _id] remoteExecCall ["Waldo_fnc_TransportNotifyLocal", owner _requester];
    };
};
if (_id == "" || {_entry isEqualTo createHashMap}) exitWith {["That vehicle is not a registered transport."] call _notify; false};
if ((_entry getOrDefault ["state", ""]) != "MANUAL") exitWith {["This transport is not currently under manual control."] call _notify; false};
private _isAuto = isNull _requester;
private _isCurator = !_isAuto && {!isNull getAssignedCuratorLogic _requester};
private _isCurrentPilot = !_isAuto && {driver _vehicle == _requester};
if (!_isAuto && {!_isCurator && {!_isCurrentPilot}}) exitWith {["Only the current pilot or Zeus may release manual control."] call _notify; false};

private _aiPilot = _entry getOrDefault ["aiPilot", objNull];
if (isNull _aiPilot || {!alive _aiPilot}) exitWith {
    ["The original AI pilot is no longer available; this transport remains under manual control until re-crewed."] call _notify;
    false
};
private _config = _entry get "config";
private _serial = (missionNamespace getVariable ["Waldo_Transport_RequestSerial", 0]) + 1;
missionNamespace setVariable ["Waldo_Transport_RequestSerial", _serial];
_entry set ["requestId", _serial];
_vehicle setVariable ["Waldo_TransportService_RequestId", _serial, true];
_entry set ["state", "AVAILABLE"];
_entry set ["requesterUID", ""];
_entry deleteAt "aiPilot";
_entry deleteAt "manualPilotUID";
_services set [_id, _entry];
missionNamespace setVariable ["Waldo_Transport_Services", _services];
_vehicle setVariable ["Waldo_TransportService_State", "AVAILABLE", true];
_vehicle setVariable ["Waldo_TransportService_RequesterUID", "", true];

["Manual control released back to the AI pilot.", "SUCCESS"] call _notify;
diag_log format ["[WMP TRANSPORT] Manual control released: service=%1 automatic=%2", _id, _isAuto];
["RELEASE", _vehicle, objNull, _aiPilot, _config] remoteExecCall ["Waldo_fnc_TransportManualLocal", groupOwner group driver _vehicle];
true
