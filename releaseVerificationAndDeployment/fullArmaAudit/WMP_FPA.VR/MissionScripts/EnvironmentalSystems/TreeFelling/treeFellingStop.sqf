/*
 * Author: WaldoTheWarfighter
 * Removes the local tree-felling action and restores any previous IMS swing callback.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_TreeFellingStop;
 */

if !(hasInterface) exitWith {};
private _actionId = player getVariable ["Waldo_TreeFelling_ActionId", -1];
if (_actionId >= 0) then {player removeAction _actionId};
player setVariable ["IMS_EventHandler_Swing", player getVariable ["Waldo_TreeFelling_PreviousIMSHandler", {}]];
player setVariable ["Waldo_TreeFelling_ActionId", -1];
missionNamespace setVariable ["Waldo_TreeFelling_ClientStarted", false];
