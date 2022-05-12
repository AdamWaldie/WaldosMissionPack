/*
Script for verifying how much damage a vehicle is taken and what parts are affected. It prints this to a hint.

This version is used via:

1) Load into the editor or wherever you have debug permissions.

2) Aim your weapon at a vehicle.

3) Access the debug console.

4) Paste the script in the debug console and local exec.

The script will continuously run until the vehicle or unit has been deleted or destroyed.

This scripts original author is known as "Real" at the time of this scritps inclusion in this pack.
I claim no rights to the script. Please credit them.

*/

//Original Script
_vic = cursorObject //vehicle to test hitpoints
;
terminate real_vicwatch;
real_vicwatch = [_vic] spawn{
	params ["_vic"];
	while{alive _vic} do {
		sleep 0.2;
		_displayPoints = [];
		_hintList = [];
		_hitPointsDamage = getAllHitPointsDamage _vic;
		_hitpoints = _hitPointsDamage select 0;
		_damaged = _hitPointsDamage select 2;
		{
			_toPercent = [format ["%1%", _x*100 toFixed 1]];
			_toPercent pushBack "%";
			_toPercent = _toPercent joinString "";
			_damaged set [_foreachindex, _toPercent];
		} foreach _damaged;
		_pointsNumber = (count _damaged) - 1;
		{
			_displaypoints set [_forEachIndex, format ["%1: %2",_x, _damaged select _forEachIndex]];
			//create array of strings in "hitpoint: damage" format
		} forEach _hitpoints;
		
		for "_i" from 0 to _pointsNumber + 2 do {
			_hintlist pushBack _i;
		};
		_hintlistString = _hintlist joinstring "\n %"; //line breaks and format notation
		_hintlistString = _hintlistString select [4]; //remove 0\n 
		_hintlistStringFormat = [_hintlistString]; //creates array to add hintSilent parameters
		for "_i" from 0 to (count _displaypoints - 1) do {
			_hintlistStringFormat pushback (_displaypoints select _i); //assembles hitpoint strings with hint formatting
		};
		hintSilent format _hintlistStringFormat;//displaypoints select n+1, displaypoints select n+2
	};
};