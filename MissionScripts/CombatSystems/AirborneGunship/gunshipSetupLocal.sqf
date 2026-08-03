/*
 * Author: WaldoTheWarfighter
 * Reconciles JIP-safe gunship markers and controller actions on one client.
 *
 * This repeat-safe client function consumes Waldo_Gunship_PublicSystems. It removes only actions
 * created by this feature, restores controller controls after respawn/JIP, and exposes status-only
 * feedback while an assigned aircraft is in transit, RTB or service. It is called by initPlayerLocal,
 * public-state publication and the audit refresh control.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Boolean - true after local reconciliation
 *
 * Example:
 * [] call Waldo_fnc_GunshipSetupLocal;
 */

if !(hasInterface) exitWith {false};
if !(missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", isServer]) exitWith {
    [] spawn {
        waitUntil {
            missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false]
            || {missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotFailed", false]}
        };
        if (missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false]) then {[] call Waldo_fnc_GunshipSetupLocal};
    };
    true
};
if (isNil {missionNamespace getVariable "Waldo_Gunship_MarkerPFH"}) then {
    private _handler = [{[] call Waldo_fnc_GunshipUpdateMarkersLocal}, 1] call CBA_fnc_addPerFrameHandler;
    missionNamespace setVariable ["Waldo_Gunship_MarkerPFH", _handler];
};
private _systems = missionNamespace getVariable ["Waldo_Gunship_PublicSystems", []];
private _systemIds = _systems apply {_x select 0};
private _knownIds = missionNamespace getVariable ["Waldo_Gunship_LocalIds", []];

{
    private _id = _x;
    if !(_id in _systemIds) then {
        deleteMarkerLocal format ["Waldo_Gunship_%1_Aircraft", _id];
        deleteMarkerLocal format ["Waldo_Gunship_%1_Orbit", _id];
    };
} forEach _knownIds;
missionNamespace setVariable ["Waldo_Gunship_LocalIds", _systemIds];

private _oldVanillaActions = player getVariable ["Waldo_Gunship_VanillaActions", []];
{player removeAction _x} forEach _oldVanillaActions;
player setVariable ["Waldo_Gunship_VanillaActions", []];
private _oldAceActions = player getVariable ["Waldo_Gunship_AceActions", []];
if !(isNil "ace_interact_menu_fnc_removeActionFromObject") then {
    {[_x select 0, _x select 1, _x select 2] call ace_interact_menu_fnc_removeActionFromObject} forEach _oldAceActions;
};
player setVariable ["Waldo_Gunship_AceActions", []];
private _newAceActions = [];
private _newVanillaActions = [];

