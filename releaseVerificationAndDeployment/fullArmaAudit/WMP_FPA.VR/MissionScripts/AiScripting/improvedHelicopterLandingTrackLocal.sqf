/*
 * Author: WaldoTheWarfighter
 * Tracks the active waypoint of one local AI helicopter and invokes the vector landing controller
 * for LAND, UNLOAD, TRANSPORT UNLOAD and GET OUT tasks. A scripted waypoint is accepted only when
 * its script identifies a landing task. The controller never activates at or inside the configured
 * 50 metre minimum, avoiding take-off waypoints that vanilla Arma completes immediately.
 *
 * Arguments:
 * 0: helicopter <OBJECT>
 *
 * Return Value: Nothing (scheduled tracker lifecycle).
 *
 * Example: [_helicopter] spawn Waldo_fnc_ImprovedHelicopterLandingTrackLocal;
 * Current callers: the helicopter class-init handler and each helicopter's Local ownership handler.
 */

params [["_helicopter", objNull, [objNull]]];
if (isNull _helicopter) exitWith {};
private _lastSignature = [];
while {
    alive _helicopter
    && {local _helicopter}
} do {
    if (missionNamespace getVariable ["Waldo_ImprovedHelicopterLanding_Enable", true]) then {
        private _pilot = currentPilot _helicopter;
        private _pilotAwake = if (isNull _pilot) then {false} else {
            if (!isNil "ace_common_fnc_isAwake") then {[_pilot] call ace_common_fnc_isAwake} else {lifeState _pilot != "INCAPACITATED"}
        };
        if (!isNull _pilot && {!isPlayer _pilot} && {isNull (remoteControlled _pilot)} && {alive _pilot} && {_pilotAwake}) then {
            private _group = group _pilot;
            private _index = currentWaypoint _group;
            private _waypoints = waypoints _group;
            if (_index >= 0 && {_index < count _waypoints}) then {
                private _waypoint = [_group, _index];
                private _position = waypointPosition _waypoint;
                private _type = toUpperANSI (waypointType _waypoint);
                private _script = toLowerANSI (waypointScript _waypoint);
                private _landingType = _type in ["LAND", "UNLOAD", "TR UNLOAD", "GETOUT"];
                if (_type == "SCRIPTED" && {_script find "land" >= 0}) then {_landingType = true;};
                private _signature = [_index, _position, _type, _script];
                if !(_signature isEqualTo _lastSignature) then {
                    _lastSignature = _signature;
                    _helicopter setVariable ["Waldo_ImprovedHelicopterLanding_TrackerState", [_index, _type, _position, _script], true];
                    diag_log format ["[WMP AI LANDING] Tracker owner=%1 helicopter=%2 waypoint=%3 type=%4 position=%5", clientOwner, netId _helicopter, _index, _type, _position];
                };
                private _minimumDistance = ([_helicopter, "MinimumActivationDistance", 50] call Waldo_fnc_ImprovedHelicopterLandingSetting) max 50;
                private _distance = _helicopter distance2D _position;
                private _triggerDistance = ((abs speed _helicopter) * ([_helicopter, "TriggerSpeedFactor", 4.2] call Waldo_fnc_ImprovedHelicopterLandingSetting))
                    max ([_helicopter, "TriggerDistance", 500] call Waldo_fnc_ImprovedHelicopterLandingSetting);
                if (
                    _landingType
                    && {_distance > _minimumDistance}
                    && {_distance <= _triggerDistance}
                    && {isEngineOn _helicopter}
                    && {isNull (getSlingLoad _helicopter)}
                ) then {
                    diag_log format ["[WMP AI LANDING] Controller acquiring helicopter=%1 waypoint=%2 type=%3 distance=%4", netId _helicopter, _index, _type, round _distance];
                    [_helicopter, _position, _type, _index, _script] call Waldo_fnc_ImprovedHelicopterLandingExecuteLocal;
                    _lastSignature = [];
                };
            } else {
                _lastSignature = [];
            };
        };
    };
    uiSleep 0.5;
};
if (!isNull _helicopter) then {
    _helicopter setVariable ["Waldo_ImprovedHelicopterLanding_TrackedLocal", false];
    _helicopter setVariable ["Waldo_ImprovedHelicopterLanding_GearLocal", false];
    if (local _helicopter) then {[_helicopter, false] call Waldo_fnc_ImprovedHelicopterLandingRestoreLocal;};
};
