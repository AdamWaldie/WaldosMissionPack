/*
 * Author: Waldo
 * Adds a validated ammunition grant to the local player's inventory.
 *
 * Arguments: 0: magazine classes <ARRAY>; 1: count per class <NUMBER>
 * Return Value: Number
 */

params [["_classes", [], [[]]], ["_countPerClass", 1, [0]]];
if !(hasInterface) exitWith {0};
if (remoteExecutedOwner != 2) exitWith {0};
private _added = 0;
{
    for "_i" from 1 to (round _countPerClass max 0) do {
        if (player canAdd _x) then {player addMagazine _x; _added = _added + 1};
    };
} forEach _classes;
["FIELD RESUPPLY", format ["Received %1 compatible magazine(s).", _added], "SUCCESS", "FIELD_RESUPPLY"] call Waldo_fnc_FeatureNotifyLocal;
_added
