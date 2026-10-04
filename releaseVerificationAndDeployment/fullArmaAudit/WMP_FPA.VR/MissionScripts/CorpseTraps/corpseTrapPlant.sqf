/*
 * Author: WaldoTheWarfighter
 * Starts ACE's corpse-trap planting progress action, consuming the selected throwable afterward.
 * Locality and authority: Runs for the interacting player; the server still verifies the completed
 * request before marking the corpse armed.
 * Repeat/JIP: Each invocation starts one progress action. A previously armed corpse is rejected;
 * this function installs no persistent handler for joining clients.
 * Arguments:
 * 0: dead target <OBJECT> (default objNull)
 * 1: planting player <OBJECT> (default objNull)
 * 2: throwable pair <ARRAY> [magazine class <STRING>, ammo class <STRING>] (default [])
 * Return Value: <BOOL> - true when ACE progress starts; false when initial checks fail.
 * Current caller: Waldo_fnc_CorpseTrapInit dynamic ACE throwable child action.
 * Example: [_corpse, player, ["HandGrenade", "GrenadeHand"]] call Waldo_fnc_CorpseTrapPlant;
 * Result: On completed progress, one magazine is spent and the server receives an arm request.
 */
params [
    ["_corpse", objNull, [objNull]],
    ["_actor", objNull, [objNull]],
    ["_throwable", [], [[]]]
];
_throwable params [
    ["_magazine", "", [""]],
    ["_ammo", "", [""]]
];

if (isNull _corpse || {isNull _actor}) exitWith {false};
if (alive _corpse || {!alive _actor}) exitWith {false};
if (_actor distance _corpse > 3 || {!(_magazine in magazines _actor)}) exitWith {false};
if (_corpse getVariable ["Waldo_CorpseTrap_State", ""] != "") exitWith {false};

[_corpse, "Waldo_CorpseTrap_Plant"] remoteExecCall ["say3D", 0];

[
    3,
    [_corpse, _actor, _magazine, _ammo],
    {
        params ["_args"];
        _args params ["_corpse", "_actor", "_magazine", "_ammo"];
        if !(_magazine in magazines _actor) exitWith {
            systemChat "Corpse trap cancelled: the selected throwable is no longer available.";
        };
        _actor removeMagazine _magazine;
        [_corpse, _actor, _magazine, _ammo] remoteExecCall ["Waldo_fnc_CorpseTrapArmServer", 2];
    },
    {},
    "Rigging corpse...",
    {
        params ["_args"];
        _args params ["_corpse", "_actor", "_magazine"];
        !isNull _corpse
            && {!alive _corpse}
            && {alive _actor}
            && {_actor distance _corpse <= 3}
            && {_corpse getVariable ["Waldo_CorpseTrap_State", ""] == ""}
            && {_magazine in magazines _actor}
    }
] call ace_common_fnc_progressBar;

true
