/*
 * Author: WaldoTheWarfighter
 * Returns ZEN COMBO data for every available shared interaction procedure.
 *
 * All ten WMP procedures are always listed with beginner-readable names. Additional procedures
 * registered locally through Waldo_fnc_MiniGameRegisterChallenge are appended automatically.
 * The preferred procedure remains selected without changing the common catalogue order.
 * This is pure client-side dialog data; it does not start an interaction or mutate network state.
 *
 * Arguments:
 * 0: preferred procedure id <STRING> (default "circuit")
 *
 * Return Value:
 * ARRAY in ZEN COMBO format: [procedure ids, display labels, selected index]
 *
 * Example:
 * ["repair"] call Waldo_fnc_MiniGameInteractionOptions;
 * Result: [["wirecut", ...], ["Control-wire isolation", ...], 5]
 *
 * Current callers: jammer, Dynamic AA, vehicle-recovery and tactical-display ZEN dialogs.
 */

params [["_preferred", "circuit", [""]]];
_preferred = toLowerANSI _preferred;

private _rows = [
    ["wirecut", "Control-wire isolation"],
    ["minesweeper", "Ordnance matrix analysis"],
    ["keypad", "Access-code authentication"],
    ["lockpick", "Physical lock bypass"],
    ["circuit", "Circuit bypass"],
    ["repair", "Mechanical repair"],
    ["radiotune", "Signal alignment"],
    ["pressure", "Hydraulic stabilisation"],
    ["sequence", "Secure sequence verification"],
    ["commandinput", "Command authentication"]
];
{
    _x params ["_id", "_opener", "_displayName"];
    private _normalized = toLowerANSI _id;
    if (_normalized != "" && {(_rows findIf {(_x select 0) == _normalized}) < 0}) then {
        _rows pushBack [_normalized, _displayName];
    };
} forEach (missionNamespace getVariable ["Waldo_MG_ChallengeRegistry", []]);

private _ids = _rows apply {_x select 0};
private _labels = _rows apply {_x select 1};
private _selected = _ids find _preferred;
if (_selected < 0) then {_selected = 0};
[_ids, _labels, _selected]
