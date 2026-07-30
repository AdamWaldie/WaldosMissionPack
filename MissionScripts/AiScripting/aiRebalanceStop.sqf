/*
 * Author: WaldoTheWarfighter
 * Stops future automatic AI profile application and optionally restores captured skills.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_AIRebalanceStop;
 *
 * Current callers: AI ZEN runtime control and the audit AI reset station.
 */

if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {};
missionNamespace setVariable ["Waldo_AI_RebalanceActive", false, isServer];
if (isServer) then {
    missionNamespace setVariable ["Waldo_AIRebalance_Enable", false, true];
    [] remoteExecCall ["", "Waldo_AIRebalance_RuntimeInit"];
    if (remoteExecutedOwner == 0) then {
        [] remoteExecCall ["Waldo_fnc_AIRebalanceStop", -2];
    };
};
if (missionNamespace getVariable ["Waldo_AI_RestoreOnStop", true]) then {
    {
        if (local _x && {!isPlayer _x}) then {
            private _unit = _x;
            private _original = _unit getVariable ["Waldo_AI_OriginalSkills", createHashMap];
            {_unit setSkill [_x, _original get _x]} forEach keys _original;
            _unit setVariable ["Waldo_AI_OriginalSkills", nil];
        };
    } forEach allUnits;
};
