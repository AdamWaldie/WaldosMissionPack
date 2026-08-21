/*
 * Author: WaldoTheWarfighter
 * Removes only WMP dialogue actions recorded on one speaker for this client.
 * Locality/authority: interface local. Repeat/JIP behaviour: repeat-safe; never removes unrelated actions.
 * Arguments: 0 speaker <OBJECT>. Return Value: BOOL.
 * Current callers: snapshot reconciliation and action replacement. Example: [npc] call Waldo_fnc_DialogueRemoveActionLocal;
 */
params [["_speaker", objNull, [objNull]]];
if (!hasInterface || {isNull _speaker}) exitWith {false};
{[_speaker, _x] call BIS_fnc_holdActionRemove} forEach (_speaker getVariable ["Waldo_Dialogue_LocalActionIds", []]);
if !(isNil "ace_interact_menu_fnc_removeActionFromObject") then {
    {[_speaker, 0, _x] call ace_interact_menu_fnc_removeActionFromObject} forEach (_speaker getVariable ["Waldo_Dialogue_LocalAcePaths", []]);
};
_speaker setVariable ["Waldo_Dialogue_LocalActionIds", []];
_speaker setVariable ["Waldo_Dialogue_LocalAcePaths", []];
true
