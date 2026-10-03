/*
 * Author: WaldoTheWarfighter
 * Shows the disposable Cortex audit's current test, expected behaviour and recorded results.
 * Locality/authority: interface only; reads server-published audit state and protects the local
 * observer so combat cannot invalidate rendered-client measurements; never changes fixture AI.
 * Repeat/JIP: one observer per client; an obsolete respawn handler is removed before installation,
 * controls are rebuilt when the game/Zeus display changes, and audit-only tracks are capped at
 * twelve actors and forty-eight samples so the visual aid cannot dominate the measured workload.
 * Arguments: None. Return: Nothing (scheduled script).
 * Current callers: staged Cortex audit client. Example: [] execVM "cortexQAGuide.sqf";
 */
if (!hasInterface || {missionNamespace getVariable ["Waldo_CortexQA_GuideRunning",false]}) exitWith {};
missionNamespace setVariable ["Waldo_CortexQA_GuideRunning",true];
waitUntil {uiSleep 0.2; !isNull player && {!isNull findDisplay 46}};
// The observer is part of the measurement surface, not the combat fixture. Death can move the
// camera away from the workload and make the client frame-time arm appear artificially faster.
player allowDamage false;
player setCaptive true;
private _oldRespawnHandler=missionNamespace getVariable ["Waldo_CortexQA_ObserverRespawnHandler",-1];
if (_oldRespawnHandler >= 0) then {removeMissionEventHandler ["EntityRespawned",_oldRespawnHandler]};
private _respawnHandler=addMissionEventHandler ["EntityRespawned",{
    params ["_newEntity"];
    if (_newEntity isEqualTo player) then {
        player allowDamage false;
        player setCaptive true;
    };
}];
missionNamespace setVariable ["Waldo_CortexQA_ObserverRespawnHandler",_respawnHandler];
player createDiaryRecord ["Diary",["Cortex audit: what to watch","The test card names the current case and expected behaviour. Open Zeus and use Inspect test to move its camera to the fixtures. PASS covers the stated assertion only. Missing completion means incomplete. Infantry should accept/release orders; both headless clients should adopt it; all three convoy vehicles should move; cargo should unload while weapon crew remain; the mortar should fire exactly two rounds. UI checks exercise real controls, not mouse input. Assess readability separately. Results are added to this diary when each suite completes."]];
private _catalogue=missionNamespace getVariable ["Waldo_CortexQA_Catalogue",[]];
private _catalogueText="Selected run: "+(missionNamespace getVariable ["Waldo_CortexQA_Focus","all"])+"<br/>The all and features selections run every suite; individual focuses skip other suites. Listed procedures are not passes. Required ownership and interruption variants may still be incomplete.<br/><br/>";
{_catalogueText=_catalogueText+format ["%1: %2<br/>%3<br/>%4<br/><br/>",_x select 0,_x select 1,_x select 2,_x select 3]} forEach _catalogue;
player createDiaryRecord ["Diary",["Cortex: full QA inventory",_catalogueText]];
missionNamespace setVariable ["Waldo_CortexQA_GuideReady",true,true];
missionNamespace setVariable ["Waldo_CortexQA_Tracks",createHashMap];
// Audit-only markers show each destination without changing the units or their orders.
private _draw = addMissionEventHandler ["Draw3D",{
    private _cameraPosition=positionCameraToWorld [0,0,0];
    private _renderDistance=2500;
    private _group = missionNamespace getVariable ["Waldo_CortexQA_Infantry",grpNull];
    {
        private _slot = _x getVariable ["Waldo_AIPass_GarrisonPos",_x getVariable ["Waldo_AIPass_DefendPos",[]]];
        if (_slot isNotEqualTo []) then {
            private _position = _slot select 0;
            private _remaining = _x distance _position;
            private _colour = [[1,0.7,0,1],[0.2,1,0.3,1]] select (_remaining <= 2);
            drawIcon3D ["\a3\ui_f\data\map\markers\military\objective_ca.paa",_colour,_position vectorAdd [0,0,1],0.8,0.8,0,format ["Soldier %1 destination | %2 m remaining",_forEachIndex+1,round _remaining],2,0.035,"RobotoCondensed"];
            drawLine3D [getPosATL _x vectorAdd [0,0,1],_position vectorAdd [0,0,1],_colour];
        };
    } forEach units _group;
    {
        private _track = _y;
        if (_track isNotEqualTo [] && {(_track select (count _track-1)) distance2D _cameraPosition <= _renderDistance}) then {
            for "_i" from 1 to (count _track-1) do {drawLine3D [(_track select (_i-1)) vectorAdd [0,0,0.12],(_track select _i) vectorAdd [0,0,0.12],[0.1,1,1,0.8]]};
        };
    } forEach (missionNamespace getVariable ["Waldo_CortexQA_Tracks",createHashMap]);
    {
        private _label=_x getVariable ["Waldo_CortexQA_Label",typeOf _x];
        private _target = _x getVariable ["Waldo_CortexQA_Target",[]];
        if (_target isNotEqualTo []) then {
            private _distance = _x distance _target;
            private _colour = [[1,0.7,0,1],[0.2,1,0.3,1]] select (_distance <= 2);
            drawLine3D [(getPosATL _x) vectorAdd [0,0,1],_target vectorAdd [0,0,0.5],_colour];
            drawIcon3D ["\a3\ui_f\data\map\markers\military\objective_ca.paa",_colour,_target vectorAdd [0,0,1],0.7,0.7,0,format ["%1 | %2 m",_label,round _distance],2,0.03,"RobotoCondensed"];
        };

        private _text=format ["%1 | %2 | %3 km/h | %4 mags | aim %5",_label,stance _x,round speed _x,count magazinesAmmo _x,(_x skill "aimingAccuracy") toFixed 2];
        if (_x isKindOf "LandVehicle") then {
            private _target=assignedTarget gunner _x;
            if (!isNull _target) then {drawLine3D [(getPosATL _x) vectorAdd [0,0,2],(getPosATL _target) vectorAdd [0,0,1],[1,0.25,0.15,1]]};
            _text=format ["%1 | %2 km/h | shots %3 | gunner target: %4",_label,round speed _x,count (_x getVariable ["Waldo_CortexQA_Shots",[]]),if (isNull _target) then {"none assigned"} else {format ["%1 m",round (_x distance2D _target)]}];
        };
        private _aaLauncher=_x getVariable ["Waldo_CortexQA_AALauncher",objNull];
        if (!isNull _aaLauncher) then {
            _text=format ["%1 | altitude %2 m | missiles %3 | warnings %4 | CM shots %5 | evasive travel %6 / 5 m",
                _label,round (getPosATL _x select 2),_aaLauncher getVariable ["Waldo_CortexQA_Missiles",0],
                count (_x getVariable ["Waldo_CortexQA_MissileWarnings",[]]),_x getVariable ["Waldo_CortexQA_Flares",0],
                round (_x getVariable ["Waldo_CortexQA_EvasiveDeparture",0])];
            drawLine3D [(getPosATL _aaLauncher) vectorAdd [0,0,2],getPosATL _x,[1,0.25,0.15,1]];
        };
        private _airPlan=_x getVariable ["Waldo_Cortex_AirAttackPlan",[]];
        if (count _airPlan >= 10) then {
            _airPlan params ["_token","_pattern","_stage","_airTarget","_destination","_remaining","_shots","_aaCount","_airSpeed","_altitude",["_approachCM",0],["_egressCM",0],["_platform","AIRCRAFT"],["_lateralTurret",false],["_standoffWeapon",""],["_standoffTurret",[]],["_fireSolution",[]],["_stageAltitudes",[]],["_stageSpeeds",[]],["_captureRadii",[]],["_attackMinimum",0],["_points",[]],["_selectedWeapon",""],["_selectedSimulation",""],["_selectedTurret",[]]];
            private _request=_x getVariable ["Waldo_Cortex_CountermeasureLastRequest",[]];
            private _cm=if (count _request >= 2) then {["REFUSED","REQUESTED"] select (_request select 1)} else {"NONE"};
            _text=format ["%1 | %2 %3 / %4 | %5 km/h | altitude %6 m | remaining %7 m | actual shots %8 | observed AA %9 | CM %10 A:%11 E:%12 | weapon %13 (%14) solution %15",
                _label,_platform,_pattern,_stage,round _airSpeed,round _altitude,round _remaining,_shots,_aaCount,_cm,_approachCM,_egressCM,_selectedWeapon,_selectedSimulation,_fireSolution];
            drawLine3D [(getPosATL _x) vectorAdd [0,0,2],_destination,[0.1,1,1,0.9]];
            drawIcon3D ["\a3\ui_f\data\map\markers\military\objective_ca.paa",[1,0.7,0,1],_destination,0.8,0.8,0,format ["%1 %2 destination",_pattern,_stage],2,0.03,"RobotoCondensed"];
            if (!isNull _airTarget) then {drawLine3D [(getPosATL _x) vectorAdd [0,0,2],(getPosATL _airTarget) vectorAdd [0,0,2],[1,0.25,0.15,0.8]]};
        };
        private _standoff=_x getVariable ["Waldo_CortexQA_Standoff",[]];
        if (_standoff isNotEqualTo []) then {
            _standoff params ["_threat","_origin","_baseline","_detected"];
            _text=format ["%1 | %2 km/h | detection check: %3 | travel %4 / 40 m | separation gained %5 / 60 m",
                _label,round speed _x,["FAILED","PASSED"] select _detected,
                round (_x distance2D _origin),round ((_x distance2D _threat)-_baseline)];
        };
        private _flow=(group _x) getVariable ["Waldo_Cortex_Consolidation",[]];
        if (_flow isNotEqualTo []) then {
            private _leader=leader group _x;
            _text=_text+format [" | %1 | leader %2 m | gathered %3/%4",_flow select 0,round (_x distance2D _leader),_flow select 1,_flow select 2];
            if (_x != _leader) then {drawLine3D [(getPosATL _x) vectorAdd [0,0,1],(getPosATL _leader) vectorAdd [0,0,1],[0.3,0.8,1,0.8]]};
        };
        private _decel=_x getVariable ["Waldo_CortexQA_Deceleration",[]];
        if (count _decel == 4) then {
            _text=format ["%1 | %2 km/h | altitude %3 m | climb %4 m | correction %5",_label,round speed _x,_decel select 0,_decel select 1,if (_decel select 3) then {"ACTIVE"} else {["not observed","completed"] select (_decel select 2)}];
        };
        drawIcon3D ["",[0.2,1,1,1],(getPosATL _x) vectorAdd [0,0,2.3],0,0,0,_text,2,0.028,"RobotoCondensed"];
    } forEach ((missionNamespace getVariable ["Waldo_CortexQA_Actors",[]]) select {
        !isNull _x && {_x distance2D _cameraPosition <= _renderDistance}
    });
    private _combined=missionNamespace getVariable ["Waldo_CortexQA_Combined",[]];
    if (count _combined >= 7) then {
        _combined params ["_scenario","_stage","_requester","_combinedTarget","_assets","_stageStarted","_note"];
        private _anchor=if (isNull _requester || {isNull leader _requester}) then {[0,0,0]} else {getPosATL leader _requester};
        if (_anchor distance2D _cameraPosition <= _renderDistance) then {
            if (!isNull _combinedTarget) then {
                drawLine3D [_anchor vectorAdd [0,0,1.4],(getPosATL _combinedTarget) vectorAdd [0,0,1.2],[1,0.25,0.15,0.9]];
            };
            drawIcon3D ["",[1,0.7,0,1],_anchor vectorAdd [0,0,4],0,0,0,
                format ["%1 | %2 | %3 s | %4",_scenario,_stage,round (serverTime-_stageStarted),_note],2,0.032,"RobotoCondensed"];
            {
                _x params ["_assetGroup","_asset","_declaredRole"];
                if (!isNull _asset && {!isNull _assetGroup}) then {
                    private _role=(_assetGroup getVariable ["Waldo_Cortex_CombinedRole",[]]) param [4,"NONE"];
                    private _result=(_assetGroup getVariable ["Waldo_Cortex_CombinedResult",[]]) param [2,"WAITING"];
                    private _detail=format ["offered %1 | live role %2 | %3",_declaredRole,_role,_result];
                    if (_asset isKindOf "CAManBase") then {
                        private _state=_assetGroup getVariable ["Waldo_AIPass_State",createHashMap];
                        private _drill=_state getOrDefault ["drill",createHashMap];
                        private _lease=_state getOrDefault ["movementLease",[]];
                        private _support=_assetGroup getVariable ["Waldo_Cortex_SupportRole",[]];
                        _detail=format ["%1 | phase %2 | tactic %3/%4 | movement %5 | support %6",
                            _declaredRole,_state getOrDefault ["phase","IDLE"],
                            _drill getOrDefault ["type","FREE"],_drill getOrDefault ["stage","FREE"],
                            _lease param [0,"ENGINE"],_support param [1,"INDEPENDENT"]];
                    };
                    private _colour=if (_result == "APPLIED") then {[0.2,1,0.3,0.9]} else {[0.2,0.65,1,0.9]};
                    drawLine3D [_anchor vectorAdd [0,0,1.2],(getPosATL _asset) vectorAdd [0,0,2],_colour];
                    drawIcon3D ["",_colour,(getPosATL _asset) vectorAdd [0,0,5],0,0,0,
                        format ["%1 | %2",groupId _assetGroup,_detail],2,0.03,"RobotoCondensed"];
                };
            } forEach _assets;
        };
    };
    private _rooms=missionNamespace getVariable ["Waldo_CortexQA_Rooms",[]];
    if (_rooms isNotEqualTo []) then {
        {private _visited=(_rooms select 1) select _forEachIndex; drawIcon3D ["\a3\ui_f\data\map\markers\military\objective_ca.paa",[[1,0.7,0,1],[0.2,1,0.3,1]] select _visited,_x vectorAdd [0,0,0.5],0.7,0.7,0,format ["Building position %1 | %2",_forEachIndex+1,["not visited","physical visit"] select _visited],2,0.03,"RobotoCondensed"]} forEach (_rooms select 0);
    };
    private _convoyVehicles = missionNamespace getVariable ["Waldo_CortexQA_ConvoyVehicles",[]];
    {
        private _text = format ["Vehicle %1 | %2 km/h",_forEachIndex+1,round abs speed _x];
        if (_forEachIndex > 0) then {
            private _front = _convoyVehicles select (_forEachIndex-1);
            private _gap = _x distance2D _front;
            private _band = _x getVariable ["Waldo_CortexQA_GapBand",[24,36]];
            _text = _text + format [" | gap %1 m | band %2-%3 m",round _gap,round (_band select 0),round (_band select 1)];
            private _colour = [[1,0.7,0,1],[0.2,1,0.3,1]] select (_gap >= (_band select 0) && {_gap <= (_band select 1)});
            drawLine3D [(getPosATL _x) vectorAdd [0,0,2],(getPosATL _front) vectorAdd [0,0,2],_colour];
        };
        drawIcon3D ["",[0.1,1,1,1],(getPosATL _x) vectorAdd [0,0,4],0,0,0,_text,2,0.032,"RobotoCondensed"];
    } forEach _convoyVehicles;
    private _combat = missionNamespace getVariable ["Waldo_CortexQA_Combat",[]];
    if (_combat isNotEqualTo []) then {
        _combat params ["_combatGroup","_mode","_stage","_element","_spots","_points","_enemyPosition","_boundIndex","_ending"];
        private _stageLabel = _stage;
        private _boundLabel = "Bound";
        if (_boundIndex >= 0 && {_boundIndex < count _points}) then {
            private _kind = (_points select _boundIndex) select 1;
            _boundLabel = switch (_kind) do {
                case "ASSAULT": {"Assault approach"};
                case "CLEAR": {"Clear through"};
                case "CONSOLIDATE": {"Support consolidation"};
                default {"Bound"};
            };
            if (_stage in ["MOVE","LATE: MOVE"]) then {_stageLabel = _boundLabel+" / "+_stage};
        };
        if (_stage == "GRENADE") then {_stageLabel = "HOLD / waiting for grenade clearance"};
        private _living = _element select {alive _x};
        if (_living isNotEqualTo []) then {
            private _centre = [0,0,0];
            {_centre = _centre vectorAdd getPosATL _x} forEach _living;
            _centre = _centre vectorMultiply (1 / count _living);
            private _heading = _centre getDir _enemyPosition;
            private _side = [cos _heading,-sin _heading,0];
            private _front = [sin _heading,cos _heading,0];
            private _lateral = _living apply {((getPosATL _x) vectorDiff _centre) vectorDotProduct _side};
            private _depth = _living apply {((getPosATL _x) vectorDiff _centre) vectorDotProduct _front};
            private _width = (selectMax _lateral) - (selectMin _lateral);
            private _length = (selectMax _depth) - (selectMin _depth);
            drawLine3D [_centre vectorAdd [0,0,0.5],(_centre getPos [20,_heading]) vectorAdd [0,0,0.5],[1,0.2,0.2,1]];
            drawLine3D [(_centre getPos [selectMin _lateral,_heading+90]) vectorAdd [0,0,0.5],(_centre getPos [selectMax _lateral,_heading+90]) vectorAdd [0,0,0.5],[0.1,1,1,1]];
            drawIcon3D ["",[0.1,1,1,1],_centre vectorAdd [0,0,3],0,0,0,format ["ACTUAL element: %1 m frontage / %2 m depth | red axis faces threat",round _width,round _length],2,0.03,"RobotoCondensed"];
        };

        {
            private _elementIndex = _element find _x;
            private _moving = _elementIndex >= 0;
            private _colour = [[0.2,0.65,1,1],[1,0.75,0.1,1]] select _moving;
            private _role = ["SUPPORT","MANOEUVRE"] select _moving;
            private _actor=_x;
            private _recovery=_combatGroup getVariable ["Waldo_Cortex_DrillRecovery",[]];
            if (_actor in (_recovery param [1,[]])) then {
                _role = if ((_recovery param [0,""]) == "REJOINING" && {_ending isEqualTo []}) then {"STRAGGLER - REJOINING"} else {"SEPARATED AT END"};
                _colour=[1,0.3,0.1,1];
            };
            private _shotRows=_combat param [9,[]];
            private _shotIndex=_shotRows findIf {(_x select 0) == _actor};
            private _shots=if (_shotIndex < 0) then {[objNull,0,0]} else {_shotRows select _shotIndex};
            drawIcon3D ["",_colour,(getPosATL _actor) vectorAdd [0,0,2],0,0,0,format ["%1 %2 | %3 | %4 | shots %5 / moving %6",_role,_forEachIndex+1,_mode,_stageLabel,_shots select 1,_shots select 2],2,0.03,"RobotoCondensed"];
            if (_moving && {_elementIndex < count _spots}) then {
                private _spot = _spots select _elementIndex;
                private _distance = _x distance2D _spot;
                private _arrivalColour = [_colour,[0.2,1,0.3,1]] select (_distance <= 3);
                drawIcon3D ["\a3\ui_f\data\map\markers\military\objective_ca.paa",_arrivalColour,_spot vectorAdd [0,0,0.8],0.7,0.7,0,format ["%1 %2 | Soldier %3 | %4 m",_boundLabel,_boundIndex+1,_forEachIndex+1,round _distance],2,0.03,"RobotoCondensed"];
                drawLine3D [(getPosATL _x) vectorAdd [0,0,1],_spot vectorAdd [0,0,0.8],_arrivalColour];
            };
        } forEach units _combatGroup;
        {
            _x params ["_position","_kind"];
            private _colour = [[0.65,0.65,0.65,0.7],[1,0.75,0.1,1]] select (_forEachIndex == _boundIndex);
            drawIcon3D ["\a3\ui_f\data\map\markers\military\dot_ca.paa",_colour,_position vectorAdd [0,0,0.3],0.5,0.5,0,format ["%1: %2",_forEachIndex+1,_kind],2,0.026,"RobotoCondensed"];
            if (_forEachIndex > 0) then {drawLine3D [((_points select (_forEachIndex-1)) select 0) vectorAdd [0,0,0.3],_position vectorAdd [0,0,0.3],_colour]};
        } forEach _points;
        drawIcon3D ["\a3\ui_f\data\map\markers\military\objective_ca.paa",[1,0.2,0.2,1],_enemyPosition vectorAdd [0,0,2],0.8,0.8,0,"ENEMY TEST POSITION",2,0.035,"RobotoCondensed"];
        if (_ending isNotEqualTo []) then {
            drawIcon3D ["",[1,0.5,0.2,1],(getPosATL leader _combatGroup) vectorAdd [0,0,4],0,0,0,format ["%1 ended: %2",_mode,_ending param [1,"UNKNOWN"]],2,0.04,"RobotoCondensed"];
        };
    };
}];
missionNamespace setVariable ["Waldo_CortexQA_DrawHandler",_draw];
disableSerialization;
private _host = displayNull;
private _controls = [];
private _last = "";
private _nextSample = 0;
while {true} do {
    if (diag_tickTime >= _nextSample) then {
        _nextSample=diag_tickTime+1;
        private _combat = missionNamespace getVariable ["Waldo_CortexQA_Combat",[]];
        private _actors = units (missionNamespace getVariable ["Waldo_CortexQA_Infantry",grpNull]);
        if (_combat isNotEqualTo []) then {_actors append units (_combat select 0)};
        _actors append (missionNamespace getVariable ["Waldo_CortexQA_Actors",[]]);
        _actors append (missionNamespace getVariable ["Waldo_CortexQA_ConvoyVehicles",[]]);
        _actors = (_actors select {!isNull _x}) arrayIntersect _actors;
        if (count _actors > 12) then {_actors resize 12};
        private _tracks = missionNamespace getVariable ["Waldo_CortexQA_Tracks",createHashMap];
        private _keys = _actors apply {netId _x};
        {if !(_x in _keys) then {_tracks deleteAt _x}} forEach keys _tracks;
        {
            private _key=netId _x;
            private _track=_tracks getOrDefault [_key,[]];
            private _position=getPosATL _x;
            if (_track isEqualTo [] || {_position distance (_track select (count _track-1)) > 2}) then {_track pushBack _position};
            if (count _track > 48) then {_track deleteRange [0,count _track-48]};
            _tracks set [_key,_track];
        } forEach _actors;
    };
    private _next = findDisplay 312;
    if (isNull _next) then {_next = findDisplay 46};
    if (!isNull _next && {_next != _host}) then {
        {ctrlDelete _x} forEach _controls;
        ["CORTEX_QA"] call Waldo_fnc_UnregisterUiReservationLocal;
        _host = _next;
        private _theme = [] call Waldo_fnc_UiTheme;
        private _back = _host ctrlCreate ["RscText",-1];
        private _body = _host ctrlCreate ["RscStructuredText",-1];
        private _inspect = _host ctrlCreate ["RscButton",-1];
        private _x = safeZoneX + safeZoneW*0.28;
        private _y = safeZoneY + safeZoneH*0.64;
        private _w = safeZoneW*0.43;
        private _h = safeZoneH*0.30;
        _back ctrlSetPosition [_x,_y,_w,_h]; _back ctrlSetBackgroundColor (_theme get "panel"); _back ctrlCommit 0;
        _body ctrlSetPosition [_x+_w*0.025,_y+_h*0.03,_w*0.95,_h*0.72]; _body ctrlSetTextColor (_theme get "text"); _body ctrlCommit 0;
        private _inZeus=!isNull findDisplay 312;
        _inspect ctrlSetPosition [_x+_w*0.025,_y+_h*0.79,_w*0.95,_h*0.17];
        _inspect ctrlSetText (["Open Zeus, then inspect the current test","Inspect current test in Zeus"] select _inZeus);
        _inspect ctrlEnable _inZeus;
        _inspect ctrlCommit 0;
        _inspect ctrlAddEventHandler ["ButtonClick",{
            private _phase = missionNamespace getVariable ["Waldo_CortexQA_Phase",[]];
            private _position = _phase param [2,[]];
            if (!isNull curatorCamera && {count _position >= 2}) then {
                curatorCamera setPosASL (AGLToASL [(_position select 0),(_position select 1)-35,30]);
                curatorCamera setDir 0;
                [curatorCamera,-35,0] call BIS_fnc_setPitchBank;
            };
        }];
        _controls = [_back,_body,_inspect];
        ["CORTEX_QA",_controls,["BOTTOM_CENTER"],true] call Waldo_fnc_RegisterUiReservationLocal;
        _last = "";
    };
    private _phase = missionNamespace getVariable ["Waldo_CortexQA_Phase",["Preparing","Waiting for the client and both headless clients.",[]]];
    private _results = missionNamespace getVariable ["Waldo_CortexQA_Results",[]];
    private _failed = {(_x select 1) == "FAIL"} count _results;
    private _text = format ["<t size='1.1'>CORTEX AUDIT [%8]: %1</t><br/>LOOK FOR: %2<br/>Live settings: %7<br/>Completed checks: %3 | Failures: %4<br/>%5<br/>%6",_phase select 0,_phase select 1,count _results,_failed,(_results select [((count _results)-3) max 0,3] apply {format ["%1: %2",_x select 0,_x select 1]}) joinString "<br/>",if (missionNamespace getVariable ["Waldo_CortexQA_ClientDone",false]) then {"RUN FINISHED. Review completion results."} else {format ["RUNNING: %1 seconds in this stage. Pending checks have not passed.",floor (serverTime-(_phase param [3,serverTime]))]},format ["Cortex %1 | Contact %2 | Regroup %3",["OFF","ON"] select (missionNamespace getVariable ["Waldo_AIPass_Enable",false]),["OFF","ON"] select (missionNamespace getVariable ["Waldo_AIPass_Contact_Enable",true]),["OFF","ON"] select (missionNamespace getVariable ["Waldo_AIPass_Regroup_Enable",true])],missionNamespace getVariable ["Waldo_CortexQA_Focus","all"]];
    if (_text != _last && {count _controls > 0}) then {(_controls select 1) ctrlSetStructuredText parseText _text; _last = _text};
    uiSleep 0.5;
};
