/*
 * Author: WaldoTheWarfighter
 * Applies a defence order on the machine that owns the group: moves soldiers to their spots and holds
 * them there facing their sectors.
 *
 * Runs on the original owner and again on any new owner (Waldo_fnc_CortexDiscover), because unit
 * orders are held by the owning machine. A job stops each soldier only on arrival and points him at
 * his sector. Each soldier has an independent physical-progress watchdog: measured travel renews
 * the lease, inactivity causes a bounded forced replan, and only exhausted replans record failure.
 * Scheduler delay and temporary Zeus ownership do not consume recovery attempts.
 * Locality and authority: call where the group is local.
 *
 * Review contract: Each application resets local holding state and versions its arrival job. Old generations retire; ineligible groups receive no new movement commands.
 *
 * Arguments:
 * 0: group <GROUP>
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_group] call Waldo_fnc_CortexDefendApplyLocal;
 * Result: the defence line forms on this machine.
 *
 * Current callers: Waldo_fnc_CortexDefend and Waldo_fnc_CortexDiscover.
 */

params [["_group", grpNull, [grpNull]]];
if (isNull _group || {!local _group} || {!([_group] call Waldo_fnc_CortexIsEligible)}) exitWith {};
private _generation = (_group getVariable ["Waldo_AIPass_DefendGeneration", 0]) + 1;
_group setVariable ["Waldo_AIPass_DefendGeneration", _generation];
_group setVariable ["Waldo_AIPass_DefendApplied", true];
private _routes=[];
{
    _x setVariable ["Waldo_AIPass_DefendHolding", nil];
    _x setVariable ["Waldo_AIPass_DefendFailed",nil,true];
    private _assignment = _x getVariable ["Waldo_AIPass_DefendPos", []];
    if (alive _x && {local _x} && {!isPlayer _x} && {lifeState _x != "INCAPACITATED"} && {_assignment isNotEqualTo []}) then {
        _routes pushBack [_x,getPosATL _x,time,0];
        if (_x distance2D (_assignment select 0) > 2) then {
            _x doMove (_assignment select 0);
            _x setDestination [_assignment select 0,"LEADER PLANNED",true];
        };
    };
} forEach units _group;
[{
    params ["_job"];
    private _group = _job get "group";
    if (isNull _group || {!local _group} || {(_group getVariable ["Waldo_AIPass_Defend", []]) isEqualTo []}) exitWith {-1};
    if ((_group getVariable ["Waldo_AIPass_DefendGeneration", -1]) != (_job get "generation")) exitWith {-1};
    // External control has priority. Do not age or reissue an owned movement while Zeus is active.
    if !([_group] call Waldo_fnc_CortexIsEligible) exitWith {2};
    private _pending = 0;
    private _routes=_job get "routes";
    {
        private _unit=_x;
        private _assignment = _unit getVariable ["Waldo_AIPass_DefendPos", []];
        if (alive _unit && {local _unit} && {!isPlayer _unit} && {lifeState _unit != "INCAPACITATED"} && {_assignment isNotEqualTo []} && {!(_unit getVariable ["Waldo_AIPass_DefendHolding", false])} && {!(_unit getVariable ["Waldo_AIPass_DefendFailed",false])}) then {
            if (_unit distance2D (_assignment select 0) <= 3) then {
                doStop _unit;
                _unit doWatch ((_assignment select 0) getPos [60, _assignment select 1]);
                _unit setVariable ["Waldo_AIPass_DefendHolding", true];
            } else {
                _pending = _pending + 1;
                private _routeIndex=_routes findIf {(_x select 0) isEqualTo _unit};
                if (_routeIndex < 0) then {
                    _routes pushBack [_unit,getPosATL _unit,time,0];
                    _routeIndex=count _routes-1;
                };
                private _route=_routes select _routeIndex;
                _route params ["_routeUnit","_lastPosition","_lastProgress","_retries"];
                if (_unit distance2D _lastPosition >= 1) then {
                    _route set [1,getPosATL _unit];
                    _route set [2,time];
                } else {
                    if (time-_lastProgress >= 15) then {
                        if (_retries < 3) then {
                            _unit doMove (_assignment select 0);
                            _unit setDestination [_assignment select 0,"LEADER PLANNED",true];
                            _route set [2,time];
                            _route set [3,_retries+1];
                        } else {
                            _unit setVariable ["Waldo_AIPass_DefendFailed",true,true];
                            _pending=_pending-1;
                            diag_log format ["[WMP CORTEX] Defence arrival failed after bounded replans unit=%1 remaining=%2",_unit,_unit distance2D (_assignment select 0)];
                        };
                    };
                };
            };
        };
    } forEach units _group;
    [2, -1] select (_pending == 0)
}, createHashMapFromArray [["group", _group], ["routes",_routes], ["generation", _generation]], 1] call Waldo_fnc_CortexQueueJob;
