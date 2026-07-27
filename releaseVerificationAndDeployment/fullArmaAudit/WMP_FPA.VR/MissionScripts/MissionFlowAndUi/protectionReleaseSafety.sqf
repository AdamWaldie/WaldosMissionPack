/*
 * Author: WaldoTheWarfighter
 * Releases one WMP ACE-safety claim. The exact weapon and muzzle captured when
 * the claim was created are used, and ACE is called only while that exact entry
 * still exists. This prevents stale-current-weapon errors in ACE safemode.
 */
params [["_source", "", [""]]];

if (!hasInterface || {_source isEqualTo ""}) exitWith {false};
private _claims = +(player getVariable ["Waldo_WMPProtection_SafetyClaims", []]);
private _claimIndex = _claims findIf {(_x param [0, ""]) isEqualTo _source};
if (_claimIndex < 0) exitWith {false};

private _claim = _claims deleteAt _claimIndex;
_claim params ["_claimSource", "_weapon", "_muzzle"];
player setVariable ["Waldo_WMPProtection_SafetyClaims", _claims];

private _hasRemainingClaim = (_claims findIf {
    (_x param [1, ""]) isEqualTo _weapon && {(_x param [2, ""]) isEqualTo _muzzle}
}) >= 0;
if (_hasRemainingClaim) exitWith {true};

private _owned = +(player getVariable ["Waldo_WMPProtection_OwnedSafety", []]);
private _ownedIndex = _owned findIf {
    (_x param [0, ""]) isEqualTo _weapon && {(_x param [1, ""]) isEqualTo _muzzle}
};
if (_ownedIndex < 0) exitWith {true};
_owned deleteAt _ownedIndex;
player setVariable ["Waldo_WMPProtection_OwnedSafety", _owned];

if (isNil "ace_safemode_fnc_unlockSafety") exitWith {true};
private _safedWeapons = player getVariable ["ace_safemode_safedWeapons", createHashMap];
private _stillSafed = false;
if (_safedWeapons isEqualType createHashMap) then {
    private _safedMuzzles = _safedWeapons getOrDefault [_weapon, createHashMap];
    if (_safedMuzzles isEqualType createHashMap) then {
        _stillSafed = _muzzle in _safedMuzzles;
    };
} else {
    if (_safedWeapons isEqualType []) then {_stillSafed = _weapon in _safedWeapons;};
};

if (_stillSafed) then {
    [player, _weapon, _muzzle] call ace_safemode_fnc_unlockSafety;
};
true
