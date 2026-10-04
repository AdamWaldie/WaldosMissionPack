/*
 * Author: WaldoTheWarfighter
 * Purpose: Authenticates a curator's vehicle-service request and routes it to the Eden API.
 * Locality / Authority: Server only; remote owner must own the named active curator.
 * Repeat / JIP: The shared API serializes edits and publishes state; this bridge adds no JIP entry.
 * Arguments: 0: vehicle <OBJECT> (objNull); 1: named pairs <ARRAY> ([]); 2: curator <OBJECT> (objNull).
 * Return Value: <BOOL> dispatch accepted; the shared worker sends applied/rejected feedback.
 * Current caller: Waldo_fnc_ZenVehicleServicesModule.
 * Example: [truck, [["medical",true]], player] remoteExecCall ["Waldo_fnc_ZenVehicleServicesServer", 2];
 */
params [["_vehicle", objNull, [objNull]], ["_pairs", [], [[]]], ["_curator", objNull, [objNull]]];
if (!isServer) exitWith {false};
private _replyOwner = if (isRemoteExecuted) then {remoteExecutedOwner} else {owner _curator};
if (isRemoteExecuted && {isNull _curator || {owner _curator != _replyOwner}
    || {isNull getAssignedCuratorLogic _curator}}) exitWith {false};
[{
    params ["_vehicle", "_pairs", "_replyOwner"];
    if !([_vehicle, _pairs, _replyOwner] call Waldo_fnc_VehicleServicesConfigure) then {
        if (_replyOwner >= 2) then {
            ["ACE VEHICLE SERVICES", "Select a live vehicle. People, props and static weapons are not supported.",
                "ERROR", "VEHICLE_SERVICES", 7] remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", _replyOwner];
        };
    };
}, [_vehicle, _pairs, _replyOwner]] call CBA_fnc_execNextFrame;
true
