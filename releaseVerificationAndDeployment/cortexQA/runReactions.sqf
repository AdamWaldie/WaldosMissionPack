/*
 * Author: WaldoTheWarfighter
 * Exercises cover stance, live grenade evasion, civilian danger responses and casualty-driven
 * retreat/surrender, including terminal CONTACT -> RETREAT -> REGROUP and CONTACT -> CALM/SURRENDER
 * handovers. Civilian checks measure real travel and later Zeus replacement-order execution. The
 * additive two-squad withdrawal keeps its deterministic VR baseline, but on terrain worlds rotates
 * the full contact and escape geometry onto a measured dry corridor with relief and separate lanes.
 * Locality/authority: scheduled dedicated-server audit, with server-pinned disposable actors.
 * Repeat/JIP: fresh actors per case; settings restored by the calling audit; observer data is public.
 * Arguments: 0: check <CODE>; 1: phase <CODE>; 2: wait <CODE>, required callbacks.
 * Return: Nothing. Current caller: cortexQAServer.sqf.
 * Example: [_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQAReactions.sqf";
 */
params ["_check","_phase","_wait"];
private _groups=[];
private _objects=[];
private _newGroup={
    params ["_side"];
    private _group=createGroup [_side,true];
    _group setVariable ["Waldo_Headless_ExcludeGroup",true,true];
    _group setVariable ["acex_headless_blacklist",true,true];
    _group allowFleeing 0;
    _groups pushBack _group;
    _group
};
private _newUnit={
    params ["_group","_position","_label"];
    private _unit=_group createUnit [["O_Soldier_F","B_Soldier_F"] select (side _group == west),_position,[],0,"NONE"];
    _unit setVariable ["acex_headless_blacklist",true,true];
    _unit setVariable ["Waldo_CortexQA_Label",_label,true];
    _objects pushBack _unit;
    _unit
};
private _cleanup={
    {deleteVehicle _x} forEach _objects;
    {deleteGroup _x} forEach _groups;
    _objects=[]; _groups=[];
    missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];
};
private _base=createHashMapFromArray [
    ["Waldo_AIPass_Enable",true],["Waldo_AIRebalance_Enable",false],
    ["Waldo_AIPass_Contact_Enable",true],["Waldo_AIPass_LambsMode","WMP"],
    ["Waldo_AIPass_Regroup_Enable",false],["Waldo_AIPass_Flank_Enable",false],
    ["Waldo_AIPass_Advance_Enable",false],["Waldo_AIPass_Reinforce_Enable",false],
    ["Waldo_AIPass_ContactReports_Enable",false],["Waldo_AIPass_CoordinatedAssault_Enable",false],
    ["Waldo_AIPass_Morale_Enable",false],["Waldo_AIPass_Stance_Enable",false],
    ["Waldo_AIPass_FireControl_Enable",false],["Waldo_AIPass_Artillery_Enable",false],
    ["Waldo_AIPass_AmmoShare_Enable",false],["Waldo_AIPass_GrenadeEvasion_Enable",false]
];
[_base] call Waldo_fnc_CortexTuning;
private _group=[east] call _newGroup;
private _soldier=[_group,[1400,1100,0],"COVER STANCE"] call _newUnit;
private _opposition=[west] call _newGroup;
_opposition setVariable ["Waldo_AIPass_Exclude",true,true];
private _enemy=[_opposition,[1400,1170,0],"VISIBLE THREAT"] call _newUnit;
{_x setCombatMode "BLUE"} forEach [_group,_opposition];
{_x disableAI "PATH"; _x allowDamage false} forEach [_soldier,_enemy];
private _wall=createVehicle ["Land_BagFence_Long_F",[1400,1102,0],[],0,"CAN_COLLIDE"];
_objects pushBack _wall;
missionNamespace setVariable ["Waldo_CortexQA_Actors",[_soldier,_enemy],true];
["Cover stance disabled","The soldier faces a low sandbag wall. Cortex must leave the stance setting on Auto while this feature is disabled; ordinary engine animations may still change.",[1400,1100,0]] call _phase;
sleep 12;
["STANCE-disabled-authored-mode",toUpperANSI unitPos _soldier == "AUTO"] call _check;
[createHashMapFromArray [["Waldo_AIPass_Stance_Enable",true]]] call Waldo_fnc_CortexTuning;
["Cover stance enabled","The soldier must adopt a crouched or prone pose behind the sandbags. The check reads the actual stance as well as the requested posture. No pose is assigned by the test.",[1400,1100,0]] call _phase;
private _posed=[{toUpperANSI unitPos _soldier in ["DOWN","MIDDLE"] && {stance _soldier in ["PRONE","CROUCH"]}},35] call _wait;
["STANCE-physical-pose",_posed,format ["requested=%1 actual=%2",unitPos _soldier,stance _soldier]] call _check;
[createHashMapFromArray [["Waldo_AIPass_Stance_Enable",false]]] call Waldo_fnc_CortexTuning;
["STANCE-disable-restores-auto",[{toUpperANSI unitPos _soldier == "AUTO"},15] call _wait] call _check;
{
    private _zeus=_x;
    _soldier setUnitPos "AUTO";
    [createHashMapFromArray [["Waldo_AIPass_Stance_Enable",true]]] call Waldo_fnc_CortexTuning;
    private _ownedPose=[{toUpperANSI unitPos _soldier in ["DOWN","MIDDLE"]
        && {stance _soldier in ["PRONE","CROUCH"]}
        && {_soldier getVariable ["Waldo_AIPass_StanceSet",false]}},35] call _wait;
    private _case=["gate","zeus"] select _zeus;
    ["STANCE-"+_case+"-override-stimulus",_ownedPose] call _check;
    _soldier setUnitPos "UP";
    ["Cover stance: preserve later standing order","The soldier has received a later explicit standing order. Watch him remain standing while Cortex releases its previous cover stance. This uses the production takeover endpoint; curator UI event delivery is a separate test.",[1400,1100,0]] call _phase;
    if (_zeus) then {[_group,true] call Waldo_fnc_CortexZeusMark} else {
        [createHashMapFromArray [["Waldo_AIPass_Stance_Enable",false]]] call Waldo_fnc_CortexTuning;
    };
    private _standing=[{toUpperANSI unitPos _soldier == "UP" && {stance _soldier == "STAND"}
        && {!(_soldier getVariable ["Waldo_AIPass_StanceSet",false])}},20] call _wait;
    private _held=true;
    for "_sample" from 1 to 12 do {sleep 1; if (toUpperANSI unitPos _soldier != "UP" || {stance _soldier != "STAND"}) then {_held=false}};
    ["STANCE-"+_case+"-preserves-physical-override",_ownedPose && {_standing} && {_held},str [unitPos _soldier,stance _soldier]] call _check;
} forEach [false,true];
call _cleanup;

