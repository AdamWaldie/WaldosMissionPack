/*
 * Clears every WMP-owned local HUD panel and transient display. This function
 * is repeat-safe and never changes server, mission or gameplay state.
 *
 * Arguments: None
 * Return: BOOL
 * Example: [] call Waldo_fnc_ClearUiPanels;
 */
if (!hasInterface) exitWith {false};
[] call Waldo_fnc_CleanupTransientUi;
diag_log format ["[WMP UI] local cleanup requested clientOwner=%1 player=%2", clientOwner, player];
true
