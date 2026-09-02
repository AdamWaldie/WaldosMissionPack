/*
 * Author: WaldoTheWarfighter
 * Installs the dual-purpose WMP HUD on one interface client. During high-technology campaigns the
 * HUD is available while configured equipment is worn. Player preferences may only suppress or
 * resize mission-permitted presentation. Configured accessibility UIDs bypass that
 * equipment requirement so the same clear friendly icon/name presentation remains available in
 * every campaign. Drawing, visibility, colour-vision response and toggle state remain local; no
 * tactical information is published to other machines. Mission range, LOS, unit-scope and explicit
 * exclusions remain authoritative. Installation and respawn are repeat-safe.
 * Locality and authority: interface-client only; all drawing and visibility state remains local.
 *
 * Arguments: None.
 * Return Value: Boolean - true when installed or already running on this interface client.
 *
 * Example:
 * [] call Waldo_fnc_WmpHudInit;
 * Result: installs one local Draw3D handler and the WMP HUD self-interaction.
 * Current callers: initPlayerLocal.sqf after runtime configuration and the local respawn handler.
 */

if !(hasInterface) exitWith {false};
if !(missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", isServer]) exitWith {
    [] spawn {
        waitUntil {
            missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false]
            || {missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotFailed", false]}
        };
        if (missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false]) then {[] call Waldo_fnc_WmpHudInit};
    };
    true
};
if !(missionNamespace getVariable ["Waldo_WmpHud_Enable", false]) exitWith {false};
if (missionNamespace getVariable ["Waldo_WmpHud_ClientStarted", false]) exitWith {true};

missionNamespace setVariable ["Waldo_WmpHud_ClientStarted", true];
private _accessibilityUser = (getPlayerUID player) in (missionNamespace getVariable ["Waldo_WmpHud_AccessibilityUIDs", []]);
missionNamespace setVariable [
    "Waldo_WmpHud_Visible",
    missionNamespace getVariable ["Waldo_WmpHud_PlayerVisibleLocal", missionNamespace getVariable [
        if (_accessibilityUser) then {"Waldo_WmpHud_AccessibilityDefaultVisible"} else {"Waldo_WmpHud_DefaultVisible"}, true
    ]]
];