// Firing acceptance is separate from the hold-fire posture/cleanup cases above.
{
    private _covered=_x;
    private _case=["open","low-cover"] select _covered;
    [createHashMapFromArray [["Waldo_AIPass_Stance_Enable",_covered]]] call Waldo_fnc_CortexTuning;
    _group=[east] call _newGroup;
    _soldier=[_group,[1450,1100,0],"COVER FIRING SOLDIER"] call _newUnit;
    _soldier setDir 0; _soldier allowDamage false;
    _soldier addEventHandler ["FiredMan",{
        params ["_unit"];
        _unit setVariable ["Waldo_CortexQA_ActualShots",(_unit getVariable ["Waldo_CortexQA_ActualShots",0])+1,true];
        private _position=getPosATL _unit;
        if (_position distance2D [1450,1100,0] <= 5 && {_position select 1 < 1102}) then {
            _unit setVariable ["Waldo_CortexQA_CoverShots",(_unit getVariable ["Waldo_CortexQA_CoverShots",0])+1,true];
        };
    }];
    _opposition=[west] call _newGroup;
    _opposition setVariable ["Waldo_AIPass_Exclude",true,true];
    _enemy=[_opposition,[1450,1170,0],"FIRING TARGET"] call _newUnit;
    removeAllWeapons _enemy; _enemy disableAI "PATH";
    _enemy addEventHandler ["HandleDamage",{
        params ["_unit","_selection","_damage","_source","_projectile"];
        if (_projectile != "") then {
            _unit setVariable ["Waldo_CortexQA_HitEvents",(_unit getVariable ["Waldo_CortexQA_HitEvents",0])+1,true];
        };
        0
    }];
    _group setCombatMode "RED"; _opposition setCombatMode "BLUE";
    if (_covered) then {_objects pushBack (createVehicle ["Land_BagFence_Long_F",[1450,1102,0],[],0,"CAN_COLLIDE"])};
    missionNamespace setVariable ["Waldo_CortexQA_Actors",[_soldier,_enemy],true];
    ["Cover firing: "+_case,"Watch actual shots and projectile hit events at the unarmed target. The soldier starts facing the target and can move naturally. Adopting a stance or aiming alone cannot pass. Compare the open control with the low sandbag wall.",[1450,1100,0]] call _phase;
    private _effective=[{
        private _shots=_soldier getVariable ["Waldo_CortexQA_ActualShots",0];
        private _hits=_enemy getVariable ["Waldo_CortexQA_HitEvents",0];
        _soldier setVariable ["Waldo_CortexQA_Label",format ["FIRING %1 | shots %2 | target hit events %3 | pose %4",_case,_shots,_hits,stance _soldier],true];
        _shots >= 3 && {_hits > 0}
    },60] call _wait;
    ["STANCE-"+_case+"-actual-fire-and-hit",_effective,str [_soldier getVariable ["Waldo_CortexQA_ActualShots",0],_enemy getVariable ["Waldo_CortexQA_HitEvents",0],getPosATL _soldier,stance _soldier]] call _check;
    if (_covered) then {
        ["STANCE-low-cover-fire-from-covered-area",_effective && {(_soldier getVariable ["Waldo_CortexQA_CoverShots",0]) >= 3},
            format ["shotsBehindCover=%1 finalPosition=%2",_soldier getVariable ["Waldo_CortexQA_CoverShots",0],getPosATL _soldier]] call _check;
    };
    call _cleanup;
} forEach [false,true];

