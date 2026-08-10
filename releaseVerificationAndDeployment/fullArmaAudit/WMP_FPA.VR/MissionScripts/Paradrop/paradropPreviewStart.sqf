/*
 * Author: WaldoTheWarfighter
 * Starts a live, curator-local preview of a paradrop deployment direction: a Draw3D overlay of the
 * standby/green/red/exit line around a chosen centre, rotated in real time with Q/E while the
 * curator watches it, then handed straight into the existing "Create Dynamic Paradrop" dialog
 * (Waldo_fnc_ParadropDropZoneZen) with that heading pre-seeded once confirmed with Enter.
 *
 * This exists because the "Run direction" slider in the create dialog is otherwise a blind 0-359
 * number with no feedback about which way the aircraft will actually fly relative to the terrain -
 * the ZEN dialog framework (zen_dialog_fnc_create) has no live per-drag callback and no documented
 * way to reach a specific dialog's control from outside its own confirm callback, so this preview
 * step deliberately does not depend on ZEN dialog internals. It reuses the same Draw3D-overlay
 * pattern already proven by Waldo_fnc_JammerMapDraw (curator-only, addMissionEventHandler so it
 * keeps rendering while Zeus owns the screen) and the same Q/E rotate + Escape cancel input pattern
 * already proven by Waldo_fnc_EcoBuild_beginPlayerConstructionPlacement.
 *
 * The Draw3D and KeyDown handlers are installed once per client and left in place afterward, gated
 * on Waldo_Paradrop_PreviewActive - exactly like Waldo_fnc_JammerMapDraw's single always-installed
 * handler - rather than added and removed on every preview session.
 *
 * Locality and authority: curator-client-local only. Nothing here touches server state; the eventual
 * Waldo_fnc_ParadropCreateDropZone call it leads to keeps its own existing curator authentication
 * and server-side clamping untouched.
 *
 * Arguments:
 * 0: centre <ARRAY> - drop point position (2 or 3 element).
 * 1: initial direction <NUMBER> - degrees, -1 (default) keeps whatever heading the previous preview
 *    session on this client last used (0 the first time).
 *
 * Return Value:
 * Boolean - true when the preview was started.
 *
 * Example:
 * [_modulePos] call Waldo_fnc_ParadropPreviewStart;
 *
 * Current callers: the "Paradrop - Preview Deployment Direction" ZEN module.
 */

params [["_centre", [], [[]]], ["_direction", -1, [0]]];
if (!hasInterface) exitWith {false};
if (isNull (getAssignedCuratorLogic player)) exitWith {false};
if (count _centre < 2) exitWith {false};

if (_direction < 0) then {_direction = missionNamespace getVariable ["Waldo_Paradrop_PreviewDirection", 0]};
missionNamespace setVariable ["Waldo_Paradrop_PreviewActive", true];
missionNamespace setVariable ["Waldo_Paradrop_PreviewCentre", +_centre];
missionNamespace setVariable ["Waldo_Paradrop_PreviewDirection", _direction mod 360];

if !(missionNamespace getVariable ["Waldo_Paradrop_PreviewHandlersInstalled", false]) then {
    missionNamespace setVariable ["Waldo_Paradrop_PreviewHandlersInstalled", true];

    addMissionEventHandler ["Draw3D", {
        if !(missionNamespace getVariable ["Waldo_Paradrop_PreviewActive", false]) exitWith {};
        if (isNull (getAssignedCuratorLogic player)) exitWith {};
        private _centre = missionNamespace getVariable ["Waldo_Paradrop_PreviewCentre", []];
        if (count _centre < 2) exitWith {};
        private _direction = missionNamespace getVariable ["Waldo_Paradrop_PreviewDirection", 0];
        // Ground-plane preview (altitude 0): the actual flight route sits at route altitude, but a
        // curator looking at the map/terrain needs the flat shape, matching how
        // Waldo_fnc_ParadropCreateDropZone's own STANDBY/GREEN/RED markers are drawn on the ground.
        private _geometry = [_centre, _direction, 0, 2500, 2500, 2500, "LEFT"] call Waldo_fnc_ParadropRouteGeometry;
        if (_geometry isEqualTo createHashMap) exitWith {};
        private _standby = _geometry get "standby";
        private _green = _geometry get "green";
        private _point = _geometry get "centre";
        private _red = _geometry get "red";
        private _exit = _geometry get "exit";
        private _amber = [1, 0.8, 0.1, 1];
        private _colGreen = [0.15, 0.9, 0.2, 1];
        private _colRed = [0.9, 0.15, 0.15, 1];
        private _grey = [0.7, 0.7, 0.7, 0.9];
        drawLine3D [_standby, _green, _amber];
        drawLine3D [_green, _point, _colGreen];
        drawLine3D [_point, _red, _colRed];
        drawLine3D [_red, _exit, _grey];
        {
            _x params ["_pos", "_col", "_label"];
            drawIcon3D ["\a3\ui_f\data\map\markers\military\dot_ca.paa", _col, _pos, 0.7, 0.7, 0, _label, 1, 0.03, "PuristaMedium"];
        } forEach [
            [_standby, _amber, "STANDBY"],
            [_green, _colGreen, "GREEN"],
            [_point, [1, 1, 1, 1], format ["DROP POINT  HDG %1", round _direction]],
            [_red, _colRed, "RED"]
        ];
    }];

    private _display = findDisplay 46;
    if !(isNull _display) then {
        _display displayAddEventHandler ["KeyDown", {
            params ["_display", "_key"];
            if !(missionNamespace getVariable ["Waldo_Paradrop_PreviewActive", false]) exitWith {false};
            if (isNull (getAssignedCuratorLogic player)) exitWith {false};
            // Q/E: same rotate keys as Waldo_fnc_EcoBuild_beginPlayerConstructionPlacement.
            if (_key in [16, 18]) exitWith {
                private _step = 5;
                private _newDirection = (missionNamespace getVariable ["Waldo_Paradrop_PreviewDirection", 0]) + (if (_key == 18) then {_step} else {-_step});
                _newDirection = _newDirection % 360;
                if (_newDirection < 0) then {_newDirection = _newDirection + 360};
                missionNamespace setVariable ["Waldo_Paradrop_PreviewDirection", _newDirection];
                true
            };
            // Enter: confirm and hand off to the existing create dialog with this heading pre-seeded.
            if (_key == 28) exitWith {
                private _confirmedCentre = missionNamespace getVariable ["Waldo_Paradrop_PreviewCentre", []];
                private _confirmedDirection = missionNamespace getVariable ["Waldo_Paradrop_PreviewDirection", 0];
                [] call Waldo_fnc_ParadropPreviewStop;
                ["CREATE", _confirmedCentre, objNull, _confirmedDirection] call Waldo_fnc_ParadropDropZoneZen;
                true
            };
            // Escape: cancel without opening anything.
            if (_key == 1) exitWith {
                [] call Waldo_fnc_ParadropPreviewStop;
                true
            };
            false
        }];
    };
};

[
    "PARADROP DIRECTION PREVIEW",
    "Q/E rotates the run line. Enter confirms and opens Create Dynamic Paradrop with this heading. Escape cancels.",
    "INFO", 0, "TOP", "PARADROP_PREVIEW", "PARADROP"
] call Waldo_fnc_ShowUiNotification;

true
