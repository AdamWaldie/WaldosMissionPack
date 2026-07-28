/*
 * Author: Waldo
 * Installs an opt-in, configurable friendly identification overlay for eligible players.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Boolean - true when installed for this player
 *
 * Example:
 * [] call Waldo_fnc_AccessibilityPIDInit;
 */

if !(hasInterface) exitWith {false};
if !(missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", isServer]) exitWith {
    [] spawn {waitUntil {missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false]}; [] call Waldo_fnc_AccessibilityPIDInit};
    true
};
if !(missionNamespace getVariable ["Waldo_AccessibilityPID_Enable", false]) exitWith {false};
if (missionNamespace getVariable ["Waldo_AccessibilityPID_ClientStarted", false]) exitWith {true};

private _allowed = missionNamespace getVariable ["Waldo_AccessibilityPID_AllowedUIDs", []];
if (count _allowed > 0 && {getPlayerUID player notIn _allowed}) exitWith {false};

missionNamespace setVariable ["Waldo_AccessibilityPID_ClientStarted", true];
missionNamespace setVariable [
    "Waldo_AccessibilityPID_Visible",
    missionNamespace getVariable ["Waldo_AccessibilityPID_DefaultVisible", true]
];

private _eventId = addMissionEventHandler ["Draw3D", {
    if !(missionNamespace getVariable ["Waldo_AccessibilityPID_Visible", false]) exitWith {};
    private _iconRange = missionNamespace getVariable ["Waldo_AccessibilityPID_IconRange", 300];
    private _nameRange = missionNamespace getVariable ["Waldo_AccessibilityPID_NameRange", 50];
    private _requiresLOS = missionNamespace getVariable ["Waldo_AccessibilityPID_RequireLOS", true];
    private _includeAI = missionNamespace getVariable ["Waldo_AccessibilityPID_IncludeAI", false];
    private _units = if (_includeAI) then {allUnits} else {allPlayers};
    private _colour = missionNamespace getVariable ["Waldo_AccessibilityPID_Colour", [0.25, 0.85, 1, 0.9]];
    private _iconScale = missionNamespace getVariable ["Waldo_AccessibilityPID_IconScale", 0.8];
    private _textScale = missionNamespace getVariable ["Waldo_AccessibilityPID_TextScale", 0.035];
    private _distanceFade = missionNamespace getVariable ["Waldo_AccessibilityPID_DistanceFade", true];
    private _groupOnly = missionNamespace getVariable ["Waldo_AccessibilityPID_GroupOnly", false];
    private _showIncapacitated = missionNamespace getVariable ["Waldo_AccessibilityPID_ShowIncapacitated", true];
    private _showIcons = missionNamespace getVariable ["Waldo_AccessibilityPID_ShowIcons", true];
    private _showNames = missionNamespace getVariable ["Waldo_AccessibilityPID_ShowNames", true];
    private _showVehicleCrew = missionNamespace getVariable ["Waldo_AccessibilityPID_ShowVehicleCrew", false];
    private _icon = missionNamespace getVariable [
        "Waldo_AccessibilityPID_Icon",
        "\a3\ui_f\data\igui\cfg\actions\getincommander_ca.paa"
    ];

    {
        private _unit = _x;
        private _distance = player distance _unit;
        private _friendly = (side group player) getFriend (side group _unit) >= 0.6;
        private _eligibleGroup = !_groupOnly || {group _unit isEqualTo group player};
        private _eligibleMedical = _showIncapacitated || {!(_unit getVariable ["ACE_isUnconscious", false])};
        private _eligibleVehicle = _showVehicleCrew || {vehicle _unit == _unit};
        if (_unit != player && {alive _unit} && {_friendly} && {_eligibleGroup} && {_eligibleMedical} && {_eligibleVehicle} && {_distance <= _iconRange}) then {
            private _visible = true;
            if (_requiresLOS) then {
                _visible = [player, "VIEW"] checkVisibility [eyePos player, eyePos _unit] > 0.25;
            };
            if (_visible) then {
                private _position = getPosATLVisual _unit;
                _position set [2, (_position select 2) + 2.1];
                private _text = if (_showNames && {_distance <= _nameRange}) then {name _unit} else {""};
                private _drawColour = +_colour;
                if (_distanceFade) then {_drawColour set [3, (_drawColour select 3) * (1 - ((_distance / _iconRange) min 0.85))]};
                drawIcon3D [if (_showIcons) then {_icon} else {""}, _drawColour, _position, _iconScale, _iconScale, 0, _text, 2, _textScale, "RobotoCondensed", "center"];
            };
        };
    } forEach _units;
}];
missionNamespace setVariable ["Waldo_AccessibilityPID_EventId", _eventId];

if (missionNamespace getVariable ["Waldo_AccessibilityPID_AllowToggle", true]) then {
    private _actionId = player addAction [
        "Toggle Friendly Identification Aid",
        {[] call Waldo_fnc_AccessibilityPIDToggle},
        [],
        -10,
        false,
        true,
        "",
        "true"
    ];
    player setVariable ["Waldo_AccessibilityPID_ActionId", _actionId];
};
true
