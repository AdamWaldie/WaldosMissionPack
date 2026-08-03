/*
 * Author: WaldoTheWarfighter
 * Removes one specialist HUD reservation from the shared local WMP UI flow manager. Controls are
 * not deleted because their owning feature remains responsible for presentation lifecycle.
 *
 * Arguments:
 * 0: reservation key <STRING>
 * 1: hide registered controls <BOOL> (default true)
 *
 * Return Value: BOOL - true when a reservation existed and was removed.
 *
 * Example: ["EW_STATUS"] call Waldo_fnc_UnregisterUiReservationLocal;
 * Current callers: available to specialist HUDs and plugins during teardown.
 */
if (!hasInterface) exitWith {false};
params [["_key", "", [""]], ["_hide", true, [true]]];
_key = toUpperANSI _key;
private _registry = +(uiNamespace getVariable ["Waldo_UI_ReservationRegistry", []]);
private _index = _registry findIf {(_x param [0, ""]) isEqualTo _key};
if (_index < 0) exitWith {false};
private _entry = _registry deleteAt _index;
if (_hide) then {{if (!isNull _x) then {_x ctrlShow false}} forEach (_entry param [1, []])};
uiNamespace setVariable ["Waldo_UI_ReservationRegistry", _registry];
[0] call Waldo_fnc_ReflowUiPanels;
true