// Queue cancellation is atomic with the state transition so the next-frame worker
// cannot run before the fixture changes state. Observe FiredMan and inventory.
{
    private _case=_x;
    _group=[east] call _newGroup;
    _soldier=[_group,[1400,1100,0],"QUEUED SMOKE / "+_case] call _newUnit;
    private _frag = _case == "ASSAULT-DISABLED";
    private _magazine = ["SmokeShell","HandGrenade"] select _frag;
    _soldier addMagazine _magazine;
    if (_frag) then {
        [createHashMapFromArray [["Waldo_AIPass_Assault_Enable",true]]] call Waldo_fnc_CortexTuning;
    };
    _soldier setVariable ["Waldo_CortexQA_ThrowCount",0];
    _soldier addEventHandler ["FiredMan",{
        params ["_unit","_weapon"];
        if (_weapon == "Throw") then {_unit setVariable ["Waldo_CortexQA_ThrowCount",(_unit getVariable ["Waldo_CortexQA_ThrowCount",0])+1,true]};
    }];
    missionNamespace setVariable ["Waldo_CortexQA_Actors",[_soldier],true];
    ["Queued grenade cancellation: "+_case,"A carried grenade is queued, then captivity, Zeus takeover, drill replacement or assault disable must cancel it before execution. No grenade should leave the hand; inventory must stay unchanged.",[1400,1100,0]] call _phase;
    private _before={_x == _magazine} count magazines _soldier;
    private _queued=false;
    private _queuedToken="";
    isNil {
        // Establish ownership before the stimulus. Discovery must not erase the
        // test generation during the presentation delay or next-frame throw.
        if !(_group getVariable ["Waldo_AIPass_Adopted",false]) then {
            [_group,true] call Waldo_fnc_CortexLocality;
        };
        if (_frag) then {
            private _state=_group getVariable ["Waldo_AIPass_State",createHashMap];
            _state set ["drill",createHashMapFromArray [["token","QA-FRAG-CANCEL"]]];
            _group setVariable ["Waldo_AIPass_State",_state];
        };
        _queuedToken=((_group getVariable ["Waldo_AIPass_State",createHashMap]) getOrDefault ["drill",createHashMap]) getOrDefault ["token",""];
        _queued=[_soldier,[1400,1125,0],["SMOKE","FRAG"] select _frag] call Waldo_fnc_CortexThrowGrenade;
        switch (_case) do {
            case "ASSAULT-DISABLED": {[createHashMapFromArray [["Waldo_AIPass_Assault_Enable",false]]] call Waldo_fnc_CortexTuning};
            case "CAPTIVE": {_soldier setCaptive true};
            case "ZEUS": {[_group] call Waldo_fnc_CortexZeusMark};
            case "DRILL-REPLACED": {
                // Inject only the replacement generation, never a successful throw/result.
                private _state=_group getVariable ["Waldo_AIPass_State",createHashMap];
                _state set ["drill",createHashMapFromArray [["token","QA-NEW-GENERATION"]]];
                _group setVariable ["Waldo_AIPass_State",_state];
            };
        };
    };
    sleep 3;
    private _shots=_soldier getVariable ["Waldo_CortexQA_ThrowCount",0];
    private _after={_x == _magazine} count magazines _soldier;
    ["GRENADE-queued-"+_case+"-cancel",_queued && {!_frag || {_queuedToken == "QA-FRAG-CANCEL"}} && {_shots == 0} && {_after == _before},format ["queued=%1 throws=%2 before=%3 after=%4 token=%5",_queued,_shots,_before,_after,_queuedToken]] call _check;
    call _cleanup;
} forEach ["CAPTIVE","ZEUS","DRILL-REPLACED","ASSAULT-DISABLED"];

