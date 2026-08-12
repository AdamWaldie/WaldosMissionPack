/*
 * Author: WaldoTheWarfighter
 * Zeus module handler: lets a curator hand a specific nearby AI group off to a specific destination
 * (auto-balance, back to the server, or a named connected headless client) right now, instead of
 * waiting for the next automatic Waldo_fnc_HeadlessRebalance pass. Builds its group/destination lists
 * fresh every time the dialog opens, same pattern as Waldo_fnc_ZenJammerPlace's emitter-class list.
 * The actual move is applied server-side by Waldo_fnc_HeadlessManualHandoff, which still refuses any
 * group with a human player leader/member and still routes through the single
 * Waldo_fnc_HeadlessMigrateGroup funnel.
 *
 * Arguments:
 * 0: modulePos <ARRAY> - position the curator placed the module; also the search origin for nearby
 *    eligible groups.
 * 1: objectPos <OBJECT> - object the module was dropped on (unused).
 *
 * Return Value:
 * Nothing - the dialog forwards an authorised handoff request to the server.
 *
 * Example:
 * [_modulePos, _objectPos] call Waldo_fnc_ZenHeadlessManualHandoff;
 *
 * Public: No
 */

if !(isClass (configFile >> "CfgPatches" >> "zen_main")) exitWith {};

params ["_modulePos", "_objectPos"];

private _notify = {
    params ["_message"];
    [createHashMapFromArray [
        ["title", "HEADLESS CLIENT"], ["message", _message], ["state", "WARNING"], ["duration", 8],
        ["placement", "TOP"], ["channel", "HEADLESS_DEBUG"], ["source", "ZEUS"],
        ["audience", "UNITS"], ["units", [player]]
    ]] call Waldo_fnc_NotificationBroadcast;
};

if !(missionNamespace getVariable ["Waldo_Headless_Enable", false]) exitWith {
    ["Headless Client Support is not enabled on this mission."] call _notify;
};

private _eligibleGroups = allGroups select {
    count units _x > 0
    && {side _x != sideLogic}
    && {(units _x) findIf {isPlayer _x} < 0}
};
_eligibleGroups = _eligibleGroups apply {[_x, _modulePos distance (leader _x)]};
_eligibleGroups = [_eligibleGroups, [], {_x select 1}, "ASCEND"] call BIS_fnc_sortBy;
_eligibleGroups = _eligibleGroups select [0, 10 min (count _eligibleGroups)];

if (_eligibleGroups isEqualTo []) exitWith {
    ["No eligible AI group (no human leader/member) was found nearby."] call _notify;
};

private _groupValues = _eligibleGroups apply {_x select 0};
private _groupLabels = _eligibleGroups apply {
    _x params ["_group", "_dist"];
    format ["%1 (%2 units) - %3m", groupId _group, count units _group, round _dist]
};

private _clients = missionNamespace getVariable ["Waldo_Headless_Clients", []];
private _destValues = ["AUTO", "SERVER"] + (_clients apply {_x select 0});
private _destLabels = [
    ["Auto (best load)", "Send to whichever connected headless client currently has the fewest managed groups."],
    ["Return to Server", "Move this group back to the server."]
] + (_clients apply {_x params ["_owner", "_label"]; [format ["%1 (owner %2)", _label, _owner], "Send directly to this connected headless client."]});

[
    "Headless Client - Manual Handoff",
    [
        ["LIST", ["Group", "Nearby AI groups without a human player leader/member, nearest first."], [_groupValues, _groupLabels, 0, 6]],
        ["LIST", ["Destination", "Where to send the selected group."], [_destValues, _destLabels, 0, 4]]
    ],
    {
        params ["_args"];
        // Both LIST controls above return the selected VALUE directly (matching every other LIST
        // usage in this codebase, e.g. Zen_jammerPlaceModule.sqf's emitter-class LIST), not an index.
        _args params ["_group", "_destination"];
        if (isNull _group) exitWith {
            [createHashMapFromArray [
                ["title", "HEADLESS CLIENT"], ["message", "That group no longer exists."], ["state", "WARNING"],
                ["duration", 8], ["placement", "TOP"], ["channel", "HEADLESS_DEBUG"], ["source", "ZEUS"],
                ["audience", "UNITS"], ["units", [player]]
            ]] call Waldo_fnc_NotificationBroadcast;
        };
        diag_log format ["[WMP ZEN] invoked module=Headless Client Manual Handoff curator=%1 group=%2 destination=%3", name player, _group, _destination];
        [_group, _destination] remoteExecCall ["Waldo_fnc_HeadlessManualHandoff", 2];
    },
    {}
] call zen_dialog_fnc_create;
