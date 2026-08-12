/*
 * Author: WaldoTheWarfighter
 * Builds the dynamic ACE self-interaction child list for the "Pronounce Dead" submenu: every
 * eligible corpse (a cached player death, not yet pronounced) within Waldo_Obituary_Radius of the
 * player, nearest first, each shown as its own named row keyed to that exact corpse - so a medic
 * standing over several bodies (a firefight pile-up) pronounces precisely the one they mean instead
 * of a single blind "nearest" action guessing for them. Reused directly by Waldo_fnc_ObituaryPronounce
 * (unchanged) once a specific row is selected.
 * Locality and authority: interface-client display filtering only, matching
 * Waldo_fnc_TransportAvailableChildrenLocal's own pattern; the actual pronouncement remains
 * server-authoritative and idempotent per corpse.
 *
 * Arguments:
 * 0: Player <OBJECT>
 *
 * Return Value: <ARRAY> - ACE dynamic child-action rows, one per eligible nearby corpse.
 * Example: [player] call Waldo_fnc_ObituaryChildrenLocal;
 * Current caller: the "Pronounce Dead" self-action root installed by
 * Waldo_fnc_ObituarySelfInteractionInit.
 */

params [["_player", objNull, [objNull]]];
if (!hasInterface || {isNull _player}) exitWith {[]};
if !(_player getUnitTrait "Medic") exitWith {[]};

private _radius = missionNamespace getVariable ["Waldo_Obituary_Radius", 15];
private _corpses = (nearestObjects [_player, ["CAManBase"], _radius]) select {
    !alive _x && {!(_x getVariable ["Waldo_Obituary_Complete", true])}
};
_corpses = [_corpses, [], {_player distance _x}, "ASCEND"] call BIS_fnc_sortBy;

private _children = [];
{
    private _corpse = _x;
    private _deathInfo = _corpse getVariable ["Waldo_Obituary_DeathInfo", []];
    private _victimName = if (count _deathInfo > 1) then {_deathInfo select 1} else {"Unknown"};
    private _distance = round (_player distance _corpse);
    private _action = [
        format ["Waldo_Obituary_Pronounce_%1", netId _corpse],
        format ["%1 (%2m)", _victimName, _distance],
        "a3\ui_f\data\igui\cfg\actions\heal_ca.paa",
        {
            private _corpse = _this select 2;
            [_corpse, player] call Waldo_fnc_ObituaryPronounce;
        },
        {
            private _corpse = _this select 2;
            !isNull _corpse && {!alive _corpse} && {!(_corpse getVariable ["Waldo_Obituary_Complete", true])}
        },
        {},
        _corpse
    ] call ace_interact_menu_fnc_createAction;
    _children pushBack [_action, [], _corpse];
} forEach _corpses;
_children