// A real projectile enters the production ProjectileCreated path. The test never calls its worker.
[createHashMapFromArray [["Waldo_AIPass_Contact_Enable",false],["Waldo_AIPass_GrenadeEvasion_Enable",true]]] call Waldo_fnc_CortexTuning;
_group=[east] call _newGroup;
_soldier=[_group,[1400,1100,0],"GRENADE EVASION"] call _newUnit;
_soldier setSkill ["general",1];
_soldier allowDamage false;
doStop _soldier;
missionNamespace setVariable ["Waldo_CortexQA_Actors",[_soldier],true];
["Live grenade evasion","A real grenade appears three metres north of the soldier. Watch for physical movement away before it explodes, then return to normal orders. The soldier is invulnerable for this case.",[1400,1100,0]] call _phase;
private _start=getPosATL _soldier;
private _grenadePosition=_start vectorAdd [0,3,0.2];
private _grenade=createVehicle ["GrenadeHand",_grenadePosition,[],0,"CAN_COLLIDE"];
_objects pushBack _grenade;
private _escaped=[{_soldier distance2D _start >= 4 && {_soldier distance2D _grenadePosition >= 7}},6] call _wait;
["GRENADE-physical-escape",_escaped,format ["travel=%1 grenadeDistance=%2",_soldier distance2D _start,_soldier distance2D _grenadePosition]] call _check;
sleep 8;
call _cleanup;
// Use a distinct stationary leader: following oneself cannot expose stale regroup.
_group=[east] call _newGroup;
private _anchor=[_group,[1375,1100,0],"REGROUP LEADER / MUST NOT RECALL RUNNER"] call _newUnit;
_soldier=[_group,[1400,1100,0],"EVASION / REPLACEMENT RUNNER"] call _newUnit;
_group selectLeader _anchor;
_anchor disableAI "PATH";
{_x allowDamage false} forEach [_anchor,_soldier];
_soldier setSkill ["general",1];
doStop _soldier;
missionNamespace setVariable ["Waldo_CortexQA_Actors",[_anchor,_soldier],true];
// A second real grenade creates a fresh pending regroup. Replace its movement
// before the six-second callback, then require arrival beyond that deadline.
private _secondStart=getPosATL _soldier;
["Grenade evasion: replacement movement","After starting to evade another real grenade, the soldier receives a new movement destination 60 metres east. Watch the cyan trail: the delayed regroup must not pull him back to formation.",_secondStart] call _phase;
private _secondGrenade=createVehicle ["GrenadeHand",_secondStart vectorAdd [0,3,0.2],[],0,"CAN_COLLIDE"];
_objects pushBack _secondGrenade;
private _interrupted=[{_soldier distance2D _secondStart >= 1},4] call _wait;
private _replacement=_secondStart vectorAdd [60,0,0];
_soldier doMove _replacement;
private _nextMovementSample=0;
private _arrived=[{
    if (time >= _nextMovementSample) then {
        _nextMovementSample=time+1;
        diag_log format ["WMP CORTEX QA EVASION REPLACEMENT: pos=%1 destination=%2 command=%3 leader=%4 path=%5 alive=%6 target=%7",
            getPosATL _soldier,expectedDestination _soldier,currentCommand _soldier,netId leader _group,_soldier checkAIFeature "PATH",alive _soldier,_replacement];
    };
    _soldier distance2D _replacement < 4
},35] call _wait;
["GRENADE-replacement-movement",_interrupted && {_arrived},format ["interrupted=%1 remaining=%2",_interrupted,_soldier distance2D _replacement]] call _check;
[createHashMapFromArray [["Waldo_AIPass_GrenadeEvasion_Enable",false]]] call Waldo_fnc_CortexTuning;
["GRENADE-handler-disabled",[{isNil {missionNamespace getVariable "Waldo_AIPass_ProjectileHandler"}},10] call _wait] call _check;
call _cleanup;

