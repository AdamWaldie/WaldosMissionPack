/*
 * Author: WaldoTheWarfighter
 * Zeus module handler: gathers title/message/type/duration/placement and recipients, then forwards
 * to Waldo_fnc_ZenNotifyServer. Recipients use ZEN's native OWNERS dialog control - one field, one
 * dialog, with its own Sides/Groups/Players tabs and live multi-select lists built by ZEN itself, so
 * a curator can mix e.g. one side with a couple of extra individual players in a single pass instead
 * of picking exactly one audience type up front. "Send to all players" is a separate checkbox because
 * OWNERS has no "everyone, no picking" state of its own; when checked, the OWNERS selection is
 * ignored. Any picked sides/groups/players are resolved into one deduplicated unit list and sent as
 * a single UNITS notification, so a player who is both on a selected side and individually selected
 * is never notified twice.
 *
 * Arguments:
 * 0: modulePos <ARRAY> - position the curator placed the module.
 * 1: objectPos <OBJECT> - object the module was dropped on; pre-selects that player in the OWNERS
 *    picker so dropping the module directly on one player works without opening it first.
 *
 * Return Value:
 * Nothing - a valid dialog forwards the composed config to Waldo_fnc_ZenNotifyServer.
 *
 * Example:
 * [_modulePos, _objectPos] call Waldo_fnc_ZenNotify;
 *
 * Current caller: the ZEN "Mission Flow: Send Notification" module.
 */

if !(isClass (configFile >> "CfgPatches" >> "zen_main")) exitWith {};

params ["_modulePos", "_objectPos"];

private _defaultPlayers = if (!isNull _objectPos && {isPlayer _objectPos}) then {[_objectPos]} else {[]};

[
    "Send Notification",
    [
        ["EDIT", ["Title", "Card title shown to the audience."], "MESSAGE FROM COMMAND"],
        ["EDIT", ["Message", "Card body text."], ""],
        ["COMBO", ["Type", "Notification state and colour."],
            [["INFO", "SUCCESS", "WARNING", "ERROR"], ["Info", "Success", "Warning", "Error"], 0], false],
        ["SLIDER", ["Duration (s)", "0 keeps the card on screen until replaced."], [0, 60, 8, 0], false],
        ["COMBO", ["Placement", "Where the card appears on screen."],
            [
                ["TOP", "TOP_RIGHT", "CENTER", "BOTTOM_LEFT", "BOTTOM_CENTER", "BOTTOM_RIGHT"],
                ["Top", "Top Right", "Centre", "Bottom Left", "Bottom Centre", "Bottom Right"],
                0
            ], false],
        ["CHECKBOX", ["Send to all players", "Ignores the picker below and reaches every connected player."], false],
        // OWNERS valueInfo is [sides, groups, players, openTab]. The row's fourth field is instead
        // ZEN's forceDefault BOOL, so the tab index must remain inside valueInfo.
        ["OWNERS", ["Recipients (if not sending to all)", "Pick any mix of sides, groups and individual players."], [[], [], _defaultPlayers, 2], false]
    ],
    {
        params ["_args", "_pos"];
        _args params ["_title", "_message", "_state", "_duration", "_placement", "_all", "_owners"];
        _owners params ["_sides", "_groups", "_players"];
        private _config = createHashMapFromArray [
            ["title", _title], ["message", _message], ["state", _state], ["duration", _duration], ["placement", _placement]
        ];
        if (_all) then {
            _config set ["audience", "ALL"];
        } else {
            // Resolve every picked side/group/player into one deduplicated unit list up front, rather
            // than issuing one broadcast per side/group/player - a player covered by more than one
            // selection (e.g. picked individually AND on a picked side) would otherwise be notified
            // more than once.
            private _units = [];
            {
                private _side = _x;
                _units append (allPlayers select {side group _x == _side});
            } forEach _sides;
            {_units append ((units _x) select {isPlayer _x})} forEach _groups;
            {_units pushBackUnique _x} forEach _players;
            _units = _units arrayIntersect _units;
            _config set ["audience", "UNITS"];
            _config set ["units", _units];
        };
        [_config, player] remoteExecCall ["Waldo_fnc_ZenNotifyServer", 2];
        diag_log format ["[WMP ZEN] invoked module=Send Notification curator=%1 all=%2 sides=%3 groups=%4 players=%5 title=%6", name player, _all, count _sides, count _groups, count _players, _title];
    },
    {},
    [_modulePos, _objectPos]
] call zen_dialog_fnc_create;
