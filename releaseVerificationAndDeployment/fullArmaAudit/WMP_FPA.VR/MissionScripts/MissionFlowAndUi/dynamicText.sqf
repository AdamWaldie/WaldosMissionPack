/*
 * Author: WaldoTheWarfighter
 * Purpose: Compatibility adapter for older mission calls that displayed centre-screen text.
 * Messages now use the bounded WMP notification service, so concurrent feature UI shares the same
 * top-right stacking, overflow, theme, accessibility and ACE-priority rules. Logistics and MHQ
 * updates must not obscure the player's centre view.
 *
 * Locality / Authority: May run where the caller runs; the notification renders only on the target client.
 * Repeat / JIP: Each invocation sends one transient message; no persistent JIP state.
 * Arguments:
 * 0: message <STRING>
 * 1: remote target <OBJECT|ARRAY|NUMBER> - any valid remoteExec target
 * 2: feature title <STRING> (default "MISSION UPDATE") - use the calling module's name.
 *
 * Return Value: BOOL - true after the notification request is sent.
 *
 * Example: ["Supplies ready", _player, "QUARTERMASTER"] call Waldo_fnc_DynamicText;
 * Current callers: MHQ, logistics crates, quartermaster, vehicle camouflage and construction.
 * Result: The selected player receives the requested WMP notification on its channel.
 */
params ["_text", "_player", ["_title", "MISSION UPDATE", [""]]];
if (_title isEqualTo "") then {_title = "MISSION UPDATE"};
[ _title, _text, "INFO", 4, "TOP_RIGHT", format ["DYNAMIC_TEXT_%1", _title], "LOGISTICS", "REPLACE"]
    remoteExecCall ["Waldo_fnc_ShowUiNotification", _player];
true
