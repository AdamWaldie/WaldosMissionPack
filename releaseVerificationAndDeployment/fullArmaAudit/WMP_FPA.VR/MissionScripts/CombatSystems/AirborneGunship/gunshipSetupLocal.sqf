/*
 * Author: WaldoTheWarfighter
 * Reconciles JIP-safe gunship markers and controller actions on one client.
 *
 * This repeat-safe client function consumes Waldo_Gunship_PublicSystems. It removes only actions
 * created by this feature and restores FAC/JTAC controller controls after respawn/JIP. No gunship
 * ACE or vanilla interaction is exposed to an unassigned player. A status readout is available to
 * the assigned controller; Designate Orbit, Return for Service and Configure Orbit also stay
 * available while the aircraft is still in transit to its orbit (matching what the server actually
 * permits), while per-turret weapon control only appears once the aircraft is on station or already
 * controlled. It also (re)creates each gunship's aircraft marker (a "mil_warning" exclamation icon)
 * and a companion border-only ellipse sized to the aircraft's current loiter radius at its orbit
 * centre. It is called by initPlayerLocal, public-state publication and the audit refresh control.
 *
 * Locality and authority:
 * Runs only on an interface client and mutates local markers/actions. It consumes the server's
 * published registry and sends all requested state changes back to server authority.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Boolean - true after local reconciliation
 *
 * Example:
 * [] call Waldo_fnc_GunshipSetupLocal;
 * Result: this client has exactly the current markers and permitted controller actions.
 * Current callers: initPlayerLocal, gunship public-state replay and audit refresh controls.
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
// Publication can legitimately arrive through the public variable, ordered runtime snapshot and
// explicit reconcile call in the same frame. Do not tear down and recreate the same ACE tree three
// times; that action churn was visible in RPTs and needlessly stressed the ACE interaction menu.
private _lastSystems = missionNamespace getVariable ["Waldo_Gunship_LastActionSnapshot", []];
private _lastPlayer = missionNamespace getVariable ["Waldo_Gunship_LastActionPlayer", objNull];
if (_lastPlayer isEqualTo player && {_lastSystems isEqualTo _systems}) exitWith {true};
missionNamespace setVariable ["Waldo_Gunship_LastActionSnapshot", +_systems];
missionNamespace setVariable ["Waldo_Gunship_LastActionPlayer", player];
private _systemIds = _systems apply {_x select 0};
private _knownIds = missionNamespace getVariable ["Waldo_Gunship_LocalIds", []];

{
    private _id = _x;
    if !(_id in _systemIds) then {
        deleteMarkerLocal format ["Waldo_Gunship_%1_Aircraft", _id];
        deleteMarkerLocal format ["Waldo_Gunship_%1_Orbit", _id];
        deleteMarkerLocal format ["Waldo_Gunship_%1_OrbitRadius", _id];
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
    _x params ["_id", "_aircraft", "_controller", "_status", "_orbit", "_home", "_side", "_callsign", "_turretProfiles", "_showMarkers", ["_serviceCompleteAt", -1], ["_serviceDuration", 0], ["_radius", 1500], ["_altitude", 700], ["_offStationReason", ""]];
    if (_showMarkers && {!isNull _aircraft} && {(side group player) getFriend _side >= 0.6}) then {
        private _aircraftMarkerName = format ["Waldo_Gunship_%1_Aircraft", _id];
        private _orbitMarkerName = format ["Waldo_Gunship_%1_Orbit", _id];
        private _radiusMarkerName = format ["Waldo_Gunship_%1_OrbitRadius", _id];
        private _markerColour = switch (_side) do {case east: {"ColorOPFOR"}; case independent: {"ColorIndependent"}; case civilian: {"ColorCivilian"}; default {"ColorBLUFOR"}};
        if (markerShape _aircraftMarkerName == "") then {
            createMarkerLocal [_aircraftMarkerName, getPosWorld _aircraft];
            // "mil_warning" is the same vanilla exclamation-in-a-triangle marker type already used
            // by MissionScripts\MissionInit\Jamming\jammerCreate.sqf, confirming it is a real,
            // loaded CfgMarkers class rather than a guess.
            _aircraftMarkerName setMarkerTypeLocal "mil_warning";
            _aircraftMarkerName setMarkerColorLocal _markerColour;
        };
        _aircraftMarkerName setMarkerPosLocal getPosWorld _aircraft;
        _aircraftMarkerName setMarkerDirLocal getDir _aircraft;
        _aircraftMarkerName setMarkerTextLocal format ["%1 - %2", _callsign, _status];
        if (count _orbit >= 2) then {
            if (markerShape _orbitMarkerName == "") then {
                createMarkerLocal [_orbitMarkerName, _orbit];
            };
            // Orbit is operational information, not an invisible implementation marker. Apply
            // every presentation field during reconciliation so clients upgrading from the former
            // Empty/alpha-zero version are repaired without requiring a fresh mission.
            _orbitMarkerName setMarkerTypeLocal "mil_circle";
            _orbitMarkerName setMarkerColorLocal _markerColour;
            _orbitMarkerName setMarkerTextLocal format ["%1 Orbit", _callsign];
            _orbitMarkerName setMarkerAlphaLocal 1;
            _orbitMarkerName setMarkerPosLocal _orbit;
            // Companion border-only ellipse sized to the actual configured loiter radius so the
            // orbit's real footprint is visible, not just its centre point. Radius/altitude can now
            // change live via Waldo_fnc_GunshipPromptOrbitConfig's SET_ORBIT_PARAMS operation, so
            // size/position are reapplied unconditionally on every reconciliation, not only at
            // creation.
            if (markerShape _radiusMarkerName == "") then {
                createMarkerLocal [_radiusMarkerName, _orbit];
                _radiusMarkerName setMarkerShapeLocal "ELLIPSE";
                _radiusMarkerName setMarkerBrushLocal "Border";
            };
            _radiusMarkerName setMarkerColorLocal _markerColour;
            _radiusMarkerName setMarkerSizeLocal [_radius, _radius];
            _radiusMarkerName setMarkerPosLocal _orbit;
            _radiusMarkerName setMarkerAlphaLocal 1;
        } else {
            deleteMarkerLocal _radiusMarkerName;
        };
    } else {
        deleteMarkerLocal format ["Waldo_Gunship_%1_Aircraft", _id];
        deleteMarkerLocal format ["Waldo_Gunship_%1_Orbit", _id];
        deleteMarkerLocal format ["Waldo_Gunship_%1_OrbitRadius", _id];
    };

    // The gunship interaction surface is FAC/JTAC equipment. Assignment is explicit server state;
    // being on a friendly side is not sufficient authority to see even the status category.
    private _isControllerSelf = _controller isEqualTo player;
    if (_isControllerSelf) then {
        // Designate Orbit and Return for Service are legitimately available while the aircraft is
        // still TRANSIT-ing to its orbit (the server's SET_ORBIT/SERVICE operations already allow
        // this), so gating the whole menu behind a single ON_STATION/CONTROLLED "_available" boolean
        // hid both of those actions - and the entire operational menu - during that window, most
        // visibly right after initial registration/controller assignment. Only weapon control
        // genuinely requires the aircraft to be physically on station.
        private _canOrbitOrService = _isControllerSelf && {_status in ["TRANSIT", "ON_STATION", "CONTROLLED"]};
        private _canTakeControl = _isControllerSelf && {_status in ["ON_STATION", "CONTROLLED"]};
        private _controllerLabel = if (isNull _controller) then {"no controller assigned - ask your curator to run Gunship: Assign Controller"} else {if (_isControllerSelf) then {"you"} else {name _controller}};
        if !(isNil "ace_interact_menu_fnc_createAction") then {
            private _categoryId = format ["Waldo_Gunship_%1", _id];
            private _category = [_categoryId, format ["Gunship: %1", _callsign], "\A3\ui_f\data\map\vehicleicons\iconPlane_ca.paa", {}, {true}] call ace_interact_menu_fnc_createAction;
            [player, 1, ["ACE_SelfActions"], _category] call ace_interact_menu_fnc_addActionToObject;
            private _paths = [[player, 1, ["ACE_SelfActions", _categoryId]]];
            private _statusAction = [format ["%1_Status", _categoryId], format ["Status: %1", _status], "\A3\ui_f\data\igui\cfg\simpletasks\types\repair_ca.paa", {
                private _args = _this select 2;
                _args params ["_callsign", "_status", "_completeAt", "_controllerLabel"];
                private _detail = switch (_status) do {
                    case "SERVICING": {format ["Service underway. Approximately %1 seconds remaining. Tasking and weapon control are locked.", ceil ((_completeAt - serverTime) max 0)]};
                    case "RTB": {"Returning to the service orbit. Tasking and weapon control are locked."};
                    case "TRANSIT": {"En route to its orbit. Orbit and service can be redirected now; weapon control unlocks once on station."};
                    default {"The aircraft is currently unavailable for tasking."};
                };
                [format ["%1: %2 Controller: %3.", _callsign, _detail, _controllerLabel]] call Waldo_fnc_GunshipNotifyLocal;
            }, {true}, {}, [_callsign, _status, _serviceCompleteAt, _controllerLabel]] call ace_interact_menu_fnc_createAction;
            [player, 1, ["ACE_SelfActions", _categoryId], _statusAction] call ace_interact_menu_fnc_addActionToObject;
            _paths pushBack [player, 1, ["ACE_SelfActions", _categoryId, format ["%1_Status", _categoryId]]];
            if (_isControllerSelf) then {
                private _orbitAction = [format ["%1_Orbit", _categoryId], "Designate Orbit", "\A3\ui_f\data\igui\cfg\simpletasks\types\map_ca.paa", {private _args = _this select 2; [(_args select 0)] call Waldo_fnc_GunshipSelectOrbitLocal}, {(_this select 2) select 1}, {}, [_id, _canOrbitOrService]] call ace_interact_menu_fnc_createAction;
                [player, 1, ["ACE_SelfActions", _categoryId], _orbitAction] call ace_interact_menu_fnc_addActionToObject;
                _paths pushBack [player, 1, ["ACE_SelfActions", _categoryId, format ["%1_Orbit", _categoryId]]];
                private _serviceAction = [format ["%1_Service", _categoryId], "Return for Service", "\A3\ui_f\data\igui\cfg\simpletasks\types\repair_ca.paa", {private _args = _this select 2; [(_args select 0), "SERVICE", [], player] remoteExecCall ["Waldo_fnc_GunshipServerHandle", 2]}, {(_this select 2) select 1}, {}, [_id, _canOrbitOrService]] call ace_interact_menu_fnc_createAction;
                [player, 1, ["ACE_SelfActions", _categoryId], _serviceAction] call ace_interact_menu_fnc_addActionToObject;
                _paths pushBack [player, 1, ["ACE_SelfActions", _categoryId, format ["%1_Service", _categoryId]]];
                private _orbitConfigAction = [format ["%1_OrbitConfig", _categoryId], "Configure Orbit", "\A3\ui_f\data\igui\cfg\simpletasks\types\move_ca.paa", {private _args = _this select 2; [(_args select 0)] call Waldo_fnc_GunshipPromptOrbitConfig}, {(_this select 2) select 1}, {}, [_id, _canOrbitOrService]] call ace_interact_menu_fnc_createAction;
                [player, 1, ["ACE_SelfActions", _categoryId], _orbitConfigAction] call ace_interact_menu_fnc_addActionToObject;
                _paths pushBack [player, 1, ["ACE_SelfActions", _categoryId, format ["%1_OrbitConfig", _categoryId]]];
                {
                    _x params ["_label", "_path"];
                    private _actionId = format ["%1_Turret_%2", _categoryId, _forEachIndex];
                    private _action = [_actionId, format ["Take Control: %1", _label], "\A3\ui_f\data\IGUI\Cfg\holdactions\holdAction_connect_ca.paa", {private _args = _this select 2; [(_args select 0), "TAKE_CONTROL", [_args select 1], player] remoteExecCall ["Waldo_fnc_GunshipServerHandle", 2]}, {(_this select 2) select 2}, {}, [_id, _path, _canTakeControl]] call ace_interact_menu_fnc_createAction;
                    [player, 1, ["ACE_SelfActions", _categoryId], _action] call ace_interact_menu_fnc_addActionToObject;
                    _paths pushBack [player, 1, ["ACE_SelfActions", _categoryId, _actionId]];
                } forEach _turretProfiles;
                private _releaseAction = [format ["%1_Release", _categoryId], "Release Weapon Control", "\A3\ui_f\data\igui\cfg\actions\getout_ca.paa", {private _id = _this select 2; [_id, "RELEASE_CONTROL", [], player] remoteExecCall ["Waldo_fnc_GunshipServerHandle", 2]}, {missionNamespace getVariable ["Waldo_Gunship_ControlledId", ""] == (_this select 2)}, {}, _id] call ace_interact_menu_fnc_createAction;
                [player, 1, ["ACE_SelfActions", _categoryId], _releaseAction] call ace_interact_menu_fnc_addActionToObject;
                _paths pushBack [player, 1, ["ACE_SelfActions", _categoryId, format ["%1_Release", _categoryId]]];
            };
            _newAceActions append _paths;
        } else {
            private _actions = [];
            _actions pushBack (player addAction [format ["<t color='#79C7FF'>%1: Status (%2)</t>", _callsign, _status], {
                private _args = _this select 3;
                _args params ["_callsign", "_status", "_completeAt", "_controllerLabel"];
                private _remaining = if (_status == "SERVICING") then {format ["; %1 seconds remaining", ceil ((_completeAt - serverTime) max 0)]} else {""};
                [format ["%1 is %2%3. Controller: %4.", _callsign, toLowerANSI _status, _remaining, _controllerLabel]] call Waldo_fnc_GunshipNotifyLocal;
            }, [_callsign, _status, _serviceCompleteAt, _controllerLabel], 1.5, false, true]);
            if (_isControllerSelf) then {
                _actions pushBack (player addAction [format ["%1: Designate Orbit", _callsign], {[(_this select 3)] call Waldo_fnc_GunshipSelectOrbitLocal}, _id, 1.5, false, true, "", str _canOrbitOrService]);
                _actions pushBack (player addAction [format ["%1: Return for Service", _callsign], {[_this select 3, "SERVICE", [], player] remoteExecCall ["Waldo_fnc_GunshipServerHandle", 2]}, _id, 1.5, false, true, "", str _canOrbitOrService]);
                _actions pushBack (player addAction [format ["%1: Configure Orbit", _callsign], {[(_this select 3)] call Waldo_fnc_GunshipPromptOrbitConfig}, _id, 1.5, false, true, "", str _canOrbitOrService]);
                {
                    _x params ["_label", "_path"];
                    _actions pushBack (player addAction [format ["%1: Control %2", _callsign, _label], {private _args = _this select 3; [_args select 0, "TAKE_CONTROL", [_args select 1], player] remoteExecCall ["Waldo_fnc_GunshipServerHandle", 2]}, [_id, _path], 1.5, false, true, "", str _canTakeControl]);
                } forEach _turretProfiles;
                _actions pushBack (player addAction [format ["%1: Release Weapon Control", _callsign], {[_this select 3, "RELEASE_CONTROL", [], player] remoteExecCall ["Waldo_fnc_GunshipServerHandle", 2]}, _id, 1.5, false, true, "", "missionNamespace getVariable ['Waldo_Gunship_ControlledId', ''] != ''"]);
            };
            _newVanillaActions append _actions;
        };
    };
} forEach _systems;
player setVariable ["Waldo_Gunship_AceActions", _newAceActions];
player setVariable ["Waldo_Gunship_VanillaActions", _newVanillaActions];
diag_log format ["[WMP GUNSHIP] Local controls reconciled systems=%1 aceActions=%2 vanillaActions=%3 controller=%4", count _systems, count (player getVariable ["Waldo_Gunship_AceActions", []]), count (player getVariable ["Waldo_Gunship_VanillaActions", []]), name player];
true