{
    private _surrender=_x;
    [createHashMapFromArray [["Waldo_AIPass_Contact_Enable",true],["Waldo_AIPass_Morale_Enable",true],["Waldo_AIPass_Surrender_Enable",_surrender],["Waldo_AIPass_Cohesion",0.5],["Waldo_AIPass_Morale_RetreatDistance",80]]] call Waldo_fnc_CortexTuning;
    _group=[east] call _newGroup;
    private _squad=[];
    for "_i" from 0 to 5 do {
        private _unit=[_group,[1400+2*_i,1100,0],format ["CASUALTY TEST %1",_i+1]] call _newUnit;
        _unit setSkill ["courage",0.1];
        _squad pushBack _unit;
    };
    _opposition=[west] call _newGroup;
    _opposition setVariable ["Waldo_AIPass_Exclude",true,true];
    _enemy=[_opposition,[1400,1145,0],"NEARBY OPPOSITION"] call _newUnit;
    _enemy disableAI "PATH"; _enemy allowDamage false;
    {_x setCombatMode "BLUE"} forEach [_group,_opposition];
    missionNamespace setVariable ["Waldo_CortexQA_Actors",_squad+[_enemy],true];
    [format ["Casualty response: %1",["retreat","surrender"] select _surrender],"The squad first detects its opponent. Five real casualties then leave one isolated survivor. Low cohesion is an explicit test setting; the test does not assign morale or a completed outcome.",[1400,1100,0]] call _phase;
    private _contact=[{((_group getVariable ["Waldo_AIPass_State",createHashMap]) getOrDefault ["phase",""]) == "CONTACT"},35] call _wait;
    [format ["MORALE-%1-real-contact",_surrender],_contact] call _check;
    private _survivor=_squad select 5;
    _survivor allowDamage false;
    // Provide carried ammunition, then observe the real production throw path.
    _survivor addMagazine "SmokeShell";
    _survivor addEventHandler ["FiredMan",{
        params ["_unit","_weapon","_muzzle","_mode","_ammo","_magazine","_projectile"];
        if (getText (configFile >> "CfgAmmo" >> _ammo >> "simulation") in ["shotSmoke","shotSmokeX"] && {!isNull _projectile}) then {
            private _records=_unit getVariable ["Waldo_CortexQA_SmokeThrows",[]];
            _records pushBack [_ammo,time,getPosATL _projectile];
            _unit setVariable ["Waldo_CortexQA_SmokeThrows",_records,true];
        };
    }];
    private _originalWeapon=primaryWeapon _survivor;
    private _origin=getPosATL _survivor;
    // Keep the actual state object read-only: surrender cleanup removes the group
    // reference before the presentation card finishes, but does not erase this map.
    private _observedMoraleState=_group getVariable ["Waldo_AIPass_State",createHashMap];
    {_x setDamage 1} forEach (_squad select [0,5]);
    [format ["MORALE-%1-five-casualties",_surrender],[{({alive _x} count _squad) == 1},10] call _wait] call _check;
    diag_log format ["WMP CORTEX QA MORALE: contact=%1 peak=%2 survivors=%3 state=%4 courage=%5",_contact,_group getVariable ["Waldo_AIPass_PeakSize",0],_squad apply {[alive _x,lifeState _x]},_group getVariable ["Waldo_AIPass_State",createHashMap],_survivor skill "courage"];
    [format ["MORALE-%1-living-successor",_surrender],[{alive leader _group && {leader _group == _survivor}},12] call _wait] call _check;
    private _lowestMorale=1;
    private _sawBroken=false;
    private _sawRetreat=false;
    private _nextLabel=0;
    private _sampleMorale={
        private _live=_group getVariable ["Waldo_AIPass_State",_observedMoraleState];
        _lowestMorale=_lowestMorale min (_live getOrDefault ["morale",1]);
        _sawBroken=_sawBroken || {(_live getOrDefault ["moraleState",""]) == "BROKEN"};
        _sawRetreat=_sawRetreat || {(_live getOrDefault ["phase",""]) == "RETREAT"};
        if (time >= _nextLabel) then {
            _nextLabel=time+2;
            diag_log format ["WMP CORTEX QA LEADERSHIP: surrender=%1 leader=%2 alive=%3 survivorLeader=%4 currentWP=%5 phase=%6 destination=%7 hold=%8",
                _surrender,netId leader _group,alive leader _group,leader _group == _survivor,currentWaypoint _group,
                _live getOrDefault ["phase",""],expectedDestination _survivor,_group getVariable ["Waldo_AIPass_ZeusHold",[]]];
            _survivor setVariable ["Waldo_CortexQA_Label",format ["SURVIVOR | morale %1 | %2 | %3 | travel %4 m",(_live getOrDefault ["morale",1]) toFixed 2,_live getOrDefault ["moraleState","NO STATE"],_live getOrDefault ["phase","NO PHASE"],round (_survivor distance2D _origin)],true];
        };
    };
    if (_surrender) then {
        ["Surrender: physical disarm","The survivor must drop the rifle into a real ground holder and surrender. Inspect the empty hands and the weapon on the ground.",_origin] call _phase;
        private _disarmed=[{call _sampleMorale; primaryWeapon _survivor == "" && {captive _survivor || {_survivor getVariable ["ace_captives_isSurrendering",false]}}},45] call _wait;
        private _holders=nearestObjects [_survivor,["GroundWeaponHolder"],8];
        private _weaponOnGround=_holders findIf {_originalWeapon in ((getWeaponCargo _x) select 0)} >= 0;
        ["SURRENDER-disarm-and-capture",_contact && {_disarmed} && {_weaponOnGround}] call _check;
        private _surrenderTransition=(_group getVariable ["Waldo_Cortex_PhaseTransitions",[]]) findIf {
            (_x param [1,""]) == "CONTACT" && {(_x param [2,""]) == "CALM"}
                && {(_x param [3,""]) == "SURRENDER"}
        };
        ["SURRENDER-terminal-transition",_disarmed && {_surrenderTransition >= 0}
            && {(_group getVariable ["Waldo_AIPass_PublicPhase",""]) == "CALM"},
            str (_group getVariable ["Waldo_Cortex_PhaseTransitions",[]])] call _check;
        private _surrenderPosition=getPosATL _survivor;
        private _stable=_disarmed;
        for "_sample" from 1 to 10 do {
            sleep 1;
            if (primaryWeapon _survivor != "" || {!alive _survivor}
                || {!captive _survivor && {!(_survivor getVariable ["ace_captives_isSurrendering",false])}}
                || {_survivor distance2D _surrenderPosition > 3}) then {_stable=false};
        };
        ["SURRENDER-stays-disarmed-and-held",_stable,str [getPosATL _survivor,primaryWeapon _survivor,captive _survivor]] call _check;
        private _again=[_group] call Waldo_fnc_CortexSurrender;
        private _holdersAfter=nearestObjects [_survivor,["GroundWeaponHolder"],8];
        ["SURRENDER-repeat-no-duplicate-holder",_disarmed && {_again == 0} && {count _holdersAfter == count _holders}] call _check;
        _objects append _holdersAfter;
    } else {
        ["Retreat: physical withdrawal","The survivor must move at least 30 m away from the threat, retaining the rifle. A retreat flag or waypoint does not pass.",_origin] call _phase;
        private _withdrawn=[{call _sampleMorale; _survivor distance2D _origin >= 30 && {_survivor distance2D _enemy > (_origin distance2D _enemy)+25}},75] call _wait;
        ["MORALE-physical-retreat",_contact && {_withdrawn},str getPosATL _survivor] call _check;
        private _retreatHandover=[{
            (_group getVariable ["Waldo_Cortex_PhaseTransitions",[]]) findIf {
                (_x param [1,""]) == "RETREAT" && {(_x param [2,""]) == "REGROUP"}
                    && {(_x param [3,""]) == "WITHDRAWAL_COMPLETE"}
            } >= 0
        },90] call _wait;
        ["RETREAT-regroup-transition",_withdrawn && {_retreatHandover},
            str (_group getVariable ["Waldo_Cortex_PhaseTransitions",[]])] call _check;
        ["SURRENDER-disabled-keeps-weapon",primaryWeapon _survivor == _originalWeapon] call _check;
        ["RETREAT-real-smoke-projectile",(_survivor getVariable ["Waldo_CortexQA_SmokeThrows",[]]) isNotEqualTo [],str (_survivor getVariable ["Waldo_CortexQA_SmokeThrows",[]])] call _check;
    };
    [format ["MORALE-%1-broken-trigger",_surrender],_sawBroken,format ["lowest=%1 retreatObserved=%2",_lowestMorale,_sawRetreat]] call _check;
    diag_log format ["WMP CORTEX QA MORALE END: surrender=%1 eligible=%2 hold=%3 state=%4 peak=%5 unit=%6 waypoints=%7 nearbyFriends=%8 knowledge=%9 profile=%10 surrenderGate=%11",
        _surrender,[_group] call Waldo_fnc_CortexIsEligible,_group getVariable ["Waldo_AIPass_ZeusHold",[]],
        _group getVariable ["Waldo_AIPass_State",createHashMap],_group getVariable ["Waldo_AIPass_PeakSize",0],
        [currentCommand _survivor,expectedDestination _survivor,behaviour _survivor,_survivor checkAIFeature "PATH",primaryWeapon _survivor],
        (waypoints _group) apply {[_x,waypointPosition _x,waypointDescription _x]},
        (allGroups select {_x != _group && {side _x == side _group} && {leader _x distance2D _survivor < 300}}) apply {[_x,count units _x,getPosATL leader _x]},
        [_group] call Waldo_fnc_CortexKnowledge,[_group] call Waldo_fnc_CortexProfile,
        [_group,"Waldo_AIPass_Surrender_Enable",false] call Waldo_fnc_CortexFeatureEnabled];
    sleep 12;
    call _cleanup;
} forEach [false,true];

