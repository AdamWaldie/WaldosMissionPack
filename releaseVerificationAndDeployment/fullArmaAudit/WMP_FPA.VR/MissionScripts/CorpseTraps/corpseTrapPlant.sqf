/*
 * Starts the local ACE planting progress action. The magazine is consumed only
 * after the progress action completes.
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
