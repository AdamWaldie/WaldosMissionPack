/*
 * Author: WaldoTheWarfighter
 * Compatibility adapter for older mission calls that displayed uncoordinated centre-screen text.
 * Messages now use the bounded WMP notification service, so concurrent feature UI shares the same
 * top-right stacking, overflow, theme, accessibility and ACE-priority rules. Logistics and MHQ
 * updates must not obscure the player's centre view.
 *
 * Arguments:
 * 0: message <STRING>
 * 1: remote target <OBJECT|ARRAY|NUMBER> - any valid remoteExec target
 *
 * Return Value: BOOL - true after the notification request is sent.
 *
 * Example: ["Construction completed", _player] call Waldo_fnc_DynamicText;
 * Current callers: MHQ, logistics crates, quartermaster and construction compatibility scripts.
 */
params ["_text", "_player"];
["MISSION UPDATE", _text, "INFO", 4, "TOP_RIGHT", "LEGACY_DYNAMIC_TEXT", "LOGISTICS", "REPLACE"]
    remoteExecCall ["Waldo_fnc_ShowUiNotification", _player];
true