// Additive multi-squad withdrawal baseline. Shared timing is a stimulus, not a
// claim of coordinated overwatch; tactical alternation needs separate acceptance. Outside VR the
// same fixture is rotated onto one bounded, measured escape corridor so a flat northbound strip
// cannot masquerade as acceptance on hills or rough ground.
[_base] call Waldo_fnc_CortexTuning;
[createHashMapFromArray [["Waldo_AIPass_Morale_Enable",true],["Waldo_AIPass_Surrender_Enable",false],["Waldo_AIPass_Cohesion",0.25]]] call Waldo_fnc_CortexTuning;
private _withdrawTerrainOrigin=[1432.5,1100,0];
private _withdrawHeading=0;
private _withdrawTerrainReady=worldName == "VR";
private _withdrawRelief=0;
if (!_withdrawTerrainReady) then {
    private _bestScore=-1;
    private _gridStep=(worldSize/9) max 900;
    for "_gridX" from 2 to 7 do {
        for "_gridY" from 2 to 7 do {
            private _candidateOrigin=[_gridX*_gridStep,_gridY*_gridStep,0];
            for "_heading" from 0 to 315 step 45 do {
                private _forward=[sin _heading,cos _heading,0];
                private _right=[cos _heading,-sin _heading,0];
                private _safe=true;
                private _heights=[];
                {
                    private _lane=_x;
                    private _previous=[];
                    private _previousHeight=0;
                    for "_along" from -180 to 100 step 20 do {
                        private _sample=_candidateOrigin vectorAdd (_right vectorMultiply _lane)
                            vectorAdd (_forward vectorMultiply _along);
                        private _height=getTerrainHeightASL _sample;
                        private _normal=(surfaceNormal _sample) select 2;
                        if (surfaceIsWater _sample || {_normal < 0.55}) then {_safe=false};
                        if (_previous isNotEqualTo []) then {
                            private _grade=abs (_height-_previousHeight)/((_sample distance2D _previous) max 1);
                            if (_grade > 0.75) then {_safe=false};
                        };
                        _heights pushBack _height;
                        _previous=_sample;
                        _previousHeight=_height;
                    };
                } forEach [-45,0,45];
                private _relief=if (_heights isEqualTo []) then {0} else {(selectMax _heights)-(selectMin _heights)};
                private _score=_relief;
                if (_safe && {_relief >= 12} && {_relief <= 120} && {_score > _bestScore}) then {
                    _bestScore=_score;
                    _withdrawTerrainOrigin=_candidateOrigin;
                    _withdrawHeading=_heading;
                    _withdrawRelief=_relief;
                    _withdrawTerrainReady=true;
                };
            };
        };
    };
};
private _withdrawForward=[sin _withdrawHeading,cos _withdrawHeading,0];
private _withdrawRight=[cos _withdrawHeading,-sin _withdrawHeading,0];
private _withdrawPosition={
    params ["_local"];
    _withdrawTerrainOrigin vectorAdd (_withdrawRight vectorMultiply ((_local select 0)-1432.5))
        vectorAdd (_withdrawForward vectorMultiply ((_local select 1)-1100))
};
["MULTI-WITHDRAW-terrain-scenario",_withdrawTerrainReady,
    format ["world=%1 origin=%2 heading=%3 relief=%4",worldName,_withdrawTerrainOrigin,_withdrawHeading,_withdrawRelief]] call _check;
