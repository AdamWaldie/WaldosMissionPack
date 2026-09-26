/*
 * Author: WaldoTheWarfighter
 * Limits requested convoy speed when friendly infantry occupy its short driving corridor.
 * Locality/authority: read-only on the vehicle owner; the existing convoy controller applies speed.
 * Repeat/JIP: no persistent orders; disabled gates return the original requested speed immediately.
 * Arguments: 0: vehicle <OBJECT>; 1: requested km/h <NUMBER>; 2: convoy group <GROUP>.
 * Return Value: Speed in km/h, between zero and the request.
 * Current callers: ConvoyTick.
 * Example: private _speed = [_truck,30,_group] call Waldo_fnc_AIPassInfantrySpeed;
 */
params ["_vehicle","_requested","_group"];
if (!([_group,"Waldo_Convoy_AvoidInfantry_Enable",false] call Waldo_fnc_AIPassFeatureEnabled) || {!local _vehicle}) exitWith {_requested};
private _bounds = boundingBoxReal _vehicle;
private _halfWidth = (abs ((_bounds select 0) select 0)) max (abs ((_bounds select 1) select 0));
private _halfLength = (abs ((_bounds select 0) select 1)) max (abs ((_bounds select 1) select 1));
private _look = (_halfLength + 5 + (abs speed _vehicle)/3.6) min 30;
private _people = _vehicle nearEntities ["CAManBase",_look+3];
if (count _people > 32) exitWith {0}; // Crowded: hold rather than ignore an unexamined pedestrian.
private _limit = _requested;
private _reverse = (velocityModelSpace _vehicle select 1) < -0.5;
{
    if (alive _x && {vehicle _x == _x} && {(side _group) getFriend (side group _x) >= 0.6}) then {
        private _relative = _vehicle worldToModel (getPosATL _x);
        private _along = (_relative select 1) * ([1,-1] select _reverse);
        if (abs (_relative select 0) < _halfWidth+1.5 && {_along > -_halfLength} && {_along < _look}
            && {abs (_relative select 2) < 3}) then {
            _limit = _limit min ([5,0] select (_along < _halfLength+5));
        };
    };
} forEach _people;
_limit