{
    _x params ["_id", "_aircraft", "_controller", "_status", "_orbit", "_home", "_side", "_callsign", "_turretProfiles", "_showMarkers", ["_serviceCompleteAt", -1], ["_serviceDuration", 0]];
    if (_showMarkers && {!isNull _aircraft} && {(side group player) getFriend _side >= 0.6}) then {
        private _aircraftMarkerName = format ["Waldo_Gunship_%1_Aircraft", _id];
        private _orbitMarkerName = format ["Waldo_Gunship_%1_Orbit", _id];
        private _markerColour = switch (_side) do {case east: {"ColorOPFOR"}; case independent: {"ColorIndependent"}; case civilian: {"ColorCivilian"}; default {"ColorBLUFOR"}};
        if (markerShape _aircraftMarkerName == "") then {
            createMarkerLocal [_aircraftMarkerName, getPosWorld _aircraft];
            _aircraftMarkerName setMarkerTypeLocal "b_plane";
            _aircraftMarkerName setMarkerColorLocal _markerColour;
        };
        _aircraftMarkerName setMarkerPosLocal getPosWorld _aircraft;
        _aircraftMarkerName setMarkerDirLocal getDir _aircraft;
        _aircraftMarkerName setMarkerTextLocal format ["%1 - %2", _callsign, _status];
        if (count _orbit >= 2) then {
            if (markerShape _orbitMarkerName == "") then {
                createMarkerLocal [_orbitMarkerName, _orbit];
                _orbitMarkerName setMarkerTypeLocal "mil_circle";
                _orbitMarkerName setMarkerColorLocal _markerColour;
            };
            _orbitMarkerName setMarkerPosLocal _orbit;
            _orbitMarkerName setMarkerTextLocal format ["%1 Orbit", _callsign];
        };
    } else {
        deleteMarkerLocal format ["Waldo_Gunship_%1_Aircraft", _id];
        deleteMarkerLocal format ["Waldo_Gunship_%1_Orbit", _id];
    };

    if (_controller isEqualTo player) then {
        private _available = _status in ["ON_STATION", "CONTROLLED"];
        if !(isNil "ace_interact_menu_fnc_createAction") then {
            private _categoryId = format ["Waldo_Gunship_%1", _id];
            private _category = [_categoryId, format ["Gunship: %1", _callsign], "\A3\ui_f\data\map\vehicleicons\iconPlane_ca.paa", {}, {true}] call ace_interact_menu_fnc_createAction;
            [player, 1, ["ACE_SelfActions"], _category] call ace_interact_menu_fnc_addActionToObject;
            private _paths = [[player, 1, ["ACE_SelfActions", _categoryId]]];
            if (_available) then {
            private _orbitAction = [format ["%1_Orbit", _categoryId], "Designate Orbit", "\A3\ui_f\data\igui\cfg\simpletasks\types\map_ca.paa", {private _args = _this select 2; [(_args select 0)] call Waldo_fnc_GunshipSelectOrbitLocal}, {(_this select 2) select 1}, {}, [_id, _available]] call ace_interact_menu_fnc_createAction;
            [player, 1, ["ACE_SelfActions", _categoryId], _orbitAction] call ace_interact_menu_fnc_addActionToObject;
            _paths pushBack [player, 1, ["ACE_SelfActions", _categoryId, format ["%1_Orbit", _categoryId]]];
            {
                _x params ["_label", "_path"];
                private _actionId = format ["%1_Turret_%2", _categoryId, _forEachIndex];
                private _action = [_actionId, format ["Take Control: %1", _label], "\A3\ui_f\data\IGUI\Cfg\holdactions\holdAction_connect_ca.paa", {private _args = _this select 2; [(_args select 0), "TAKE_CONTROL", [_args select 1], player] remoteExecCall ["Waldo_fnc_GunshipServerHandle", 2]}, {(_this select 2) select 2}, {}, [_id, _path, _available]] call ace_interact_menu_fnc_createAction;
                [player, 1, ["ACE_SelfActions", _categoryId], _action] call ace_interact_menu_fnc_addActionToObject;
                _paths pushBack [player, 1, ["ACE_SelfActions", _categoryId, _actionId]];
            } forEach _turretProfiles;
            private _releaseAction = [format ["%1_Release", _categoryId], "Release Weapon Control", "\A3\ui_f\data\igui\cfg\actions\getout_ca.paa", {private _id = _this select 2; [_id, "RELEASE_CONTROL", [], player] remoteExecCall ["Waldo_fnc_GunshipServerHandle", 2]}, {missionNamespace getVariable ["Waldo_Gunship_ControlledId", ""] == (_this select 2)}, {}, _id] call ace_interact_menu_fnc_createAction;
            [player, 1, ["ACE_SelfActions", _categoryId], _releaseAction] call ace_interact_menu_fnc_addActionToObject;
            _paths pushBack [player, 1, ["ACE_SelfActions", _categoryId, format ["%1_Release", _categoryId]]];
            private _serviceAction = [format ["%1_Service", _categoryId], "Return for Service", "\A3\ui_f\data\igui\cfg\simpletasks\types\repair_ca.paa", {private _args = _this select 2; [(_args select 0), "SERVICE", [], player] remoteExecCall ["Waldo_fnc_GunshipServerHandle", 2]}, {(_this select 2) select 1}, {}, [_id, _available]] call ace_interact_menu_fnc_createAction;
            [player, 1, ["ACE_SelfActions", _categoryId], _serviceAction] call ace_interact_menu_fnc_addActionToObject;
            _paths pushBack [player, 1, ["ACE_SelfActions", _categoryId, format ["%1_Service", _categoryId]]];
            } else {
                private _statusAction = [format ["%1_Status", _categoryId], format ["Status: %1", _status], "\A3\ui_f\data\igui\cfg\simpletasks\types\repair_ca.paa", {
                    private _args = _this select 2;
                    _args params ["_callsign", "_status", "_completeAt"];
                    private _detail = if (_status == "SERVICING" && {_completeAt >= 0}) then {
                        format ["Service underway. Approximately %1 seconds remaining. Tasking and weapon control are locked.", ceil ((_completeAt - serverTime) max 0)]
                    } else {
                        if (_status == "RTB") then {"Returning to the service orbit. Tasking and weapon control are locked."} else {"The aircraft is currently unavailable for tasking."}
                    };
                    [format ["%1: %2", _callsign, _detail]] call Waldo_fnc_GunshipNotifyLocal;
                }, {true}, {}, [_callsign, _status, _serviceCompleteAt]] call ace_interact_menu_fnc_createAction;
                [player, 1, ["ACE_SelfActions", _categoryId], _statusAction] call ace_interact_menu_fnc_addActionToObject;
                _paths pushBack [player, 1, ["ACE_SelfActions", _categoryId, format ["%1_Status", _categoryId]]];
            };
            _newAceActions append _paths;
        } else {
            private _actions = [];
            if (_available) then {
            _actions pushBack (player addAction [format ["%1: Designate Orbit", _callsign], {[(_this select 3)] call Waldo_fnc_GunshipSelectOrbitLocal}, _id, 1.5, false, true, "", str _available]);
            {
                _x params ["_label", "_path"];
                _actions pushBack (player addAction [format ["%1: Control %2", _callsign, _label], {private _args = _this select 3; [_args select 0, "TAKE_CONTROL", [_args select 1], player] remoteExecCall ["Waldo_fnc_GunshipServerHandle", 2]}, [_id, _path], 1.5, false, true, "", str _available]);
            } forEach _turretProfiles;
            _actions pushBack (player addAction [format ["%1: Return for Service", _callsign], {[_this select 3, "SERVICE", [], player] remoteExecCall ["Waldo_fnc_GunshipServerHandle", 2]}, _id, 1.5, false, true, "", str _available]);
            _actions pushBack (player addAction [format ["%1: Release Weapon Control", _callsign], {[_this select 3, "RELEASE_CONTROL", [], player] remoteExecCall ["Waldo_fnc_GunshipServerHandle", 2]}, _id, 1.5, false, true, "", "missionNamespace getVariable ['Waldo_Gunship_ControlledId', ''] != ''"]);
            } else {
                _actions pushBack (player addAction [format ["<t color='#79C7FF'>%1: Status (%2)</t>", _callsign, _status], {
                    private _args = _this select 3;
                    _args params ["_callsign", "_status", "_completeAt"];
                    private _remaining = if (_status == "SERVICING") then {format ["; %1 seconds remaining", ceil ((_completeAt - serverTime) max 0)]} else {""};
                    [format ["%1 is %2%3. Tasking and weapon control are locked.", _callsign, toLowerANSI _status, _remaining]] call Waldo_fnc_GunshipNotifyLocal;
                }, [_callsign, _status, _serviceCompleteAt], 1.5, false, true]);
            };
            _newVanillaActions append _actions;
        };
    };
} forEach _systems;
player setVariable ["Waldo_Gunship_AceActions", _newAceActions];
player setVariable ["Waldo_Gunship_VanillaActions", _newVanillaActions];
diag_log format ["[WMP GUNSHIP] Local controls reconciled systems=%1 aceActions=%2 vanillaActions=%3 controller=%4", count _systems, count (player getVariable ["Waldo_Gunship_AceActions", []]), count (player getVariable ["Waldo_Gunship_VanillaActions", []]), name player];
true