if (!_withdrawTerrainReady) then {
    ["Multi-squad withdrawal: no evaluative terrain","No dry three-lane corridor provided 12-120 m relief without unsafe slopes. Withdrawal results are skipped rather than falling back to a misleading flat layout.",_withdrawTerrainOrigin] call _phase;
} else {
private _withdrawTeams=[];
private _withdrawSurvivors=[];
private _withdrawEnemies=[];
for "_teamIndex" from 0 to 1 do {
    private _team=[east] call _newGroup;
    _team setCombatMode "BLUE";
    private _members=[];
    for "_i" from 0 to 5 do {
        private _unit=[_team,[[1400+_teamIndex*65+_i*2,1100,0]] call _withdrawPosition,format ["WITHDRAW SQUAD %1 / SOLDIER %2",_teamIndex+1,_i+1]] call _newUnit;
        _unit setSkill ["courage",0.1];
        _members pushBack _unit;
    };
    _withdrawTeams pushBack _members;
    private _survivors=_members select [4,2];
    {
        _x allowDamage false;
        _x addMagazine "SmokeShell";
        _x addEventHandler ["FiredMan",{
            params ["_unit","_weapon","_muzzle","_mode","_ammo","_magazine","_projectile"];
            if (!isNull _projectile && {getText (configFile >> "CfgAmmo" >> _ammo >> "simulation") in ["shotSmoke","shotSmokeX"]}) then {
                _unit setVariable ["Waldo_CortexQA_MultiSmoke",true,true];
            };
        }];
    } forEach _survivors;
    _withdrawSurvivors append _survivors;
    private _enemyGroup=[west] call _newGroup;
    _enemyGroup setVariable ["Waldo_AIPass_Exclude",true,true];
    _enemyGroup setCombatMode "BLUE";
    private _enemy=[_enemyGroup,[[1400+_teamIndex*65,1180,0]] call _withdrawPosition,format ["SQUAD %1 THREAT",_teamIndex+1]] call _newUnit;
    _enemy disableAI "PATH"; _enemy allowDamage false;
    _withdrawEnemies pushBack _enemy;
};
missionNamespace setVariable ["Waldo_CortexQA_Actors",+_objects,true];
["Two squads: casualty-driven withdrawal","Both squads must naturally detect contact across the measured corridor. Four casualties in each leave two survivors. Watch each survivor follow a dry escape avenue, gain ground away from the threat, retain its squad lane and use real smoke. Low cohesion is a declared stimulus; no retreat state is assigned.",[[1435,1100,0]] call _withdrawPosition] call _phase;
private _bothContact=[{_withdrawTeams findIf {((group (_x select 0) getVariable ["Waldo_AIPass_State",createHashMap]) getOrDefault ["phase",""]) != "CONTACT"} < 0},40] call _wait;
["MULTI-WITHDRAW-natural-contact",_bothContact] call _check;
private _withdrawOrigins=_withdrawSurvivors apply {getPosATL _x};
private _originalGroups=_withdrawSurvivors apply {group _x};
{{_x setDamage 1} forEach (_x select [0,4])} forEach _withdrawTeams;
private _allWithdrew=[{
    private _okay=true;
    {
        private _origin=_withdrawOrigins select _forEachIndex;
        private _enemy=_withdrawEnemies select floor (_forEachIndex/2);
        private _travel=_x distance2D _origin;
        private _gain=(_x distance2D _enemy)-(_origin distance2D _enemy);
        private _escapeProgress=((getPosATL _x) vectorDiff _origin) vectorDotProduct (_withdrawForward vectorMultiply -1);
        _x setVariable ["Waldo_CortexQA_Label",format ["SQUAD %1 SURVIVOR | travel %2 m | escape %3 m | threat separation +%4 m",1+floor (_forEachIndex/2),round _travel,round _escapeProgress,round _gain],true];
        if (!alive _x || {_travel < 30} || {_escapeProgress < 20} || {_gain < 25}) then {_okay=false};
    } forEach _withdrawSurvivors;
    _okay
},100] call _wait;
["MULTI-WITHDRAW-every-survivor-travel",_bothContact && {_allWithdrew},str (_withdrawSurvivors apply {getPosATL _x})] call _check;
private _membership=true;
{if (group _x != (_originalGroups select _forEachIndex) || {primaryWeapon _x == ""}) then {_membership=false}} forEach _withdrawSurvivors;
["MULTI-WITHDRAW-membership-and-rifles",_membership] call _check;
private _laneCentres=[];
{
    private _survivors=_x select [4,2];
    private _centroid=((getPosATL (_survivors select 0)) vectorAdd (getPosATL (_survivors select 1))) vectorMultiply 0.5;
    _laneCentres pushBack ((_centroid vectorDiff _withdrawTerrainOrigin) vectorDotProduct _withdrawRight);
} forEach _withdrawTeams;
["MULTI-WITHDRAW-distinct-terrain-lanes",_allWithdrew && {abs ((_laneCentres select 1)-(_laneCentres select 0)) >= 35},str _laneCentres] call _check;
{
    private _survivors=_x select [4,2];
    [format ["MULTI-WITHDRAW-squad-%1-smoke",_forEachIndex+1],_survivors findIf {_x getVariable ["Waldo_CortexQA_MultiSmoke",false]} >= 0] call _check;
    [format ["MULTI-WITHDRAW-squad-%1-cohesion",_forEachIndex+1],_allWithdrew && {(_survivors select 0) distance2D (_survivors select 1) <= 30},str ((_survivors select 0) distance2D (_survivors select 1))] call _check;
} forEach _withdrawTeams;
sleep 12;
call _cleanup;
};

