/*
 * Author: WaldoTheWarfighter
 * Debug helper that monitors the vehicle under the local cursor and reports total and named
 * hit-point damage until that vehicle is destroyed or removed.
 *
 * Arguments: None; resolves `cursorObject` locally when executed.
 * Return Value: Script handle stored in `real_vicwatch`.
 * Example: execute this file locally from the debug console while aiming at a vehicle.
 * Current caller: manual mission-maker diagnostics only.
 */

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
        _hintlistString = _hintlist joinstring ((toString [10]) + " %"); // line breaks and format notation
        _hintlistString = _hintlistString select [4]; // remove the first placeholder
        _hintlistStringFormat = [_hintlistString]; //creates array to add hintSilent parameters
        for "_i" from 0 to (count _displaypoints - 1) do {
            _hintlistStringFormat pushback (_displaypoints select _i); //assembles hitpoint strings with hint formatting
        };
        hintSilent format _hintlistStringFormat;//displaypoints select n+1, displaypoints select n+2
    };
};
