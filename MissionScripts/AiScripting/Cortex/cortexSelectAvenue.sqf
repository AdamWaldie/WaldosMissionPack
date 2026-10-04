/*
 * Author: WaldoTheWarfighter
 * Selects one bounded, terrain-aware avenue from a small caller-supplied candidate set.
 *
 * Each candidate is an ordered array of ATL leg endpoints. The selector rejects water and routes
 * which enter a supporting element's 30 m live-fire corridor. A manoeuvre element which begins
 * inside its own supporting squad's corridor may depart laterally for at most 60 m of route; once
 * clear it may not re-enter. This distinguishes a necessary departure from crossing friendly fire.
 * The existing bounded safety samples also reject water and cliff-like ground and score cumulative
 * height change, steep surfaces and roads. An off-road vehicle route rejects sustained ground
 * steeper than roughly 37 degrees or an abrupt sample-to-sample grade above 70 percent. Roads keep
 * a wider allowance because their engine path surface can disagree with the underlying terrain
 * normal. Infantry retains a wider traversable envelope but still rejects cliff-like steps. This
 * closes the gaps between the three more expensive
 * ballistic/visual screening rays, so a route that looked valid on a flat range cannot jump across
 * a narrow ridge, ditch or water strip on a real terrain. Vehicle callers use a stricter slope limit
 * and receive a small road preference; the selector still chooses only endpoints and leaves actual
 * driving and local obstacle avoidance to the engine. Concealment receives a smaller benefit and is
 * never described as cover. Route length keeps the result purposeful.
 * Candidate and sample counts are capped, so this runs once when an operation starts rather than
 * per unit or scheduler tick.
 * Locality/authority: pure terrain and geometry calculation; call on the group owner planning the
 * operation. No AI command or public state is changed.
 * Repeat/JIP: deterministic for the supplied geometry and current world objects. The calling
 * operation stores and reuses the selected legs; this function has no persistent state.
 *
 * Arguments:
 * 0: start <ARRAY> - ATL route origin
 * 1: candidate routes <ARRAY> - arrays of ATL leg endpoints, maximum eight considered
 * 2: threat position <ARRAY> - ATL position used for exposure rays
 * 3: support origins <ARRAY> - origins whose live-fire corridors remain clear, default []
 * 4: threat object <OBJECT> - optional ray exclusion object, default objNull
 * 5: mobility <STRING> - "INFANTRY" or "VEHICLE", default "INFANTRY"
 *
 * Return Value:
 * Array - selected ordered leg endpoints, or [] when no candidate is safe
 *
 * Current callers: Waldo_fnc_CortexFlankStart, Waldo_fnc_CortexFlankStep,
 * Waldo_fnc_CortexAdvanceStart, Waldo_fnc_CortexRetreat, Waldo_fnc_CortexGroupTick,
 * Waldo_fnc_CortexSupportAssaultServer, Waldo_fnc_CortexSupportCoordinateStep,
 * Waldo_fnc_CortexCombinedArmsLocal, Waldo_fnc_CortexVehicles and
 * Waldo_fnc_CortexArtilleryScoot.
 *
 * Example:
 * private _legs = [_start, [[_goal],[_screen,_goal]], _enemyPos, [_baseOrigin], _target]
 *     call Waldo_fnc_CortexSelectAvenue;
 */

params [
    ["_start",[],[[]]],
    ["_candidates",[],[[]]],
    ["_threat",[],[[]]],
    ["_supportOrigins",[],[[]]],
    ["_threatObject",objNull,[objNull]],
    ["_mobility","INFANTRY",[""]]
];
if (count _start < 2 || {count _threat < 2} || {_candidates isEqualTo []}) exitWith {[]};
_mobility=toUpper _mobility;
if !(_mobility in ["INFANTRY","VEHICLE"]) then {_mobility="INFANTRY"};
private _vehicleRoute=_mobility == "VEHICLE";
private _minimumSurfaceUp=[0.55,0.8] select _vehicleRoute;
private _maximumGrade=[1.25,0.7] select _vehicleRoute;

