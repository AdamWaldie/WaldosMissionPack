/*
 * Author: WaldoTheWarfighter
 * Acknowledges the current local Safestart presentation phase and immediately hides its persistent
 * panel for this player. WAITING and COUNTDOWN are separate phases: acknowledging the waiting panel
 * hides it until a go-live countdown starts; acknowledging the countdown hides it until SafeStart
 * ends. This changes no server state, protection, timer, confinement or other player's display. The
 * local acknowledgement is cleared at go-live and therefore is not persisted or replayed to JIP.
 * Repeat calls during the same phase are harmless.
 *
 * Arguments: None.
 * Return Value: BOOL - true when active Safestart was acknowledged; false when it was not active.
 * Current caller: WMP Interface > Acknowledge SafeStart self-interaction.
 * Example: [] call Waldo_fnc_SafeStartAcknowledgeLocal;
 */
if (!hasInterface || {!(missionNamespace getVariable ["Waldo_SafeStart_Active", false])}) exitWith {false};

private _phase = if ((missionNamespace getVariable ["Waldo_SafeStart_EndTime", 0]) > 0) then {"COUNTDOWN"} else {"WAITING"};
uiNamespace setVariable ["Waldo_SafeStart_AcknowledgedPhase", _phase];

private _display = findDisplay 46;
if (!isNull _display) then {
    private _frame = _display displayCtrl 5299;
    private _control = _display displayCtrl 5300;
    if (!isNull _frame) then {_frame ctrlShow false};
    if (!isNull _control) then {_control ctrlShow false};
    ["SAFESTART_STATUS", [_frame, _control], ["TOP", "TOP_RIGHT"], false] call Waldo_fnc_RegisterUiReservationLocal;
};
diag_log format ["[WMP SAFESTART] Local player acknowledged presentation phase=%1", _phase];
true
