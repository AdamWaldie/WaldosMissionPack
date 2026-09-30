/*
 * Author: WaldoTheWarfighter
 * Applies a garrison order on the machine that owns the group: moves soldiers to their positions,
 * locks them there, and installs the duck-under-fire handlers.
 *
 * disableAI and event handlers exist only on the machine that set them, so this runs on the original
 * owner and again on any new owner (Waldo_fnc_CortexDiscover). Soldiers more than 2 m from their
 * position are sent there. Only three-dimensional arrival locks PATH; a 90-second timeout records failure and leaves movement enabled.
 * Routes approach the building entrance first. Twelve seconds without two metres of progress
 * retries the move at most three times, including commands still reporting MOVE. A replacement
 * order or locality change retires the old job; the new owner rebuilds its local route.
 * Handlers: Suppressed and Hit drop the soldier to a lower stance for 4-8 s, then restore the stance
 * he held when the order was applied only if the Cortex duck stance still remains.
 * Later stance changes are preserved. Handlers do nothing after release or Zeus takeover.
 * Locality and authority: call where the group is local.
 *
 * Review contract: Arrival jobs carry a local generation token, so replacing an order retires older work. PATH restoration is recorded publicly only when this pass disables it.
 *
 * Arguments:
 * 0: group <GROUP>
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_group] call Waldo_fnc_CortexGarrisonApplyLocal;
 * Result: the garrison is live on this machine.
 *
 * Current callers: Waldo_fnc_CortexGarrison and Waldo_fnc_CortexDiscover.
 */

