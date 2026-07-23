/*
 * Author: Waldo
 * Draws a persistent electronic-warfare HUD element. Arma's radio and UAV systems drop out for all
 * sorts of buggy reasons, so this makes jamming unmistakable: a dedicated control on the main
 * mission display that other scripts' hints cannot overwrite, showing a blinking banner, a strength
 * bar and an explicit "this is intentional, not a bug" line while active. Passing a factor of 0
 * hides it. Reused for both radio jamming and UAV-link jamming by passing a different label and IDC.
 * Called every tick by the watchers in Waldo_fnc_JammingInit.
 *
 * Arguments:
 * 0: Factor <NUMBER> - current effect strength, 0..1 (0 hides the HUD)
 * 1: Label <STRING> - the banner title (optional, default: "RADIO JAMMED")
 * 2: IDC <NUMBER> - unique control id so multiple banners can coexist (optional, default: 5310)
 * 3: Sub <STRING> - the small explanatory line (optional, default: the radio wording)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [0.8] call Waldo_fnc_JammingHud;                                   // radio banner
 * [0.5, "UAV LINK JAMMED", 5311, "Drone datalink is jammed - not a game bug"] call Waldo_fnc_JammingHud;
 */

if !(hasInterface) exitWith {};

params [["_factor", 0], ["_label", "RADIO JAMMED"], ["_idc", 5310], ["_sub", "Comms loss here is intentional - not a game bug"]];

private _display = findDisplay 46;
if (isNull _display) exitWith {};

private _ctrl = _display displayCtrl _idc;
if (isNull _ctrl) then {
    _ctrl = _display ctrlCreate ["RscStructuredText", _idc];
    // Stack a second banner (UAV) just below the first (radio) using the IDC offset.
    private _row = 0.09 + (0.10 * (_idc - 5310));
    _ctrl ctrlSetPosition [
        safezoneX + safezoneW * 0.31,
        safezoneY + safezoneH * _row,
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
    "<t align='center' color='%1' size='1.7' shadow='1'>%2  %3%4</t><br/><t align='center' color='%1' size='1.3'>[%5]</t><br/><t align='center' color='#ffffff' size='0.85'>%6</t>",
    _col, _label, _pct, "%", _bar, _sub
];
