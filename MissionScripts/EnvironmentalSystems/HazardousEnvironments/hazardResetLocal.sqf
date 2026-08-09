/*
 * Author: WaldoTheWarfighter, Val
 * Clears every player-object-specific hazardous-environment value on the executing interface
 * client. Exposure is deliberately not persistent across death: a replacement player begins with
 * no dose, damage stage, inside-zone transition, audio cooldown or prior damage attribution. The
 * authoritative server zone registry is untouched, and the already-running evaluator may continue.
 *
 * Locality and authority: interface-client only. Repeat-safe and safe during initial join, local
 * respawn, JIP player-object replacement and runtime shutdown. HazardTick also calls this function
 * when it detects a different player object, so event-handler ordering cannot permit one inherited
 * damage tick on the replacement unit.
 *
 * Arguments: None.
 * Return Value: Boolean - true after local state and presentation are reset.
 * Current callers: HazardInit, HazardStop, the local EntityRespawned handler and HazardTick's
 * player-object generation guard.
 *
 * Example:
 * [] call Waldo_fnc_HazardResetLocal;
 * Result: the current local player has zero carried hazard exposure while shared zones remain live.
 */

if (!hasInterface) exitWith {false};
missionNamespace setVariable ["Waldo_Hazard_LocalPlayerObject", player];
missionNamespace setVariable ["Waldo_Hazard_LocalExposure", createHashMap];
missionNamespace setVariable ["Waldo_Hazard_LocalInside", createHashMap];
missionNamespace setVariable ["Waldo_Hazard_LocalTypeLastInside", createHashMap];
missionNamespace setVariable ["Waldo_Hazard_LocalDamageStages", createHashMap];
missionNamespace setVariable ["Waldo_Hazard_LocalAudioTimers", createHashMap];
missionNamespace setVariable ["Waldo_Hazard_LastEvaluation", []];
uiNamespace setVariable ["Waldo_Hazard_StatusText", ""];
[[]] call Waldo_fnc_HazardHud;
diag_log format ["[WMP HAZARD] Local player exposure reset object=%1 owner=%2.", netId player, clientOwner];
true
