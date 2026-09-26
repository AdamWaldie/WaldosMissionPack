/*
 * Author: WaldoTheWarfighter
 * Reads a directly observed target and visibly uses the assigned observer binoculars. No report is extrapolated.
 * Locality/authority: documented guards enforce server coordination and owner-local execution.
 * Repeat/JIP: mission tokens reject stale work; server state survives HC migration, not restart.
 * Arguments: 0: spotter <OBJECT>; 1: enemy <OBJECT>; 2: previous impact ATL <ARRAY>, default [].
 * Return Value: Array [reported ATL, error], or [] without observation.
 * Current callers: ArtilleryRequest and ArtilleryObserve.
 * Example: private _fix = [_spotter, _enemy] call Waldo_fnc_AIPassSpotterFix;
 */
params [["_spotter", objNull, [objNull]], ["_enemy", objNull, [objNull]], ["_impact", [], [[]]]];
if (!local _spotter || {!alive _spotter} || {isPlayer _spotter} || {!alive _enemy}
    || {!(_spotter getVariable ["Waldo_AIPass_Spotter", false])}
    || {vehicle _spotter != _spotter} || {binocular _spotter == ""}
    || {_spotter getVariable ["ACE_isUnconscious", false]} || {lifeState _spotter == "INCAPACITATED"}
    || {!([group _spotter] call Waldo_fnc_AIPassIsEligible)}) exitWith {[]};
if (!([_spotter] call Waldo_fnc_AIPassCanTransmit)) exitWith {[]};
private _knowledge = _spotter targetKnowledge _enemy;
if (!(_knowledge select 1) || {_spotter knowsAbout _enemy < 1.5}
    || {time - (_knowledge select 2) > 5}
    || {(side group _spotter) getFriend (side group _enemy) >= 0.6}) exitWith {[]};
private _eye = eyePos _spotter;
if ([_spotter, "VIEW", _enemy] checkVisibility [_eye, aimPos _enemy] < 0.5) exitWith {[]};
if (_impact isNotEqualTo [] && {[_spotter, "VIEW"] checkVisibility [_eye, (ATLToASL _impact) vectorAdd [0, 0, 1]] < 0.5}) exitWith {[]};
_spotter doWatch _enemy;
_spotter selectWeapon (binocular _spotter);
[_spotter getHideFrom _enemy, _knowledge select 5]