// Civilian reactions are event driven in normal play. This focused stage calls the same production
// endpoint used by FiredNear/Hit so its stimulus is deterministic, then measures physical movement.
private _civilianGroup=[civilian] call _newGroup;
private _civilian=_civilianGroup createUnit ["C_man_1",[1600,1100,0],[],0,"NONE"];
_civilian setVariable ["acex_headless_blacklist",true,true];
_civilian setVariable ["Waldo_CortexQA_Label","CIVILIAN / DISABLED",true];
_civilian allowDamage false;
_objects pushBack _civilian;
private _civilianThreatGroup=[west] call _newGroup;
_civilianThreatGroup setVariable ["Waldo_AIPass_Exclude",true,true];
private _civilianThreat=[_civilianThreatGroup,[1600,1120,0],"CIVILIAN THREAT"] call _newUnit;
_civilianThreat disableAI "PATH";
_civilianThreat allowDamage false;
missionNamespace setVariable ["Waldo_CortexQA_Actors",[_civilian,_civilianThreat],true];
private _civilianOrigin=getPosATL _civilian;
[createHashMapFromArray [["Waldo_AIPass_CivilianReaction_Enable",false]]] call Waldo_fnc_CortexTuning;
[_civilian,true] call Waldo_fnc_CortexCivilianSetup;
["Civilian reaction disabled","An unarmed civilian stands near a threat. The production reaction endpoint must refuse the request and the civilian must remain in place while the feature is disabled.",_civilianOrigin] call _phase;
private _disabledIssued=[_civilian,_civilianThreat] call Waldo_fnc_CortexCivilianReact;
sleep 8;
["CIVILIAN-disabled-no-response",!_disabledIssued && {_civilian distance2D _civilianOrigin < 3},format ["issued=%1 travel=%2",_disabledIssued,_civilian distance2D _civilianOrigin]] call _check;

[createHashMapFromArray [
    ["Waldo_AIPass_CivilianReaction_Enable",true],
    ["Waldo_AIPass_CivilianReaction_Radius",45],
    ["Waldo_AIPass_CivilianReaction_Distance",180],
    ["Waldo_AIPass_CivilianReaction_Cooldown",20]
]] call Waldo_fnc_CortexTuning;
[_civilian] call Waldo_fnc_CortexCivilianSetup;
_civilian setVariable ["Waldo_CortexQA_Label","CIVILIAN / FLEE",true];
["Civilian reaction enabled","The same civilian receives the production danger response. Watch real movement away from the nearby threat. No FSM, animation or test waypoint is injected.",_civilianOrigin] call _phase;
private _enabledIssued=[_civilian,_civilianThreat] call Waldo_fnc_CortexCivilianReact;
private _fled=[{_civilian distance2D _civilianOrigin >= 25 && {_civilian distance2D _civilianThreat > (_civilianOrigin distance2D _civilianThreat)+20}},35] call _wait;
["CIVILIAN-enabled-physical-flee",_enabledIssued && {_fled},format ["issued=%1 travel=%2 separation=%3",_enabledIssued,_civilian distance2D _civilianOrigin,_civilian distance2D _civilianThreat]] call _check;
private _cooldownRefused=!([_civilian,_civilianThreat] call Waldo_fnc_CortexCivilianReact);
["CIVILIAN-cooldown-no-duplicate",_cooldownRefused] call _check;

// A later Zeus order must own the actor immediately and complete physically without the old flee
// destination returning after the hold expires.
[_civilianGroup,true] call Waldo_fnc_CortexZeusMark;
private _replacement=(getPosATL _civilian) vectorAdd [0,55,0];
_civilian doMove _replacement;
_civilian setVariable ["Waldo_CortexQA_Label","CIVILIAN / ZEUS REPLACEMENT",true];
["Civilian reaction: Zeus replacement","A later Zeus movement order now owns the civilian. Watch physical arrival at the green replacement destination and no renewed Cortex flee order.",_replacement] call _phase;
private _replacementArrived=[{_civilian distance2D _replacement < 5},35] call _wait;
private _blockedDuringZeus=!([_civilian,_civilianThreat] call Waldo_fnc_CortexCivilianReact);
["CIVILIAN-zeus-replacement-physical",_replacementArrived && {_blockedDuringZeus},format ["remaining=%1 blocked=%2",_civilian distance2D _replacement,_blockedDuringZeus]] call _check;
call _cleanup;
