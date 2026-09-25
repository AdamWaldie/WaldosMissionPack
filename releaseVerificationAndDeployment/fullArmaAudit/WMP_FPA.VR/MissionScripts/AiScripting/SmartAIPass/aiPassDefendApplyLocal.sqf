/*
 * Author: WaldoTheWarfighter
 * Applies a defence order on the machine that owns the group: moves soldiers to their spots and holds
 * them there facing their sectors.
 *
 * Runs on the original owner and again on any new owner (Waldo_fnc_AIPassDiscover), because unit
 * orders are held by the owning machine. A job stops each soldier on arrival (or after 90 s) and
 * points him at his sector.
 * Locality and authority: call where the group is local.
 *
 * Arguments:
 * 0: group <GROUP>
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_group] call Waldo_fnc_AIPassDefendApplyLocal;
 * Result: the defence line forms on this machine.
 *
 * Current callers: Waldo_fnc_AIPassDefend and Waldo_fnc_AIPassDiscover.
 */

params [["_group", grpNull, [grpNull]]];
if (isNull _group || {!local _group}) exitWith {};
_group setVariable ["Waldo_AIPass_DefendApplied", true];
{
    private _assignment = _x getVariable ["Waldo_AIPass_DefendPos", []];
    if (alive _x && {local _x} && {_assignment isNotEqualTo []} && {_x distance2D (_assignment select 0) > 2}) then {
        _x doMove (_assignment select 0);
    };
} forEach units _group;
[{
    params ["_job"];
    private _group = _job get "group";
    if (isNull _group || {!local _group} || {(_group getVariable ["Waldo_AIPass_Defend", []]) isEqualTo []}) exitWith {-1};
    private _pending = 0;
    {
        private _assignment = _x getVariable ["Waldo_AIPass_DefendPos", []];
        if (alive _x && {local _x} && {_assignment isNotEqualTo []} && {!(_x getVariable ["Waldo_AIPass_DefendHolding", false])}) then {
            if (_x distance2D (_assignment select 0) <= 3 || {time > (_job get "deadline")}) then {
                doStop _x;
                _x doWatch ((_assignment select 0) getPos [60, _assignment select 1]);
                _x setVariable ["Waldo_AIPass_DefendHolding", true];
            } else {
                _pending = _pending + 1;
            };
        };
    } forEach units _group;
    [2, -1] select (_pending == 0)
}, createHashMapFromArray [["group", _group], ["deadline", time + 90]], 1] call Waldo_fnc_AIPassQueueJob;
