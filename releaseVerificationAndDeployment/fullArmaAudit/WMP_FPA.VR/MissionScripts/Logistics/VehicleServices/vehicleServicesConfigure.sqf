/*
 * Author: WaldoTheWarfighter
 * Purpose: Queues independent ACE rearm, refuel, repair and medical vehicle roles.
 * Locality / Authority: Server-local API. Eden client copies and direct remote calls exit.
 *   ZEN authenticates its curator in ZenVehicleServicesServer before next-frame dispatch.
 * Repeat / JIP: Per-vehicle FIFO worker preserves patch order. Repeating enabled roles preserves
 *   consumed stock unless refillFuel/refillRearm is true. ACE owns action JIP replay and cleanup;
 *   public object variables persist across joins and locality migration. No WMP player actions.
 * Arguments:
 * 0: vehicle <OBJECT> (objNull) - live land vehicle, aircraft or boat; no static weapons.
 * 1: options <ARRAY of [STRING,VALUE] or HASHMAP> ([]) - omitted keys keep current settings.
 *    rearm, refuel, repair, medical <BOOL>; fuelLitres <NUMBER,1000> (-10 unlimited, or 0..1000000);
 *    rearmSupply <NUMBER,1000> (0..1000000); refillFuel, refillRearm <BOOL,false>.
 *    Amounts apply on first enable/re-enable or explicit refill. ACE global rearm mode still applies.
 * 2: reply owner <NUMBER> (-1) - internal ZEN feedback target; omitted for Eden/server scripts.
 * Return Value: <BOOL> accepted into queue, not proof of application. Last result is published as
 *   Waldo_VehicleServices_LastResult [BOOL,STRING]; Ready is true when this queue is drained.
 * Current callers: Eden object Init, server scripts, Waldo_fnc_ZenVehicleServicesServer.
 * Example: [this, [["refuel",true],["fuelLitres",2000],["repair",true]]] call Waldo_fnc_VehicleServicesConfigure;
 */
params [["_vehicle", objNull, [objNull]], ["_options", [], [[], createHashMap]], ["_replyOwner", -1, [0]]];
if (!isServer || {isRemoteExecuted} || {isNull _vehicle}) exitWith {false};
if (!alive _vehicle || {_vehicle isKindOf "StaticWeapon"}
    || {!(_vehicle isKindOf "LandVehicle" || {_vehicle isKindOf "Air"} || {_vehicle isKindOf "Ship"})}) exitWith {false};
if (isNil "CBA_fnc_execNextFrame") exitWith {false};
private _pairs = if (_options isEqualType createHashMap) then {
    private _map = _options;
    (keys _map) apply {[_x, _map get _x]}
} else {+_options};
private _queue = +(_vehicle getVariable ["Waldo_VehicleServices_Queue", []]);
_queue pushBack [_pairs, _replyOwner];
_vehicle setVariable ["Waldo_VehicleServices_Queue", _queue];
_vehicle setVariable ["Waldo_VehicleServices_Ready", false, true];
if (_vehicle getVariable ["Waldo_VehicleServices_Worker", false]) exitWith {true};
_vehicle setVariable ["Waldo_VehicleServices_Worker", true];
[{
    _this spawn {
        params ["_vehicle"];
        private _deadline = diag_tickTime + 60;
        waitUntil {
            sleep 0.1;
            isNull _vehicle || {diag_tickTime >= _deadline}
                || {time > 0 && {missionNamespace getVariable ["ace_common_settingsInitFinished", false]}}
        };
        if (isNull _vehicle) exitWith {};
        private _ready = time > 0 && {missionNamespace getVariable ["ace_common_settingsInitFinished", false]};
        // One unscheduled drain prevents two requests interleaving stock/role mutations.
        isNil {
            private _requests = _vehicle getVariable ["Waldo_VehicleServices_Queue", []];
            _vehicle setVariable ["Waldo_VehicleServices_Queue", []];
            {
                _x params ["_pairs", "_replyOwner"];
                private _result = if (_ready) then {[_vehicle, _pairs] call Waldo_fnc_VehicleServicesApplyServer}
                    else {[false, "ACE settings were not ready within 60 seconds. Retry after mission startup."]};
                _vehicle setVariable ["Waldo_VehicleServices_LastResult", _result, true];
                diag_log format ["[WMP VEHICLE SERVICES] target=%1 class=%2 requested=%3 result=%4 state=%5",
                    netId _vehicle, typeOf _vehicle, _pairs, _result, _vehicle getVariable ["Waldo_VehicleServices_State", []]];
                if (_replyOwner >= 2) then {
                    ["ACE VEHICLE SERVICES", _result select 1, ["ERROR", "SUCCESS"] select (_result select 0),
                        "VEHICLE_SERVICES", 8] remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", _replyOwner];
                };
            } forEach _requests;
            _vehicle setVariable ["Waldo_VehicleServices_Worker", false];
            _vehicle setVariable ["Waldo_VehicleServices_Ready", true, true];
        };
    };
}, [_vehicle]] call CBA_fnc_execNextFrame;
true
