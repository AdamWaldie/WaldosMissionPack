/*
 * Author: WaldoTheWarfighter
 * Applies a defence order on the machine that owns the group: moves soldiers to their spots and holds
 * them there facing their sectors.
 *
 * Runs on the original owner and again on any new owner (Waldo_fnc_CortexDiscover), because unit
 * orders are held by the owning machine. A job stops each soldier only on arrival, records failure after 90 seconds without arrival, and
 * points him at his sector.
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
{
    _x setVariable ["Waldo_AIPass_DefendHolding", nil];
    _x setVariable ["Waldo_AIPass_DefendFailed",nil,true];
    private _assignment = _x getVariable ["Waldo_AIPass_DefendPos", []];
    if (alive _x && {local _x} && {_assignment isNotEqualTo []} && {_x distance2D (_assignment select 0) > 2}) then {
        _x doMove (_assignment select 0);
    };
} forEach units _group;
[{
    params ["_job"];
    private _group = _job get "group";
    if (isNull _group || {!local _group} || {(_group getVariable ["Waldo_AIPass_Defend", []]) isEqualTo []}) exitWith {-1};
    if ((_group getVariable ["Waldo_AIPass_DefendGeneration", -1]) != (_job get "generation")) exitWith {-1};
    if !([_group] call Waldo_fnc_CortexIsEligible) exitWith {2};
    private _pending = 0;
    {
        private _assignment = _x getVariable ["Waldo_AIPass_DefendPos", []];
        if (alive _x && {local _x} && {_assignment isNotEqualTo []} && {!(_x getVariable ["Waldo_AIPass_DefendHolding", false])} && {!(_x getVariable ["Waldo_AIPass_DefendFailed",false])}) then {
            if (_x distance2D (_assignment select 0) <= 3) then {
                doStop _x;
                _x doWatch ((_assignment select 0) getPos [60, _assignment select 1]);
                _x setVariable ["Waldo_AIPass_DefendHolding", true];
            } else {
                if (time > (_job get "deadline")) then {
                    _x setVariable ["Waldo_AIPass_DefendFailed",true,true];
                    diag_log format ["[WMP CORTEX] Defence arrival failed unit=%1 remaining=%2",_x,_x distance2D (_assignment select 0)];
                } else {_pending = _pending + 1};
            };
        };
    } forEach units _group;
    [2, -1] select (_pending == 0)
}, createHashMapFromArray [["group", _group], ["deadline", time + 90], ["generation", _generation]], 1] call Waldo_fnc_CortexQueueJob;