private _limited=_candidates select [0,(count _candidates) min 8];
private _threatASL=(AGLToASL _threat) vectorAdd [0,0,1.4];
private _best=[];
private _bestScore=1e12;
{
    private _route=_x;
    private _valid=_route isNotEqualTo [] && {_route findIf {count _x < 2 || {surfaceIsWater _x}} < 0};
    private _routeLength=0;
    private _hardScreen=0;
    private _concealed=0;
    private _screenSamples=0;
    private _terrainPenalty=0;
    private _terrainSamples=0;
    private _roadSamples=0;
    private _previousTerrainASL=getTerrainHeightASL _start;
    private _previousTerrainPoint=+_start;
    private _from=_start;
    // [starts inside corridor, has cleared corridor]. State persists across every leg in this
    // candidate so a route cannot leave the lane and later cross back through it.
    private _laneStates=_supportOrigins apply {
        private _laneX=(_threat select 0)-(_x select 0);
        private _laneY=(_threat select 1)-(_x select 1);
        private _laneLength=sqrt (_laneX*_laneX+_laneY*_laneY);
        private _startLateral=if (_laneLength > 0) then {
            abs ((((_start select 0)-(_x select 0))*_laneY-((_start select 1)-(_x select 1))*_laneX)/_laneLength)
        } else {1e6};
        [_startLateral < 30,false]
    };
    if (_valid) then {
        {
            private _to=_x;
            private _legLength=_from distance2D _to;
            _routeLength=_routeLength+_legLength;
            // Safety sampling is simple arithmetic and capped independently from the three
            // geometry rays. Long flank legs therefore cannot jump across a narrow fire lane.
            private _safetySamples=((ceil (_legLength/20)) max 3) min 24;
            for "_safetyIndex" from 1 to _safetySamples do {
                private _fraction=_safetyIndex/_safetySamples;
                private _sample=[
                    (_from select 0)+((_to select 0)-(_from select 0))*_fraction,
                    (_from select 1)+((_to select 1)-(_from select 1))*_fraction,
                    0
                ];
                // Reuse the already bounded fire-lane samples for terrain passability. The former
                // three-point terrain check could miss a narrow ridge, ditch or water strip on a
                // long leg. This adds no loop and remains a once-per-operation planning cost.
                private _surfaceUp=(surfaceNormal _sample) select 2;
                private _terrainASL=getTerrainHeightASL _sample;
                private _sampleDistance=(_previousTerrainPoint distance2D _sample) max 1;
                private _sampleGrade=abs (_terrainASL-_previousTerrainASL)/_sampleDistance;
                private _onRoad=_vehicleRoute && {isOnRoad _sample};
                private _sampleMinimumUp=if (_onRoad) then {0.68} else {_minimumSurfaceUp};
                private _sampleMaximumGrade=if (_onRoad) then {0.9} else {_maximumGrade};
                _terrainSamples=_terrainSamples+1;
                if (surfaceIsWater _sample || {_surfaceUp < _sampleMinimumUp} || {_sampleGrade > _sampleMaximumGrade}) then {
                    _valid=false;
                } else {
                    _terrainPenalty=_terrainPenalty+abs (_terrainASL-_previousTerrainASL)
                        +((1-_surfaceUp)*12);
                    if (_onRoad) then {_roadSamples=_roadSamples+1};
                    _previousTerrainASL=_terrainASL;
                    _previousTerrainPoint=+_sample;
                };
                if (!_valid) exitWith {};
                if (_sample distance2D _start > 10) then {
                    {
                        private _support=_x;
                        private _laneState=_laneStates select _forEachIndex;
                        private _laneX=(_threat select 0)-(_support select 0);
                        private _laneY=(_threat select 1)-(_support select 1);
                        private _laneLength=sqrt (_laneX*_laneX+_laneY*_laneY);
                        if (_laneLength > 40) then {
                            private _startX=(_start select 0)-(_support select 0);
                            private _startY=(_start select 1)-(_support select 1);
                            private _startSide=(_laneX*_startY-_laneY*_startX)/_laneLength;
                            private _pointX=(_sample select 0)-(_support select 0);
                            private _pointY=(_sample select 1)-(_support select 1);
                            private _along=(_pointX*_laneX+_pointY*_laneY)/_laneLength;
                            private _lateral=abs (_pointX*_laneY-_pointY*_laneX)/_laneLength;
                            private _pointSide=(_laneX*_pointY-_laneY*_pointX)/_laneLength;
                            private _insideLiveLane=_along > 10 && {_along < _laneLength-10} && {_lateral < 30};
                            if (_laneState select 0) then {
                                if !(_laneState select 1) then {
                                    if (_lateral >= 30) then {
                                        _laneState set [1,true];
                                    } else {
                                        if (_sample distance2D _start > 60) then {_valid=false};
                                    };
                                } else {
                                    if (_insideLiveLane) then {_valid=false};
                                };
                            } else {
                                if (_insideLiveLane) then {_valid=false};
                                if (abs _startSide >= 30 && {abs _pointSide >= 10} && {_pointSide*_startSide < 0}) then {_valid=false};
                            };
                        };
                    } forEach _supportOrigins;
                };
                if (!_valid) exitWith {};
            };
            if (!_valid) exitWith {};
            {
                private _fraction=_x;
                private _sample=[
                    (_from select 0)+((_to select 0)-(_from select 0))*_fraction,
                    (_from select 1)+((_to select 1)-(_from select 1))*_fraction,
                    0
                ];
                _screenSamples=_screenSamples+1;
                private _sampleASL=(AGLToASL _sample) vectorAdd [0,0,1.0];
                private _rayStart=_threatASL vectorAdd ((_threatASL vectorFromTo _sampleASL) vectorMultiply 2);
                private _hard=terrainIntersectASL [_threatASL,_sampleASL]
                    || {(lineIntersectsSurfaces [_rayStart,_sampleASL,_threatObject,objNull,true,1,"FIRE","GEOM"]) isNotEqualTo []};
                if (_hard) then {
                    _hardScreen=_hardScreen+1;
                } else {
                    if ((lineIntersectsSurfaces [_rayStart,_sampleASL,_threatObject,objNull,true,1,"VIEW","GEOM"]) isNotEqualTo []) then {
                        _concealed=_concealed+1;
                    };
                };
            } forEach [0.25,0.5,0.75];
            if (!_valid) exitWith {};
            _from=_to;
        } forEach _route;
    };
    if (_valid) then {
        private _score=_routeLength
            -70*(_hardScreen/(_screenSamples max 1))
            -25*(_concealed/(_screenSamples max 1))
            -30*(_roadSamples/(_terrainSamples max 1))
            +2*(_terrainPenalty/(_terrainSamples max 1));
        if (_score < _bestScore) then {_best=+_route; _bestScore=_score};
    };
} forEach _limited;
_best
