/*
 * Author: WaldoTheWarfighter
 * Applies a garrison order on the machine that owns the group: moves soldiers to their positions,
 * locks them there, and installs the duck-under-fire handlers.
 *
 * disableAI and event handlers exist only on the machine that set them, so this runs on the original
 * owner and again on any new owner (Waldo_fnc_AIPassDiscover). Soldiers more than 2 m from their
 * position are sent there, and a job locks them on arrival or after 90 s wherever they are.
 * Handlers: Suppressed and Hit drop the soldier to a lower stance for 4-8 s, then restore the stance
 * he held when the order was applied. Handlers do nothing once the order is released.
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
 * [_group] call Waldo_fnc_AIPassGarrisonApplyLocal;
 * Result: the garrison is live on this machine.
 *
 * Current callers: Waldo_fnc_AIPassGarrison and Waldo_fnc_AIPassDiscover.
 */

params [["_group", grpNull, [grpNull]]];
if (isNull _group || {!local _group} || {!([_group] call Waldo_fnc_AIPassIsEligible)}) exitWith {};
private _generation = (_group getVariable ["Waldo_AIPass_GarrisonGeneration", 0]) + 1;
_group setVariable ["Waldo_AIPass_GarrisonGeneration", _generation];
_group setVariable ["Waldo_AIPass_GarrisonApplied", true];
{
    private _unit = _x;
    private _assignment = _unit getVariable ["Waldo_AIPass_GarrisonPos", []];
    if (alive _unit && {local _unit} && {_assignment isNotEqualTo []}) then {
        if (isNil {_unit getVariable "Waldo_AIPass_GarrisonStance"}) then {_unit setVariable ["Waldo_AIPass_GarrisonStance", unitPos _unit, true]};
        if (_unit getVariable ["Waldo_AIPass_GarrisonDisabledPath", false]) then {_unit enableAI "PATH"};
        if !(_unit getVariable ["Waldo_AIPass_GarrisonHandlers", false]) then {
            _unit setVariable ["Waldo_AIPass_GarrisonHandlers", true];
            private _duck = {
                params ["_unit"];
                if (!local _unit || {(_unit getVariable ["Waldo_AIPass_GarrisonPos", []]) isEqualTo []}) exitWith {};
                if (time < (_unit getVariable ["Waldo_AIPass_DuckUntil", -1])) exitWith {};
                private _until = time + 4 + random 4;
                _unit setVariable ["Waldo_AIPass_DuckUntil", _until];
                _unit setUnitPos (["MIDDLE", "DOWN"] select ((unitPos _unit) == "MIDDLE"));
                [{
                    params ["_unit", "_until"];
                    if (alive _unit && {local _unit} && {(_unit getVariable ["Waldo_AIPass_DuckUntil", -1]) == _until}
                        && {(_unit getVariable ["Waldo_AIPass_GarrisonPos", []]) isNotEqualTo []}) then {
                        _unit setUnitPos (_unit getVariable ["Waldo_AIPass_GarrisonStance", "AUTO"]);
                    };
                }, [_unit, _until], _until - time] call CBA_fnc_waitAndExecute;
            };
            _unit setVariable ["Waldo_AIPass_GarrisonHandlerIds", [
                ["Suppressed", _unit addEventHandler ["Suppressed", _duck]],
                ["Hit", _unit addEventHandler ["Hit", _duck]]
            ]];
        };
        if (_unit distance2D (_assignment select 0) > 2) then {_unit doMove (_assignment select 0)};
    };
} forEach units _group;
[{
    params ["_job"];
    private _group = _job get "group";
    if (isNull _group || {!local _group} || {(_group getVariable ["Waldo_AIPass_Garrison", []]) isEqualTo []}) exitWith {-1};
    if ((_group getVariable ["Waldo_AIPass_GarrisonGeneration", -1]) != (_job get "generation")) exitWith {-1};
    if !([_group] call Waldo_fnc_AIPassIsEligible) exitWith {2};
    private _pending = 0;
    {
        private _assignment = _x getVariable ["Waldo_AIPass_GarrisonPos", []];
        if (alive _x && {local _x} && {_assignment isNotEqualTo []} && {_x checkAIFeature "PATH"}) then {
            if (_x distance2D (_assignment select 0) <= 2 || {time > (_job get "deadline")}) then {
                doStop _x;
                _x setVariable ["Waldo_AIPass_GarrisonDisabledPath", true, true];
                _x disableAI "PATH";
                _x doWatch ((_assignment select 0) getPos [50, _assignment select 1]);
            } else {
                _pending = _pending + 1;
            };
        };
    } forEach units _group;
    [2, -1] select (_pending == 0)
}, createHashMapFromArray [["group", _group], ["deadline", time + 90], ["generation", _generation]], 1] call Waldo_fnc_AIPassQueueJob;
