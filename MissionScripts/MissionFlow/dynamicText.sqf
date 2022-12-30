/*
This proceedure displays a dynamic text across the center of the scren 


Parameters:
 _text - wha you want to display to the _player target.
 _player - whom you want to target, can be multiple or all clients.

*/
params ["_text", "_player"];
["<t size='.8'>" + _text,-1,-1,3,0.2,0.1,789] remoteExec ["BIS_fnc_dynamicText", _player];