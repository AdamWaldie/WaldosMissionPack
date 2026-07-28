/*
 * Author: Waldo
 * Reconciles JIP-safe gunship markers and controller actions on one client.
 * Arguments: None
 * Return Value: Boolean
 */

if !(hasInterface) exitWith {false};
if !(missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", isServer]) exitWith {
    [] spawn {waitUntil {missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false]}; [] call Waldo_fnc_GunshipSetupLocal};
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
    {[_x select 0, 1, _x select 1] call ace_interact_menu_fnc_removeActionFromObject} forEach _oldAceActions;
};
player setVariable ["Waldo_Gunship_AceActions", []];

{
    _x params ["_id", "_aircraft", "_controller", "_status", "_orbit", "_home", "_side", "_callsign", "_turretProfiles", "_showMarkers"];
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
            private _orbitAction = [format ["%1_Orbit", _categoryId], "Designate Orbit", "\A3\ui_f\data\igui\cfg\simpletasks\types\map_ca.paa", {(_this select 2) call Waldo_fnc_GunshipSelectOrbitLocal}, {(_this select 2) select 1}, {}, [_id, _available]] call ace_interact_menu_fnc_createAction;
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
            private _serviceAction = [format ["%1_Service", _categoryId], "Return for Service", "\A3\ui_f\data\igui\cfg\holdactions\refuel_ca.paa", {private _id = _this select 2; [_id, "SERVICE", [], player] remoteExecCall ["Waldo_fnc_GunshipServerHandle", 2]}, {(_this select 2) select 1}, {}, [_id, _available]] call ace_interact_menu_fnc_createAction;
            [player, 1, ["ACE_SelfActions", _categoryId], _serviceAction] call ace_interact_menu_fnc_addActionToObject;
            _paths pushBack [player, 1, ["ACE_SelfActions", _categoryId, format ["%1_Service", _categoryId]]];
            player setVariable ["Waldo_Gunship_AceActions", _paths];
        } else {
            private _actions = [];
            _actions pushBack (player addAction [format ["%1: Designate Orbit", _callsign], {[(_this select 3)] call Waldo_fnc_GunshipSelectOrbitLocal}, _id, 1.5, false, true, "", str _available]);
            {
                _x params ["_label", "_path"];
                _actions pushBack (player addAction [format ["%1: Control %2", _callsign, _label], {private _args = _this select 3; [_args select 0, "TAKE_CONTROL", [_args select 1], player] remoteExecCall ["Waldo_fnc_GunshipServerHandle", 2]}, [_id, _path], 1.5, false, true, "", str _available]);
            } forEach _turretProfiles;
            _actions pushBack (player addAction [format ["%1: Return for Service", _callsign], {[_this select 3, "SERVICE", [], player] remoteExecCall ["Waldo_fnc_GunshipServerHandle", 2]}, _id, 1.5, false, true, "", str _available]);
            _actions pushBack (player addAction [format ["%1: Release Weapon Control", _callsign], {[_this select 3, "RELEASE_CONTROL", [], player] remoteExecCall ["Waldo_fnc_GunshipServerHandle", 2]}, _id, 1.5, false, true, "", "missionNamespace getVariable ['Waldo_Gunship_ControlledId', ''] != ''"]);
            player setVariable ["Waldo_Gunship_VanillaActions", _actions];
        };
    };
} forEach _systems;
true
