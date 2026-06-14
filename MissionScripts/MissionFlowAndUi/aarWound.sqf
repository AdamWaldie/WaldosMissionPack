/*
 * Author: Waldo
 * Server-side WIA tally for the AAR. Increments the wounded-in-action count for a
 * side index. Fed by the ACE unconscious listener registered in init.sqf, which
 * forwards each unit's first unconsciousness here (one count per unit). Paired with
 * Waldo_fnc_AARTrack / the ENDEX debrief.
 *
 * Arguments:
 * 0: Side index <NUMBER> - 0 west, 1 east, 2 independent, 3 civilian (-1 = ignore)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [0] call Waldo_fnc_AARWound;
 */

if !(isServer) exitWith {};

params [["_idx", -1]];
if (_idx < 0 || _idx > 3) exitWith {};

private _wia = +(missionNamespace getVariable ["Waldo_AAR_WIA", [0,0,0,0]]);
_wia set [_idx, (_wia select _idx) + 1];
missionNamespace setVariable ["Waldo_AAR_WIA", _wia, true];
