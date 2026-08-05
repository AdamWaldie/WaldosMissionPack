/*
 * Author: WaldoTheWarfighter, Val
 * Reads a player's client-owned hazard exposure and reports it to the requesting player through
 * the WMP notification UI. When inspecting another player the call forwards to that target's owner,
 * because exposure intentionally remains local rather than being broadcast every evaluator tick.
 * Locality and authority: reads on the target owner's client and notifies only the requesting player.
 *
 * Arguments:
 * 0: target <OBJECT> - player whose exposure is being read.
 * 1: requester <OBJECT> - player receiving the result (default player).
 *
 * Return Value: Boolean - true when handled or forwarded.
 *
 * Example:
 * [cursorTarget, player] call Waldo_fnc_HazardReadExposureLocal;
 * Result: the requester receives a formatted exposure reading without persistent network traffic.
 * Current callers: Hazard Equipment self and target ACE actions.
 */

params [["_target", objNull, [objNull]], ["_requester", player, [objNull]]];
if (isNull _target || {isNull _requester} || {!isPlayer _target}) exitWith {false};
if (!local _target) exitWith {
    [_target, _requester] remoteExecCall ["Waldo_fnc_HazardReadExposureLocal", owner _target];
    true
};
private _exposures = missionNamespace getVariable ["Waldo_Hazard_LocalExposure", createHashMap];
private _rows = [];
{
    private _value = _exposures getOrDefault [_x, 0];
    if (_value > 0) then {_rows pushBack format ["%1: %2", _x, _value toFixed 2]};
} forEach ((keys _exposures) call BIS_fnc_sortAlphabetically);
private _body = if (_rows isEqualTo []) then {
    format ["%1 has no measurable exposure.", name _target]
} else {
    format ["%1 — %2", name _target, _rows joinString " | "]
};
["HAZARD DOSIMETER", _body, if (_rows isEqualTo []) then {"SUCCESS"} else {"WARNING"}, "HAZARD_DOSIMETER", 6]
    remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", owner _requester];
true
