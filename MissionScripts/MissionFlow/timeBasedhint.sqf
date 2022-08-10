/*
This proceedure allows for the pushing of a hint to all players screen for a limited amount of seconds

params:
_hintContents - text contents which you wish to display to the player
_hintTimer - length of time in which the text will be displayed on the screen

e.g.

 ["Rendevous Respawn Activated",10] spawn Waldo_fnc_TimedHint;

*/
params["_hintContents",["_hintTimer",10]];

//[_hintContents] remoteExec ["hint",-2];
hint _hintContents;
sleep _hintTimer;
//[""] remoteExec ["hint",-2];
hint "";