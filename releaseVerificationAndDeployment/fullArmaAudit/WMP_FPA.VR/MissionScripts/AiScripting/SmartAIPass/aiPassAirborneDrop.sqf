/*
 * Author: WaldoTheWarfighter
 * Orders an AI squad riding as cargo in an AI-flown aircraft to parachute out now.
 *
 * The scripted and Zeus equivalent of the automatic airborne insertion: it does not wait for a known
 * enemy, but the aircraft must still be at least Waldo_AIPass_Airborne_MinAltitude above ground, not
 * over water, and flown by AI. Works even while automatic insertion (Waldo_AIPass_Airborne_Enable) is
 * off, as long as the Smart AI Pass runs on the machine that owns the squad. Once down, the squad goes
 * to fight around where it landed unless it has waypoints of its own.
 * Locality and authority: safe anywhere on the server; forwarded to the machine that owns the group.
 *
 * Arguments:
 * 0: group <GROUP, OBJECT> - the squad, or one of its soldiers
 *
 * Return Value:
 * Boolean - true when the drop started (or was forwarded to the owning machine)
 *
 * Example:
 * [group this] call Waldo_fnc_AIPassAirborneDrop;
 * Result: from a trigger or a waypoint's On Activation, the squad in the helicopter jumps.
 *
 * Current callers: mission triggers and scripts, and the AI Orders ZEN module.
 */

params [["_group", grpNull, [grpNull, objNull]]];
if (_group isEqualType objNull) then {_group = group _group};
if (isNull _group) exitWith {false};
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {false};
if (!local _group) exitWith {
    if (isServer) then {[_group] remoteExecCall ["Waldo_fnc_AIPassAirborneDrop", groupOwner _group]; true} else {false};
};
if !(missionNamespace getVariable ["Waldo_AIPass_Active", false]) exitWith {
    diag_log format ["[WMP AI PASS] %1 airborne drop refused: the Smart AI Pass is not running on this machine.", _group];
    false
};
if !([_group] call Waldo_fnc_AIPassIsEligible) exitWith {
    diag_log format ["[WMP AI PASS] %1 airborne drop refused: the squad is not eligible (Zeus hold, exclusion or another feature's AI).", _group];
    false
};
private _started = ([_group, [_group] call Waldo_fnc_AIPassGroupState, true] call Waldo_fnc_AIPassAirborneCheck) == 0;
if (!_started) then {
    diag_log format ["[WMP AI PASS] %1 airborne drop refused: not riding an AI-flown aircraft high enough over land.", _group];
};
_started
