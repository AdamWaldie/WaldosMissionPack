/*
This proceedure allows for the pushing of a hint to all players screen for a limited amount of seconds

params:
_hintContents - text contents which you wish to display to the player

e.g.

 ["Rendevous Respawn Activated"] spawn Waldo_fnc_TimedHint;

*/
params["_hintContents"];

[_hintContents] remoteExec ["hint",-2];
sleep 10;
[""] remoteExec ["hint",-2];