private _eventId = addMissionEventHandler ["Draw3D", {
    if !(missionNamespace getVariable ["Waldo_WmpHud_Visible", false]) exitWith {};
    if !([player] call Waldo_fnc_WmpHudEligible) exitWith {};
    private _iconRange = missionNamespace getVariable ["Waldo_WmpHud_IconRange", 300];
    private _nameRange = missionNamespace getVariable ["Waldo_WmpHud_NameRange", 50];
    private _requiresLOS = missionNamespace getVariable ["Waldo_WmpHud_RequireLOS", true];
    private _includeAI = missionNamespace getVariable ["Waldo_WmpHud_IncludeAI", false];
    private _units = if (_includeAI) then {allUnits} else {allPlayers};
    private _playerPreferences = [] call Waldo_fnc_WmpHudPreferences;
    private _themeColour = +(([] call Waldo_fnc_UiTheme) getOrDefault ["accentActive", [0.25, 0.85, 1, 1]]);
    _themeColour set [3, 0.9];
    private _configuredColour = missionNamespace getVariable ["Waldo_WmpHud_Colour", []];
    private _colour = if (_configuredColour isEqualType [] && {count _configuredColour == 4}) then {+_configuredColour} else {_themeColour};
    _colour set [3, (_colour param [3, 1]) * (_playerPreferences getOrDefault ["opacity", 0.82])];
    private _playerScale = _playerPreferences getOrDefault ["scale", 1];
    private _iconScale = (missionNamespace getVariable ["Waldo_WmpHud_IconScale", 0.8]) * _playerScale;
    private _textScale = (missionNamespace getVariable ["Waldo_WmpHud_TextScale", 0.035]) * _playerScale;
    private _distanceFade = missionNamespace getVariable ["Waldo_WmpHud_DistanceFade", true];
    private _groupOnly = missionNamespace getVariable ["Waldo_WmpHud_GroupOnly", false];
    private _showIncapacitated = missionNamespace getVariable ["Waldo_WmpHud_ShowIncapacitated", true];
    private _showIcons = (missionNamespace getVariable ["Waldo_WmpHud_ShowIcons", true]) && {_playerPreferences getOrDefault ["showIcons", true]};
    private _showNames = (missionNamespace getVariable ["Waldo_WmpHud_ShowNames", true]) && {_playerPreferences getOrDefault ["showNames", true]};
    private _showVehicleCrew = missionNamespace getVariable ["Waldo_WmpHud_ShowVehicleCrew", false];
    private _font = missionNamespace getVariable ["Waldo_WmpHud_Font", "PuristaBold"];
    private _textGrowth = (missionNamespace getVariable ["Waldo_WmpHud_TextDistanceGrowth", 0.00025]) * _playerScale;
    private _textMaximum = (missionNamespace getVariable ["Waldo_WmpHud_TextMaximumScale", 0.05]) * _playerScale;
    private _textHeadOffset = missionNamespace getVariable ["Waldo_WmpHud_TextHeadOffset", 0.30];
    private _iconHeadOffset = missionNamespace getVariable ["Waldo_WmpHud_IconHeadOffset", 0.75];
    private _outlineScale = missionNamespace getVariable ["Waldo_WmpHud_OutlineScale", 1.12];
    private _outlineColour = +(missionNamespace getVariable ["Waldo_WmpHud_OutlineColour", [0.03, 0.03, 0.03, 1]]);
    private _icon = missionNamespace getVariable ["Waldo_WmpHud_Icon", "\a3\ui_f\data\igui\cfg\actions\getincommander_ca.paa"];
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
            if (_requiresLOS) then {_visible = [player, "VIEW"] checkVisibility [eyePos player, eyePos _unit] > 0.25};
            if (_visible) then {
                // eyePos follows the animated centre of the face. The broad visual "head"
                // selection is not guaranteed to have its origin in the model's horizontal
                // centre and visibly pulled some nameplates to one side when units turned.
                private _headPosition = ASLToAGL eyePos _unit;
                if (_headPosition isEqualTo [0, 0, 0]) then {
                    private _fallback = getPosATLVisual _unit;
                    _fallback set [2, (_fallback select 2) + 1.7];
                    _headPosition = _fallback;
                };
                private _iconPosition = +_headPosition;
                _iconPosition set [2, (_iconPosition select 2) + _iconHeadOffset];
                private _drawColour = +_colour;
                if (_distanceFade) then {_drawColour set [3, (_drawColour select 3) * (1 - ((_distance / _iconRange) min 0.85))]};
                if (_showIcons) then {drawIcon3D [_icon, _drawColour, _iconPosition, _iconScale, _iconScale, 0, "", 1, 0, _font, "center"]};
                if (_showNames && {_distance <= _nameRange}) then {
                    private _textPosition = +_headPosition;
                    _textPosition set [2, (_textPosition select 2) + _textHeadOffset];
                    private _drawTextScale = (_textScale + (_distance * (_textGrowth max 0))) min (_textMaximum max _textScale);
                    private _drawOutline = +_outlineColour;
                    _drawOutline set [3, (_drawOutline param [3, 1]) * (_drawColour param [3, 1])];
                    drawIcon3D [_textAnchorIcon, _drawOutline, _textPosition, 0, 0, 0, name _unit, 0, _drawTextScale * (_outlineScale max 1), _font, "center"];
                    drawIcon3D [_textAnchorIcon, _drawColour, _textPosition, 0, 0, 0, name _unit, 0, _drawTextScale, _font, "center"];
                };
            };
        };
    } forEach _units;
}];
missionNamespace setVariable ["Waldo_WmpHud_EventId", _eventId];
[] call Waldo_fnc_AccessibilitySelfInteractionInit;

if !(missionNamespace getVariable ["Waldo_WmpHud_RespawnHandlerInstalled", false]) then {
    missionNamespace setVariable ["Waldo_WmpHud_RespawnHandlerInstalled", true];
    private _respawnId = addMissionEventHandler ["EntityRespawned", {
        params ["_newEntity"];
        if (local _newEntity && {_newEntity isEqualTo player}) then {
            [] call Waldo_fnc_WmpHudStop;
            if (missionNamespace getVariable ["Waldo_WmpHud_Enable", false]) then {[] call Waldo_fnc_WmpHudInit};
        };
    }];
    missionNamespace setVariable ["Waldo_WmpHud_RespawnHandlerId", _respawnId];
};
true
