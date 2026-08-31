/*
 * Author: WaldoTheWarfighter
 * Removes the local Tree Felling action, restores the previous IMS callback and clears local caches.
 * Locality/authority: interface-local cleanup only; no server or world state is mutated.
 * Repeat/JIP behaviour: idempotent and safe before installation, after runtime disable and on JIP.
 * Arguments: None.
 * Return Value: BOOL - true after cleanup; false on non-interface machines.
 * Current caller: FeatureRuntimeApply disable path and manual mission cleanup.
 * Example: [] call Waldo_fnc_TreeFellingStop;
 */

if !(hasInterface) exitWith {false};
private _actionId = player getVariable ["Waldo_TreeFelling_ActionId", -1];
if (_actionId >= 0) then {player removeAction _actionId};
player setVariable ["IMS_EventHandler_Swing", player getVariable ["Waldo_TreeFelling_PreviousIMSHandler", {}]];
player setVariable ["Waldo_TreeFelling_ActionId", -1];
missionNamespace setVariable ["Waldo_TreeFelling_ClientStarted", false];
uiNamespace setVariable ["Waldo_TreeFelling_TargetCache", []];
true
