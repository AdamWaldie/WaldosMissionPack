/*
 * Author: Waldo
 * Draws the persistent "RADIO JAMMED" HUD element. Arma's radio mods drop comms for all sorts of
 * buggy reasons, so this makes jamming unmistakable: a dedicated control on the main mission
 * display (IDC 5310) that other scripts' hints cannot overwrite, showing a blinking banner, a
 * strength bar and an explicit "this is intentional, not a bug" line while the player is jammed.
 * Passing a factor of 0 hides it. Called every tick by the watcher in Waldo_fnc_JammingInit.
 *
 * Arguments:
 * 0: Factor <NUMBER> - current jamming strength on the player, 0..1 (0 hides the HUD)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [0.8] call Waldo_fnc_JammingHud;
 */

if !(hasInterface) exitWith {};

params [["_factor", 0]];

private _display = findDisplay 46;
if (isNull _display) exitWith {};

private _idc = 5310;
private _ctrl = _display displayCtrl _idc;
if (isNull _ctrl) then {
    _ctrl = _display ctrlCreate ["RscStructuredText", _idc];
    _ctrl ctrlSetPosition [
        safezoneX + safezoneW * 0.31,
        safezoneY + safezoneH * 0.09,
        safezoneW * 0.38,
        safezoneH * 0.085
    ];
    _ctrl ctrlSetBackgroundColor [0, 0, 0, 0.65];
    _ctrl ctrlCommit 0;
};

if (_factor <= 0) exitWith { _ctrl ctrlShow false; };

_ctrl ctrlShow true;

private _pct = round (_factor * 100);
private _filled = round (_factor * 10);
private _bar = "";
for "_i" from 1 to 10 do {
    _bar = _bar + (["_", "#"] select (_i <= _filled));
};

// Blink between two reds so it visibly pulses and cannot be mistaken for a static UI leftover.
private _blink = (floor (diag_tickTime * 2)) % 2 == 0;
private _col = ["#c8102e", "#ff6161"] select _blink;

_ctrl ctrlSetStructuredText parseText format [
    "<t align='center' color='%1' size='1.7' shadow='1'>RADIO JAMMED  %2%3</t><br/><t align='center' color='%1' size='1.3'>[%4]</t><br/><t align='center' color='#ffffff' size='0.85'>Comms loss here is intentional - not a game bug</t>",
    _col, _pct, "%", _bar
];
