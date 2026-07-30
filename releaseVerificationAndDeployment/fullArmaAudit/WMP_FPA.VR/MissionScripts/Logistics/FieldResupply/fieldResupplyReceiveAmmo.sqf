/*
 * Author: WaldoTheWarfighter
 * Adds a server-authorized Field Resupply ammunition grant to the local player's inventory.
 *
 * Each row carries its own quantity so rifles, pistols, launchers, machine guns and large boxes can
 * receive useful but distinct amounts. Inventory mutation stays on the owning client because
 * `canAdd` and local containers must be evaluated there. Requests not sent by the server are
 * rejected. Items that do not fit are skipped and the notification reports the actual added total.
 *
 * Arguments:
 * 0: grant rows <ARRAY> - entries in `[magazine class <STRING>, quantity <NUMBER>]` format.
 *
 * Return Value:
 * Number - total magazines actually added to the local player.
 *
 * Example:
 * [[['30Rnd_65x39_caseless_mag', 8]]] remoteExecCall
 *     ["Waldo_fnc_FieldResupplyReceiveAmmo", owner _unit];
 *
 * Current caller: FieldResupplyServerHandle after an authoritative TAKE operation.
 */

params [["_rows", [], [[]]]];
if !(hasInterface) exitWith {0};
if (remoteExecutedOwner != 2) exitWith {0};
private _added = 0;
{
    _x params [["_class", "", [""]], ["_quantity", 0, [0]]];
    if (isClass (configFile >> "CfgMagazines" >> _class)) then {
        for "_i" from 1 to (round _quantity max 0) do {
            if (player canAdd _class) then {
                player addMagazine _class;
                _added = _added + 1;
            };
        };
    };
} forEach _rows;
[
    "FIELD RESUPPLY",
    format ["Received %1 compatible magazine(s).", _added],
    ["WARNING", "SUCCESS"] select (_added > 0),
    "FIELD_RESUPPLY"
] call Waldo_fnc_FeatureNotifyLocal;
_added
