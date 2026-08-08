/*
 * Author: WaldoTheWarfighter
 * Zeus module handler: gathers title/message/type/duration/placement and audience, then forwards to
 * Waldo_fnc_ZenNotifyServer. The "Selected Unit(s)" audience uses whichever player units are
 * currently selected in Zeus (curatorSelected), falling back to the object the module was dropped on.
 *
 * Arguments:
 * 0: modulePos <ARRAY> - position the curator placed the module.
 * 1: objectPos <OBJECT> - object the module was dropped on; used as a Selected Unit(s) fallback so
 *    dropping the module directly on one player works without opening the Zeus selection list first.
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
        ["COMBO", ["Audience", "Who receives this card."],
            [["ALL", "SIDE", "GROUP", "UNITS"], ["All Players", "By Side", "By Group", "Selected Unit(s)"], 0], false],
        ["COMBO", ["Side (if By Side)", "Used only when Audience is By Side."],
            [["WEST", "EAST", "IND", "CIV"], ["BLUFOR", "OPFOR", "INDFOR", "CIVILIAN"], 0], false],
        ["EDIT", ["Group name (if By Group)", "Matched against each unit's group callsign, case-insensitive."], ""]
    ],
    {
        params ["_args", "_pos"];
        _args params ["_title", "_message", "_state", "_duration", "_placement", "_audience", "_sideStr", "_group"];
        _pos params ["_modulePos", "_objectPos"];
        private _units = [];
        if (_audience == "UNITS") then {
            private _curator = getAssignedCuratorLogic player;
            if !(isNull _curator) then {
                _units = (curatorSelected select 0) select {isPlayer _x};
            };
            if (_units isEqualTo [] && {!isNull _objectPos} && {isPlayer _objectPos}) then {_units = [_objectPos];};
        };
        private _sideIndex = ["WEST", "EAST", "IND", "CIV"] find _sideStr;
        private _side = [west, east, independent, civilian] select (_sideIndex max 0);
        private _config = createHashMapFromArray [
            ["title", _title], ["message", _message], ["state", _state], ["duration", _duration],
            ["placement", _placement], ["audience", _audience], ["side", _side], ["group", _group], ["units", _units]
        ];
        [_config, player] remoteExecCall ["Waldo_fnc_ZenNotifyServer", 2];
        diag_log format ["[WMP ZEN] invoked module=Send Notification curator=%1 audience=%2 title=%3", name player, _audience, _title];
    },
    {},
    [_modulePos, _objectPos]
] call zen_dialog_fnc_create;
