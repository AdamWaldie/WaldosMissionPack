/*
 * Author: WaldoTheWarfighter
 * Clears every WMP-owned local HUD panel and transient display. This function
 * is repeat-safe and never changes server, mission or gameplay state.
 *
 * Arguments: None
 * Return Value: <BOOL> true after local cleanup; false without an interface.
 * Example: [] call Waldo_fnc_ClearUiPanels;
 * Locality and authority: Runs only on the current interface client. Repeating cleanup is
 * safe and does not change server state or another player's UI; no JIP replay is needed.
 * Current callers: mission-maker UI cleanup scripts and feature teardown controls.
 * Result: WMP-owned local panels and transient displays are cleared.
 */
if (!hasInterface) exitWith {false};
[] call Waldo_fnc_CleanupTransientUi;
diag_log format ["[WMP UI] local cleanup requested clientOwner=%1 player=%2", clientOwner, player];
true
