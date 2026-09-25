/*
 * Author: WaldoTheWarfighter
 * Installs, on each player's machine, the curator event handlers that give Zeus priority over the
 * Smart AI Pass.
 *
 * Whenever this player's Zeus interface opens (ZEN's zen_curatorDisplayLoaded event), the assigned
 * curator logic gets these handlers once:
 * - group and object selection;
 * - group and object double-click (attributes);
 * - object edited (moved or rotated);
 * - waypoint placed, edited and deleted.
 * Each calls Waldo_fnc_AIPassZeusMark for the affected group, so the pass releases it and leaves it
 * alone while Zeus commands it. Curator event handlers fire only on the curator's machine, which is why
 * this runs on clients even though the pass itself never does. The handlers cost nothing until Zeus
 * acts, and send nothing while the pass is disabled.
 * Locality and authority: interface clients only; repeat-safe, JIP-safe.
 *
 * Arguments: None.
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_AIPassZeusWatchLocal;
 * Result: this player's Zeus orders always take priority over the pass.
 *
 * Current caller: initPlayerLocal.sqf.
 */

if (!hasInterface || {missionNamespace getVariable ["Waldo_AIPass_ZeusWatchInstalled", false]}) exitWith {};
missionNamespace setVariable ["Waldo_AIPass_ZeusWatchInstalled", true];
private _install = {
    private _curator = getAssignedCuratorLogic player;
    if (isNull _curator || {_curator getVariable ["Waldo_AIPass_ZeusHandlers", false]}) exitWith {};
    _curator setVariable ["Waldo_AIPass_ZeusHandlers", true];
    private _objectGroup = {
        params ["_object"];
        if (isNull _object) exitWith {grpNull};
        if (_object isKindOf "CAManBase") exitWith {group _object};
        group effectiveCommander _object
    };
    missionNamespace setVariable ["Waldo_AIPass_ZeusObjectGroup", _objectGroup];
    _curator addEventHandler ["CuratorGroupSelectionChanged", {params ["", "_group"]; [_group] call Waldo_fnc_AIPassZeusMark}];
    _curator addEventHandler ["CuratorGroupDoubleClicked", {params ["", "_group"]; [_group] call Waldo_fnc_AIPassZeusMark}];
    {
        _curator addEventHandler [_x, {
            params ["", "_entity"];
            [[_entity] call (missionNamespace getVariable ["Waldo_AIPass_ZeusObjectGroup", {grpNull}])] call Waldo_fnc_AIPassZeusMark;
        }];
    } forEach ["CuratorObjectSelectionChanged", "CuratorObjectDoubleClicked", "CuratorObjectEdited"];
    _curator addEventHandler ["CuratorWaypointPlaced", {params ["", "_group"]; [_group, true] call Waldo_fnc_AIPassZeusMark}];
    {
        _curator addEventHandler [_x, {
            params ["", "_waypoint"];
            if (_waypoint isEqualType [] && {count _waypoint >= 1}) then {[_waypoint select 0, true] call Waldo_fnc_AIPassZeusMark};
        }];
    } forEach ["CuratorWaypointEdited", "CuratorWaypointDeleted"];
};
["zen_curatorDisplayLoaded", _install] call CBA_fnc_addEventHandler;
call _install;
