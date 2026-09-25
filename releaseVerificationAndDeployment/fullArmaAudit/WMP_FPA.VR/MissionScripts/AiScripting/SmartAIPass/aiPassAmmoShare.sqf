/*
 * Author: WaldoTheWarfighter
 * Redistributes rifle magazines inside a squad, from Smart Combat V2's squad logistics.
 *
 * A soldier with one spare magazine or fewer for his primary weapon receives one from a squad-mate
 * within Waldo_AIPass_AmmoShare_Distance who has at least four spare magazines his weapon accepts.
 * The magazine keeps its actual round count, and is only moved if the receiver has room for it. At
 * most two transfers happen per call, and a squad is checked at most every 20 s. Vehicle cargo is not
 * used.
 * Locality and authority: call where the group is local; both soldiers must be local.
 *
 * Arguments:
 * 0: group <GROUP>
 * 1: state <HASHMAP>
 *
 * Return Value:
 * Number - magazines transferred
 *
 * Example:
 * [_group, _state] call Waldo_fnc_AIPassAmmoShare;
 * Result: the rifleman who has shot himself dry gets a magazine from the machine gunner's assistant.
 *
 * Current caller: Waldo_fnc_AIPassGroupTick.
 */

params [["_group", grpNull, [grpNull]], ["_state", createHashMap, [createHashMap]]];
if ([_state, "ammo"] call Waldo_fnc_AIPassCooldown) exitWith {0};
[_state, "ammo", 20] call Waldo_fnc_AIPassCooldown;
private _range = missionNamespace getVariable ["Waldo_AIPass_AmmoShare_Distance", 10];
private _members = (units _group) select {alive _x && {local _x} && {vehicle _x == _x} && {primaryWeapon _x != ""}};
private _transfers = 0;
{
    if (_transfers >= 2) exitWith {};
    private _receiver = _x;
    private _compatible = compatibleMagazines (primaryWeapon _receiver);
    if (({(_x select 0) in _compatible} count (magazinesAmmo _receiver)) <= 1) then {
        {
            private _donor = _x;
            if (_donor != _receiver && {_donor distance _receiver <= _range}) then {
                private _spare = (magazinesAmmo _donor) select {(_x select 0) in _compatible};
                if (count _spare >= 4) then {
                    (_spare select 0) params ["_magazine", "_rounds"];
                    if (_receiver canAdd _magazine) then {
                        _donor removeMagazine _magazine;
                        _receiver addMagazine [_magazine, _rounds];
                        _transfers = _transfers + 1;
                    };
                };
            };
            if (_transfers > 0 && {({(_x select 0) in _compatible} count (magazinesAmmo _receiver)) > 1}) exitWith {};
        } forEach _members;
    };
} forEach _members;
if (_transfers > 0) then {
    missionNamespace setVariable ["Waldo_AIPass_MagazinesShared", (missionNamespace getVariable ["Waldo_AIPass_MagazinesShared", 0]) + _transfers];
};
_transfers
