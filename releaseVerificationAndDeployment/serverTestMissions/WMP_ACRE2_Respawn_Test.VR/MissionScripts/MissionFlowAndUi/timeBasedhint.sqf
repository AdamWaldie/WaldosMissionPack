/*
This proceedure allows for the pushing of a hint to all players screen for a limited amount of seconds

params:
_hintContents - text contents which you wish to display to the player
_hintTimer - length of time in which the text will be displayed on the screen

e.g.

 ["Rendevous Respawn Activated",10] spawn Waldo_fnc_TimedHint;

*/
params ["_hintContents", ["_hintTimer", 10], ["_owner", "", [""]]];

private _token = format ["%1_%2", diag_tickTime, random 1e9];
uiNamespace setVariable ["Waldo_TimedHintToken", _token];
uiNamespace setVariable ["Waldo_TimedHintOwner", toUpper _owner];
hint _hintContents;
sleep _hintTimer;
// An older hint must never clear a newer or more important notification.
if ((uiNamespace getVariable ["Waldo_TimedHintToken", ""]) isEqualTo _token) then {
    hint "";
    uiNamespace setVariable ["Waldo_TimedHintToken", nil];
    uiNamespace setVariable ["Waldo_TimedHintOwner", nil];
};