params [["_group", grpNull, [grpNull]]];
if (isNull _group || {!local _group} || {!([_group] call Waldo_fnc_CortexIsEligible)}) exitWith {};
private _generation = (_group getVariable ["Waldo_AIPass_GarrisonGeneration", 0]) + 1;
_group setVariable ["Waldo_AIPass_GarrisonGeneration", _generation];
_group setVariable ["Waldo_AIPass_GarrisonApplied", true];
private _routes = createHashMap;
{
    private _unit = _x;
    private _assignment = _unit getVariable ["Waldo_AIPass_GarrisonPos", []];
    if (alive _unit && {local _unit} && {!isPlayer _unit} && {lifeState _unit != "INCAPACITATED"} && {_assignment isNotEqualTo []}) then {
        _unit setVariable ["Waldo_AIPass_GarrisonFailed",nil,true];
        if (isNil {_unit getVariable "Waldo_AIPass_GarrisonStance"}) then {_unit setVariable ["Waldo_AIPass_GarrisonStance", unitPos _unit, true]};
        if (_unit getVariable ["Waldo_AIPass_GarrisonDisabledPath", false]) then {_unit enableAI "PATH"};
        if !(_unit getVariable ["Waldo_AIPass_GarrisonHandlers", false]) then {
            _unit setVariable ["Waldo_AIPass_GarrisonHandlers", true];
            private _duck = {
                params ["_unit"];
                if (!local _unit || {isPlayer _unit} || {lifeState _unit == "INCAPACITATED"} || {(_unit getVariable ["Waldo_AIPass_GarrisonPos", []]) isEqualTo []}
                    || {!([group _unit] call Waldo_fnc_CortexIsEligible)}) exitWith {};
                if (time < (_unit getVariable ["Waldo_AIPass_DuckUntil", -1])) exitWith {};
                private _until = time + 4 + random 4;
                _unit setVariable ["Waldo_AIPass_DuckUntil", _until];
                private _duckStance=["MIDDLE", "DOWN"] select ((unitPos _unit) == "MIDDLE");
                _unit setVariable ["Waldo_Cortex_GarrisonDuckStance",_duckStance,true];
                _unit setUnitPos _duckStance;
                [{
                    params ["_unit", "_until"];
                    if (alive _unit && {local _unit} && {!isPlayer _unit} && {lifeState _unit != "INCAPACITATED"} && {(_unit getVariable ["Waldo_AIPass_DuckUntil", -1]) == _until}
                        && {(_unit getVariable ["Waldo_AIPass_GarrisonPos", []]) isNotEqualTo []}
                        && {[group _unit] call Waldo_fnc_CortexIsEligible}) then {
                        if (unitPos _unit == (_unit getVariable ["Waldo_Cortex_GarrisonDuckStance", ""])) then {
                            _unit setUnitPos (_unit getVariable ["Waldo_AIPass_GarrisonStance", "AUTO"]);
                        };
                        _unit setVariable ["Waldo_Cortex_GarrisonDuckStance",nil,true];
                    };
                }, [_unit, _until], _until - time] call CBA_fnc_waitAndExecute;
            };
            _unit setVariable ["Waldo_AIPass_GarrisonHandlerIds", [
                ["Suppressed", _unit addEventHandler ["Suppressed", _duck]],
                ["Hit", _unit addEventHandler ["Hit", _duck]]
            ]];
        };
        // Release from the former formation command before assigning an individual building slot.
        // Defence release issues doFollow; clear that formation task before issuing the new move.
        doStop _unit;
        private _destination = _assignment select 0;
        private _building = _assignment param [2,objNull];
        private _entry = if (isNull _building) then {[]} else {_building buildingExit 0};
        private _approach = count _entry >= 3 && {_entry distance2D _destination < 50} && {_unit distance2D _entry > 5};
        private _target = [_destination,_entry] select _approach;
        _routes set [netId _unit,[_target,_approach,getPosATL _unit,time,0]];
        if (_unit distance _destination > 2) then {_unit doMove _target};
    };
} forEach units _group;
[{
    params ["_job"];
    private _group = _job get "group";
    if (isNull _group || {!local _group} || {(_group getVariable ["Waldo_AIPass_Garrison", []]) isEqualTo []}) exitWith {-1};
    if ((_group getVariable ["Waldo_AIPass_GarrisonGeneration", -1]) != (_job get "generation")) exitWith {-1};
    if !([_group] call Waldo_fnc_CortexIsEligible) exitWith {2};
    private _pending = 0;
    {
        private _assignment = _x getVariable ["Waldo_AIPass_GarrisonPos", []];
        // A temporarily unconscious member keeps a pending route until the order deadline.
        // Recovery before then resumes naturally without issuing movement while incapacitated.
        if (alive _x && {local _x} && {!isPlayer _x} && {lifeState _x == "INCAPACITATED"}
            && {_assignment isNotEqualTo []} && {time <= (_job get "deadline")}) then {
            _pending=_pending+1;
        };
        if (alive _x && {local _x} && {!isPlayer _x} && {lifeState _x != "INCAPACITATED"} && {_assignment isNotEqualTo []} && {_x checkAIFeature "PATH"} && {!(_x getVariable ["Waldo_AIPass_GarrisonFailed",false])}) then {
            [_x,_assignment param [2,objNull]] call Waldo_fnc_CortexBuildingDoor;
            if (_x distance (_assignment select 0) <= 2) then {
                doStop _x;
                _x setVariable ["Waldo_AIPass_GarrisonDisabledPath", true, true];
                _x disableAI "PATH";
                _x doWatch ((_assignment select 0) getPos [50, _assignment select 1]);
            } else {
                if (time > (_job get "deadline")) then {
                    _x setVariable ["Waldo_AIPass_GarrisonFailed",true,true];
                    diag_log format ["[WMP CORTEX] Garrison arrival failed unit=%1 remaining=%2",_x,_x distance (_assignment select 0)];
                } else {
                    _pending = _pending + 1;
                    private _route = (_job get "routes") getOrDefault [netId _x,[_assignment select 0,false,getPosATL _x,time,0]];
                    _route params ["_target","_approach","_lastPosition","_lastProgress","_retries"];
                    if (_approach && {_x distance2D _target <= 5}) then {
                        _route set [0,_assignment select 0]; _route set [1,false];
                        _route set [2,getPosATL _x]; _route set [3,time];
                        doStop _x; _x doMove (_assignment select 0);
                    } else {
                        if (_x distance2D _lastPosition >= 2) then {
                            _route set [2,getPosATL _x]; _route set [3,time];
                        } else {
                            if (time-_lastProgress >= 12 && {_retries < 3}) then {
                                doStop _x; _x doMove _target;
                                _route set [3,time]; _route set [4,_retries+1];
                            };
                        };
                    };
                    (_job get "routes") set [netId _x,_route];
                };
            };
        };
    } forEach units _group;
    [2, -1] select (_pending == 0)
}, createHashMapFromArray [["group", _group], ["routes",_routes], ["deadline", time + 90], ["generation", _generation]], 1] call Waldo_fnc_CortexQueueJob;
