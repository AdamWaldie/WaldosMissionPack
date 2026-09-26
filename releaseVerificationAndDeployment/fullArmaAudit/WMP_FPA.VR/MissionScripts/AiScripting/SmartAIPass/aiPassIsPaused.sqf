/*
 * Author: WaldoTheWarfighter
 * Reports whether the Smart AI Pass must hold every behaviour because the mission is frozen.
 * ENDEX and SafeStart both publish their authoritative state, so every AI-owning machine reads the
 * same answer without a request. Jobs are deferred, never discarded, while this is true.
 *
 * Arguments: None.
 *
 * Return Value:
 * Boolean - true while ENDEX or SafeStart is active
 *
 * Example:
 * if ([] call Waldo_fnc_AIPassIsPaused) exitWith {};
 * Result: behaviour code does nothing while the mission is frozen.
 *
 * Current callers: Waldo_fnc_AIPassSchedulerTick and Waldo_fnc_AIPassRegroupOnKill.
 */

(missionNamespace getVariable ["Waldo_ENDEX_Active", false])
|| {missionNamespace getVariable ["Waldo_SafeStart_Active", false]}
