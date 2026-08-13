/*
 * Author: WaldoTheWarfighter
 * Shared gate for the headless-client system's extended debug output. The legacy
 * MissionScripts\ThirdPartyScripts\WerthlesHeadless.sqf ("Werthles' Headless Kit") shipped an
 * always-visible hint-based debug display of HC connect/migrate/disconnect flow; this rework keeps
 * that same admin-visible intent but through WMP's own [WMP DIAG] framing (Waldo_fnc_DiagnosticLog,
 * consistent with every other feature's diagnostics rather than a one-off hint channel) and extends
 * it with per-pass load/eligibility detail the legacy script never reported. Off by default
 * (Waldo_Headless_Debug in MissionConfig\headlessConfig.sqf) - the four call sites in this rework
 * (Waldo_fnc_HeadlessRegisterClient, Waldo_fnc_HeadlessRebalance, Waldo_fnc_HeadlessMigrateGroup,
 * Waldo_fnc_HeadlessReassignOnDisconnect) already write a one-line diag_log unconditionally for
 * every real event regardless of this flag - that baseline trail is one-shot-per-event and cheap
 * enough to always keep. This helper exists only for the noisier, genuinely optional extra detail
 * (per-client load tables, exclusion-reason tallies, timing) a mission maker only wants while
 * actively diagnosing HC behaviour, so a released mission running this system pays nothing extra by
 * default. Performance: a single getVariable check when the flag is off; only formats/writes when on.
 *
 * Locality and authority:
 * Server-only (the headless system's own event stream is entirely server-side); a no-op elsewhere.
 * A local systemChat still fires when hasInterface (a listen-server host sees it directly), but on a
 * genuine dedicated server that machine has no console to show it on - so this also remoteExecs the
 * same line to every currently assigned curator's client (allCurators/getAssignedCuratorUnit), the
 * same admin-audience mechanism Waldo_fnc_HeadlessDebugToggle already uses for its own confirmation
 * notification. This mirrors what the legacy WerthlesHeadless.sqf actually did - BIS_fnc_MP-ing its
 * debug hint to the specific connected player (WHKDEBUGGER) who toggled it, not a local-only call
 * gated on the executing machine's own interface - rather than the RPT-only fallback this rework
 * originally shipped with, which left dedicated-server admins with no in-game visibility at all
 * unless they tailed the server's own RPT file by hand.
 *
 * Arguments:
 * 0: event <STRING> - short event tag, e.g. "REGISTER", "REBALANCE", "MIGRATE", "DISCONNECT".
 * 1: message <STRING> - human-readable detail.
 *
 * Return Value:
 * Nothing.
 *
 * Example:
 * ["REBALANCE", "eligible=4 excluded=2 queuedNow=1 loadByOwner=[[3,2],[4,2]]"] call Waldo_fnc_HeadlessDebugLog;
 *
 * Current callers: Waldo_fnc_HeadlessRegisterClient, Waldo_fnc_HeadlessRebalance,
 * Waldo_fnc_HeadlessMigrateGroup, Waldo_fnc_HeadlessReassignOnDisconnect.
 */

params [["_event", "EVENT", [""]], ["_message", "", [""]]];
if !(isServer) exitWith {};
if !(missionNamespace getVariable ["Waldo_Headless_Debug", false]) exitWith {};

["headless-client", "headless-client", "INFO", _event, _message] call Waldo_fnc_DiagnosticLog;
private _text = format ["[WMP HEADLESS] %1: %2", _event, _message];
if (hasInterface) then {systemChat _text;};
private _curatorUnits = (allCurators apply {getAssignedCuratorUnit _x}) select {!isNull _x};
if (count _curatorUnits > 0) then {[_text] remoteExec ["systemChat", _curatorUnits];};
