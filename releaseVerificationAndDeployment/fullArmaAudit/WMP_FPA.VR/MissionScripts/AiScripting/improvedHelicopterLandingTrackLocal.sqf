/*
 * Author: WaldoTheWarfighter
 * Tracks the active waypoint of one local AI helicopter and invokes the vector landing controller
 * for LAND, UNLOAD, TRANSPORT UNLOAD and GET OUT tasks. A scripted waypoint is accepted only when
 * its script identifies a landing task. A MOVE waypoint is accepted only for a registered WMP
 * transport whose explicit WMP destination-order token matches the current request, waypoint and
 * position; this lets passenger services land without treating an ordinary Zeus MOVE as a landing.
 * The controller never activates at or inside the configured 50 metre minimum, avoiding take-off
 * waypoints that vanilla Arma completes immediately. A group containing more than one helicopter
 * keeps vanilla formation/waypoint flight: one group waypoint cannot safely provide a separate
 * exact touchdown point for every aircraft, and driving all of them at one point causes collisions.
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
            private _groupHelicopters = [];
            {
                private _groupVehicle = vehicle _x;
                if (_groupVehicle isKindOf "Helicopter") then {
                    _groupHelicopters pushBackUnique _groupVehicle;
                };
            } forEach units _group;
            // If Zeus groups an aircraft while WMP still owns a previous landing controller, release
            // that controller immediately. Otherwise its zero-height/anchor state can survive into
            // the new formation route and pull the newly grouped aircraft towards the terrain.
            if (
                count _groupHelicopters != 1
                && {
                    _helicopter getVariable ["Waldo_ImprovedHelicopterLanding_Active", false]
                    || {_helicopter getVariable ["Waldo_ImprovedHelicopterLanding_GroundAnchored", false]}
                }
            ) then {
                [_helicopter, false, "", true] call Waldo_fnc_ImprovedHelicopterLandingRestoreLocal;
                diag_log format ["[WMP AI LANDING] Released controller because helicopter joined a %1-aircraft group helicopter=%2.", count _groupHelicopters, netId _helicopter];
            };
            private _index = currentWaypoint _group;
            private _waypoints = waypoints _group;
            if (_index >= 0 && {_index < count _waypoints}) then {
                private _waypoint = [_group, _index];
                private _position = waypointPosition _waypoint;
                private _type = toUpperANSI (waypointType _waypoint);
                private _script = toLowerANSI (waypointScript _waypoint);
                private _landingType = _type in ["LAND", "UNLOAD", "TR UNLOAD", "GETOUT"];
                if (_type == "SCRIPTED" && {_script find "land" >= 0}) then {_landingType = true;};
                if (_type == "MOVE" && {_helicopter getVariable ["Waldo_TransportService_Registered", false]}) then {
                    private _landingOrder = _helicopter getVariable ["Waldo_TransportService_LandingOrder", []];
                    private _requestId = _helicopter getVariable ["Waldo_TransportService_RequestId", -1];
                    _landingType = count _landingOrder >= 3
                        && {_helicopter getVariable ["Waldo_TransportService_State", ""] == "TO_DESTINATION"}
                        && {(_landingOrder select 0) == _requestId}
                        && {(_landingOrder select 1) == _index}
                        && {(_landingOrder select 2) distance2D _position < 2};
                };
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
                private _velocity = velocity _helicopter;
                private _horizontalSpeed = sqrt (((_velocity select 0) ^ 2) + ((_velocity select 1) ^ 2));
                private _minimumApproachSpeed = (([_helicopter, "MinimumApproachSpeed", 55] call Waldo_fnc_ImprovedHelicopterLandingSetting) max 0) / 3.6;
                private _transitAltitude = ([_helicopter, "TransitAltitude", 30] call Waldo_fnc_ImprovedHelicopterLandingSetting) max 15;
                private _glideRatio = ([_helicopter, "GlideSlopeRatio", 4] call Waldo_fnc_ImprovedHelicopterLandingSetting) max 2;
                private _finalCommitDistance = ([_helicopter, "FinalCommitDistance", 75] call Waldo_fnc_ImprovedHelicopterLandingSetting) max 10;
                // On a short leg the helicopter can enter TriggerDistance before it has even accelerated away
                // from the pad. Preserve vanilla departure control until it has useful forward speed, unless it
                // has already reached the distance genuinely needed for the descent and final flare.
                private _closeApproachDistance = ((_transitAltitude * _glideRatio) max (_finalCommitDistance * 2)) min _triggerDistance;
                // Registered air transports retain immediate post-takeoff acquisition. Their dispatch has an
                // original LAND fallback inside 300 m, so delaying takeover creates a race with that fallback.
                private _approachReady = _helicopter getVariable ["Waldo_ImprovedHelicopterLanding_ImmediateAcquisition", false]
                    || {_horizontalSpeed >= _minimumApproachSpeed}
                    || {_distance <= _closeApproachDistance};
                if (
                    _landingType
                    && {count _groupHelicopters == 1}
                    && {_distance > _minimumDistance}
                    && {_distance <= _triggerDistance}
                    && {_approachReady}
                    && {isEngineOn _helicopter}
                    && {!isTouchingGround _helicopter}
                    && {isNull (getSlingLoad _helicopter)}
                    // Guard against re-attempting acquisition on every 0.5s tick while a controller is
                    // already active for this helicopter. Waldo_fnc_ImprovedHelicopterLandingExecuteLocal
                    // already no-ops in that case, but reaching this branch at all still reset
                    // _lastSignature below, which forced the unchanged waypoint signature to read as
                    // "changed" on the very next tick - re-broadcasting Waldo_ImprovedHelicopterLanding_
                    // TrackerState (setVariable ..., true) and re-logging "Controller acquiring" every
                    // tick for the whole multi-second descent instead of once per approach. With several
                    // helicopters landing concurrently this produced continuous, redundant global
                    // broadcast traffic for no behavioural benefit.
                    && {!(_helicopter getVariable ["Waldo_ImprovedHelicopterLanding_Active", false])}
                ) then {
                    diag_log format ["[WMP AI LANDING] Controller acquiring helicopter=%1 waypoint=%2 type=%3 distance=%4 horizontalSpeed=%5 closeEnvelope=%6", netId _helicopter, _index, _type, round _distance, round (_horizontalSpeed * 3.6), round _closeApproachDistance];
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
