/*
 * Author: WaldoTheWarfighter
 * Installs an opt-in, configurable friendly identification overlay for eligible players. The
 * default TAG presentation uses a bold two-pass text label with a tight dark outline, distance-
 * compensated sizing and a short far-range friendly glyph. ICON preserves the former marker and
 * HYBRID combines both. All drawing remains local, theme/colour-vision aware and repeat-safe.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Boolean - true when installed for this player
 *
 * Example:
 * [] call Waldo_fnc_AccessibilityPIDInit;
 *
 * Current callers: initPlayerLocal.sqf after the ordered runtime snapshot, the Accessibility QA
 * station, runtime reconfiguration, and the local EntityRespawned handler below.
 */

if !(hasInterface) exitWith {false};
if !(missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", isServer]) exitWith {
    [] spawn {
        waitUntil {
            missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false]
            || {missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotFailed", false]}
        };
        if (missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false]) then {[] call Waldo_fnc_AccessibilityPIDInit};
    };
    true
};
if !(missionNamespace getVariable ["Waldo_AccessibilityPID_Enable", false]) exitWith {false};
if (missionNamespace getVariable ["Waldo_AccessibilityPID_ClientStarted", false]) exitWith {true};

private _allowed = missionNamespace getVariable ["Waldo_AccessibilityPID_AllowedUIDs", []];
if (count _allowed > 0 && {!(getPlayerUID player in _allowed)}) exitWith {false};

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
    private _themeColour = +(([] call Waldo_fnc_UiTheme) getOrDefault ["accentActive", [0.25, 0.85, 1, 1]]);
    _themeColour set [3, 0.9];
    private _colour = missionNamespace getVariable ["Waldo_AccessibilityPID_Colour", _themeColour];
    private _iconScale = missionNamespace getVariable ["Waldo_AccessibilityPID_IconScale", 0.8];
    private _textScale = missionNamespace getVariable ["Waldo_AccessibilityPID_TextScale", 0.035];
    private _distanceFade = missionNamespace getVariable ["Waldo_AccessibilityPID_DistanceFade", true];
    private _groupOnly = missionNamespace getVariable ["Waldo_AccessibilityPID_GroupOnly", false];
    private _showIncapacitated = missionNamespace getVariable ["Waldo_AccessibilityPID_ShowIncapacitated", true];
    private _showIcons = missionNamespace getVariable ["Waldo_AccessibilityPID_ShowIcons", true];
    private _showNames = missionNamespace getVariable ["Waldo_AccessibilityPID_ShowNames", true];
    private _showVehicleCrew = missionNamespace getVariable ["Waldo_AccessibilityPID_ShowVehicleCrew", false];
    private _style = toUpperANSI (missionNamespace getVariable ["Waldo_AccessibilityPID_Style", "TAG"]);
    if !(_style in ["TAG", "ICON", "HYBRID"]) then {_style = "TAG";};
    private _farLabel = missionNamespace getVariable ["Waldo_AccessibilityPID_FarLabel", "F"];
    private _font = missionNamespace getVariable ["Waldo_AccessibilityPID_Font", "PuristaBold"];
    private _textGrowth = missionNamespace getVariable ["Waldo_AccessibilityPID_TextDistanceGrowth", 0.0008];
    private _textMaximum = missionNamespace getVariable ["Waldo_AccessibilityPID_TextMaximumScale", 0.07];
    private _outlineScale = missionNamespace getVariable ["Waldo_AccessibilityPID_OutlineScale", 1.12];
    private _outlineColour = +(missionNamespace getVariable ["Waldo_AccessibilityPID_OutlineColour", [0.03, 0.03, 0.03, 1]]);
    private _icon = missionNamespace getVariable [
        "Waldo_AccessibilityPID_Icon",
        "\a3\ui_f\data\igui\cfg\actions\getincommander_ca.paa"
    ];
    // drawIcon3D still evaluates icon metadata for a text-only call. A valid marker with zero
    // dimensions avoids per-frame missing-size diagnostics without rendering another symbol.
    private _textAnchorIcon = getText (configFile >> "CfgMarkers" >> "mil_dot" >> "icon");

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
                private _drawColour = +_colour;
                if (_distanceFade) then {_drawColour set [3, (_drawColour select 3) * (1 - ((_distance / _iconRange) min 0.85))]};
                if (_showIcons && {_style in ["ICON", "HYBRID"]}) then {
                    drawIcon3D [_icon, _drawColour, _position, _iconScale, _iconScale, 0, "", 1, 0, _font, "center"];
                };
                if (_showNames && {_style in ["TAG", "HYBRID"]}) then {
                    private _text = if (_distance <= _nameRange) then {name _unit} else {_farLabel};
                    if (_text != "") then {
                        private _drawTextScale = (_textScale + (_distance * (_textGrowth max 0))) min (_textMaximum max _textScale);
                        private _drawOutline = +_outlineColour;
                        _drawOutline set [3, (_drawOutline param [3, 1]) * (_drawColour param [3, 1])];
                        drawIcon3D [_textAnchorIcon, _drawOutline, _position, 0, 0, 0, _text, 0, _drawTextScale * (_outlineScale max 1), _font, "center"];
                        drawIcon3D [_textAnchorIcon, _drawColour, _position, 0, 0, 0, _text, 0, _drawTextScale, _font, "center"];
                    };
                };
            };
        };
    } forEach _units;
}];
missionNamespace setVariable ["Waldo_AccessibilityPID_EventId", _eventId];

// The shared Accessibility self-interaction owns the PID toggle and colour-vision selector.
// Its PID child becomes visible dynamically once this eligible client has started.
[] call Waldo_fnc_AccessibilitySelfInteractionInit;

if !(missionNamespace getVariable ["Waldo_AccessibilityPID_RespawnHandlerInstalled", false]) then {
    missionNamespace setVariable ["Waldo_AccessibilityPID_RespawnHandlerInstalled", true];
    private _respawnId = addMissionEventHandler ["EntityRespawned", {
        params ["_newEntity"];
        if (local _newEntity && {_newEntity isEqualTo player}) then {
            [] call Waldo_fnc_AccessibilityPIDStop;
            if (missionNamespace getVariable ["Waldo_AccessibilityPID_Enable", false]) then {
                [] call Waldo_fnc_AccessibilityPIDInit;
            };
        };
    }];
    missionNamespace setVariable ["Waldo_AccessibilityPID_RespawnHandlerId", _respawnId];
};
true
