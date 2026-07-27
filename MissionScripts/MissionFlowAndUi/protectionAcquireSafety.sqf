/*
 * Author: WaldoTheWarfighter
 * Claims ACE weapon safety for one WMP protection source. Claims are reference
 * counted so SafeStart and ENDEX cannot release each other's safety state.
 * Only safety states added by WMP are later removed by WMP.
 */
params [["_source", "", [""]]];

if (!hasInterface || {_source isEqualTo ""}) exitWith {false};
if (isNil "ace_safemode_fnc_lockSafety") exitWith {false};

private _weapon = currentWeapon player;
private _muzzle = currentMuzzle player;
if (_weapon isEqualTo "" || {_muzzle isEqualTo ""}) exitWith {false};

private _claims = +(player getVariable ["Waldo_WMPProtection_SafetyClaims", []]);
if ((_claims findIf {(_x param [0, ""]) isEqualTo _source}) >= 0) exitWith {true};

private _safedWeapons = player getVariable ["ace_safemode_safedWeapons", createHashMap];
private _alreadySafed = false;
if (_safedWeapons isEqualType createHashMap) then {
    private _safedMuzzles = _safedWeapons getOrDefault [_weapon, createHashMap];
    if (_safedMuzzles isEqualType createHashMap) then {
        _alreadySafed = _muzzle in _safedMuzzles;
    };
} else {
    // Compatibility with older ACE versions which exposed weapon names only.
    if (_safedWeapons isEqualType []) then {_alreadySafed = _weapon in _safedWeapons;};
};

if (!_alreadySafed) then {
    [player, _weapon, _muzzle] call ace_safemode_fnc_lockSafety;
    private _owned = +(player getVariable ["Waldo_WMPProtection_OwnedSafety", []]);
    _owned pushBackUnique [_weapon, _muzzle];
    player setVariable ["Waldo_WMPProtection_OwnedSafety", _owned];
};

_claims pushBack [_source, _weapon, _muzzle];
player setVariable ["Waldo_WMPProtection_SafetyClaims", _claims];
true
