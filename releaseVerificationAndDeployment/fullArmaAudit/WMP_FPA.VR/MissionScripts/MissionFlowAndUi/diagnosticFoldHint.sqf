/*
 * Author: WaldoTheWarfighter
 * Folds an optional plain-language remediation hint into a diagnostic check's detail text, using
 * the one "; fix: <hint>" convention every WMP diagnostic check - server, client, and every
 * *GetDiagnostics.sqf feature report - shares. Centralising the exact phrasing here keeps a check
 * authored anywhere in the pack assistive in the same wording instead of each call site
 * hand-formatting its own variant.
 * Locality and authority: none. Pure, unscheduled string formatting; safe anywhere.
 *
 * Arguments:
 * 0: detail text <STRING>
 * 1: hint <STRING> (optional, default "" - no hint folded in)
 *
 * Return Value:
 * String - _detail unchanged, or "_detail; fix: _hint" when a hint was supplied
 *
 * Example:
 * private _fullDetail = ["state=ERROR class=foo", "Set Logi_SupplyBoxClass to a real CfgVehicles class."]
 *     call Waldo_fnc_DiagnosticFoldHint;
 * Current callers: Waldo_fnc_RunDiagnostics' _status helper, Waldo_fnc_RunDiagnosticsClient's _add
 * helper, and every *GetDiagnostics.sqf feature report that builds its own check rows directly.
 */

params [["_detail", "", [""]], ["_hint", "", [""]]];
if (_hint == "") then {_detail} else {format ["%1; fix: %2", _detail, _hint]}
