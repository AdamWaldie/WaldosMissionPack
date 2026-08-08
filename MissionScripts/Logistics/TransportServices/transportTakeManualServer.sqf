/*
 * Author: WaldoTheWarfighter
 * Hands direct player control of a registered transport's driver seat to a crew member already
 * aboard it, suspending its AI dispatch until Waldo_fnc_TransportReleaseManualServer (or automatic
 * recovery when the manual pilot disconnects or dies) hands it back. Squad leaders keep the ability
 * to command the transport remotely through Waldo_fnc_TransportRequestServer whenever it is
 * AI-driven; this is the alternative for a player already aboard who wants to fly or drive it
 * directly instead of waiting on a remote dispatch. Both instruction sets are always available - which
 * one currently applies is just whichever machine is in the driver's seat.
 * Locality and authority: server-authoritative. Non-server calls forward themselves. The actual seat
 * swap and waypoint clearing run on the vehicle's AI-owning machine through Waldo_fnc_TransportManualLocal.
 *
 * Arguments:
 * 0: vehicle <OBJECT> - a vehicle registered by Waldo_fnc_TransportRegister.
 * 1: requester <OBJECT> - the player taking control; must already be aboard (any crew seat), or an
 *    assigned curator.
 *
 * Return Value: Boolean - true when control was handed over.
 *
 * Example:
 * [cursorObject, player] remoteExecCall ["Waldo_fnc_TransportTakeManualServer", 2];
 *
 * Current callers: the "Take Manual Control" ACE/vanilla action installed on every registered
 * transport by Waldo_fnc_TransportSetupVehicleLocal.
 * Wiki: https://github.com/AdamWaldie/WaldosMissionPack/wiki/Transport-Services
 */
params [["_vehicle", objNull, [objNull]], ["_requester", objNull, [objNull]]];
if (!isServer) exitWith {[_vehicle, _requester] remoteExecCall ["Waldo_fnc_TransportTakeManualServer", 2]; true};
if (remoteExecutedOwner > 0 && {isNull _requester || {owner _requester != remoteExecutedOwner}}) exitWith {false};
if (isNull _vehicle || {isNull _requester} || {!isPlayer _requester}) exitWith {false};
if !(missionNamespace getVariable ["Waldo_TransportServices_Enable", false]) exitWith {false};

private _id = _vehicle getVariable ["Waldo_TransportService_Id", ""];
private _services = missionNamespace getVariable ["Waldo_Transport_Services", createHashMap];
private _entry = _services getOrDefault [_id, createHashMap];
private _notify = {
    params ["_message", ["_severity", "WARNING"]];
    [_vehicle getVariable ["Waldo_TransportService_Type", "GROUND"], _message, _severity, _id] remoteExecCall ["Waldo_fnc_TransportNotifyLocal", owner _requester];
};
if (_id == "" || {_entry isEqualTo createHashMap}) exitWith {["That vehicle is not a registered transport."] call _notify; false};
private _isCurator = !isNull getAssignedCuratorLogic _requester;
if (!_isCurator && {!(_requester in crew _vehicle)}) exitWith {["You must be aboard this transport to take manual control of it."] call _notify; false};
private _state = _entry getOrDefault ["state", ""];
if (_state == "MANUAL") exitWith {
    private _pilot = driver _vehicle;
    [format ["%1 is already under manual control%2.", _entry get "name", if (isPlayer _pilot) then {format [" by %1", name _pilot]} else {""}]] call _notify;
    false
};
if (isNull driver _vehicle || {!alive driver _vehicle}) exitWith {["This transport has no living pilot to hand control from."] call _notify; false};
if (isPlayer driver _vehicle) exitWith {["This transport already has a player driver."] call _notify; false};
// The outgoing AI pilot needs a free seat to move into - refuse rather than risk ejecting them.
private _hasFreeSeat = ((_vehicle emptyPositions "cargo") > 0) || {((allTurrets [_vehicle, true]) select {(_vehicle emptyPositions _x) > 0}) isNotEqualTo []};
if (!_hasFreeSeat) exitWith {["No free seat is available for the AI pilot to move into - manual control was not taken."] call _notify; false};

private _serial = (missionNamespace getVariable ["Waldo_Transport_RequestSerial", 0]) + 1;
missionNamespace setVariable ["Waldo_Transport_RequestSerial", _serial];
_entry set ["requestId", _serial];
_vehicle setVariable ["Waldo_TransportService_RequestId", _serial, true];
_entry set ["state", "MANUAL"];
_entry set ["aiPilot", driver _vehicle];
_entry set ["manualPilotUID", getPlayerUID _requester];
private _destinationMarker = _entry getOrDefault ["destinationMarker", ""];
if (_destinationMarker != "") then {deleteMarker _destinationMarker; _entry set ["destinationMarker", ""]};
_services set [_id, _entry];
missionNamespace setVariable ["Waldo_Transport_Services", _services];
_vehicle setVariable ["Waldo_TransportService_State", "MANUAL", true];
_vehicle setVariable ["Waldo_TransportService_RequesterUID", getPlayerUID _requester, true];

["Manual control granted. Fly or drive this transport directly; use Release Manual Control on this vehicle to hand it back to its AI pilot.", "SUCCESS"] call _notify;
diag_log format ["[WMP TRANSPORT] Manual control taken: service=%1 pilot=%2", _id, name _requester];
["TAKE", _vehicle, _requester] remoteExecCall ["Waldo_fnc_TransportManualLocal", groupOwner group driver _vehicle];
true
