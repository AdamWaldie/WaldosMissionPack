/*
 * Author: WaldoTheWarfighter
 * Reports whether the WMP AI profile is active and whether ordinary AI groups currently owned by
 * headless clients have acknowledged profile adoption. Also reports the Cortex scheduler and
 * survivor-regroup counters, per-feature gates/tuning, coordinated support outcomes,
 * active drill heartbeats, durable transition/remount/support/combined-arms ownership, pending artillery
 * relocation, bounded action/order snapshots and queue health
 * for the server (headless-client private counters stay on those machines). This is independent of which scheduler moved
 * the groups: ACE Headless may be active while WMP's optional HC distributor is disabled.
 *
 * Locality and authority:
 * Read-only and server-only. It compares engine HeadlessClient_F owners with current groupOwner and
 * authenticated adoption records. No state is changed or broadcast; repeat/JIP behaviour is not
 * applicable. The shared diagnostics runner publishes the resulting report normally.
 *
 * Arguments: None. On-demand snapshots cap groups/controllers at 20 and members at 8.
 * Return Value: HashMap - Waldo_fnc_DiagnosticFeatureReport shape for area "ai".
 *
 * Example:
 * [] call Waldo_fnc_AIGetDiagnostics;
 * Result: reports active profile/mode and any HC-owned groups lacking verified adoption.
 *
 * Current caller: Waldo_fnc_RunDiagnostics.
 */

if !(isServer) exitWith {["ai", []] call Waldo_fnc_DiagnosticFeatureReport};
private _groups = allGroups;
private _enabled = missionNamespace getVariable ["Waldo_AIRebalance_Enable", true];
private _hcOwners = (entities "HeadlessClient_F") apply {owner _x};
private _hcGroups = _groups select {
    groupOwner _x in _hcOwners
    && {(units _x) findIf {isPlayer _x} < 0}
    && {!(_x getVariable ["Waldo_ServerOwnedFeature", false])}
};
private _includedSides = missionNamespace getVariable ["Waldo_AI_IncludedSides", []];
private _includedSideKeys = (_includedSides select {_x isEqualType ""}) apply {toUpperANSI _x};
private _includedFactions = missionNamespace getVariable ["Waldo_AI_IncludedFactions", []];
private _excludedFactions = missionNamespace getVariable ["Waldo_AI_ExcludedFactions", []];
private _excludedClasses = missionNamespace getVariable ["Waldo_AI_ExcludedClasses", []];
private _eligibleAI = {
    params ["_unit"];
    private _sideKey = switch (side group _unit) do {
        case west: {"WEST"}; case east: {"EAST"}; case independent: {"GUER"}; default {"CIV"};
    };
    !isPlayer _unit
    && {!(_unit getVariable ["Waldo_ServerOwnedFeature", false])}
    && {!(_unit getVariable ["Waldo_AI_Exclude", false])}
    && {count _includedSides == 0 || {_sideKey in _includedSideKeys}}
    && {count _includedFactions == 0 || {faction _unit in _includedFactions}}
    && {!(faction _unit in _excludedFactions)}
    && {!(typeOf _unit in _excludedClasses)}
};
private _missing = _hcGroups select {
    private _owner = groupOwner _x;
    private _aceResult = _x getVariable ["Waldo_AI_LastHeadlessAdoption", []];
    private _wmpResult = _x getVariable ["Waldo_Headless_LastAdoption", []];
    private _eligibleCount = {_x call _eligibleAI} count units _x;
    private _aceValid = count _aceResult >= 2
        && {(_aceResult select 0) == _owner}
        && {(_aceResult select 1) >= _eligibleCount};
    private _wmpValid = count _wmpResult >= 4
        && {(_wmpResult select 1) == _owner}
        && {_wmpResult select 2}
        && {(!_enabled) || {(_wmpResult select 3) >= _eligibleCount}};
    !(_aceValid || {_wmpValid})
};
private _helicopters = (allMissionObjects "Helicopter") select {alive _x};
private _activeLanding = _helicopters select {_x getVariable ["Waldo_ImprovedHelicopterLanding_Active", false]};
private _orphanedMovementControl = _helicopters select {
    (_x getVariable ["Waldo_ImprovedHelicopterLanding_GroundAnchored", false])
    || {_x getVariable ["Waldo_ImprovedHelicopterLanding_Active", false]}
};
private _staleLanding = _helicopters select {
    _x getVariable ["Waldo_ImprovedHelicopterLanding_GroundAnchored", false]
    && {!(_x getVariable ["Waldo_ImprovedHelicopterLanding_Active", false])}
};
private _groupedLanding = _activeLanding select {
    private _aircraft = _x;
    private _pilot = currentPilot _aircraft;
    if (isNull _pilot) exitWith {false};
    private _aircraftInGroup = [];
    {
        private _vehicle = vehicle _x;
        if (_vehicle isKindOf "Helicopter") then {_aircraftInGroup pushBackUnique _vehicle};
    } forEach (units (group _pilot));
    count _aircraftInGroup > 1
};
private _decelerationEnabled = missionNamespace getVariable ["Waldo_HelicopterDeceleration_Enable", false];
private _decelerationAircraft = vehicles select {
    _x getVariable ["Waldo_HelicopterDeceleration_LocalHandlerInstalled", false]
};
private _decelerationActive = _decelerationAircraft select {
    _x getVariable ["Waldo_HelicopterDeceleration_Active", false]
};
private _decelerationLandingConflict = _decelerationActive select {
    _x getVariable ["Waldo_ImprovedHelicopterLanding_Active", false]
};
private _passEnabled = missionNamespace getVariable ["Waldo_AIPass_Enable", true];
private _passActive = missionNamespace getVariable ["Waldo_AIPass_Active", false];
private _passJobs = count (missionNamespace getVariable ["Waldo_AIPass_Jobs", []]) + count (missionNamespace getVariable ["Waldo_AIPass_PendingJobs", []]);
private _externalActors=(allUnits select {alive _x}) apply {[_x,[_x] call Waldo_fnc_CortexExternalOwner]};
_externalActors=_externalActors select {(_x select 1) != ""};
private _vcomMovementLeases={_x getVariable ["Waldo_Cortex_VcomLease",[]] isNotEqualTo []} count _groups;
private _civilianActors=allUnits select {alive _x && {side group _x == civilian}
    && {primaryWeapon _x == ""} && {secondaryWeapon _x == ""} && {handgunWeapon _x == ""}};
private _civilianReactions={serverTime < (_x getVariable ["Waldo_Cortex_CivilianReactionUntil",0])} count _civilianActors;
private _passState = if (!_passEnabled) then {"DISABLED"} else {if (_passActive && {!isNil {missionNamespace getVariable "Waldo_AIPass_SchedulerHandle"}}) then {"ACTIVE"} else {"ERROR"}};
private _passHint = if (_passState == "ERROR") then {"Waldo_AIPass_Enable is true but the server scheduler is not running; check RPT for [WMP CORTEX] and that CBA is loaded."} else {""};
private _regroupEnabled = missionNamespace getVariable ["Waldo_AIPass_Regroup_Enable", true];
private _lambsDanger = isClass (configFile >> "CfgPatches" >> "lambs_danger");
private _lambsWaypoints = isClass (configFile >> "CfgPatches" >> "lambs_wp");
private _lambsTurrets = isClass (configFile >> "CfgPatches" >> "lambs_turrets");
private _lambsSuppression = isClass (configFile >> "CfgPatches" >> "lambs_suppression");
private _lambsRpg = isClass (configFile >> "CfgPatches" >> "lambs_rpg");
private _lambsMovementLeases = {_x getVariable ["Waldo_Cortex_LambsLease", []] isNotEqualTo []} count _groups;
private _lambsBusyGroups = {
    private _currentTactic = _x getVariable ["lambs_main_currentTactic", ""];
    (_x getVariable ["lambs_danger_isExecutingTactic", false])
        || {(_currentTactic isEqualType "") && {(toLowerANSI _currentTactic) find "task" == 0}}
        || {(units _x) findIf {_x getVariable ["lambs_danger_forceMove", false]} >= 0}
} count _groups;
private _operatingCrew=allUnits select {
    !isPlayer _x && {vehicle _x != _x}
        && {toUpperANSI ((assignedVehicleRole _x) param [0,""]) != "CARGO"}
};
private _dynamicAACrew=_operatingCrew select {
    (vehicle _x getVariable ["Waldo_DynamicAA_SystemId",""]) != ""
};
private _crewAimAdjusted={
    !isNil {_x getVariable "Waldo_AI_OriginalAimCoef"}
        && {abs (getCustomAimCoef _x - (_x getVariable ["Waldo_AI_OriginalAimCoef",getCustomAimCoef _x])) > 0.01}
} count _operatingCrew;
private _activeAirAttacks=vehicles select {(_x getVariable ["Waldo_Cortex_AirAttackPlan",[]]) isNotEqualTo []};
private _hbqLoaded=isClass (configFile >> "CfgPatches" >> "hbq_advanced_driving_ai");
private _convoyRegistry=missionNamespace getVariable ["Waldo_Convoy_Registry",[]];
private _convoyGroups=_convoyRegistry apply {_x select 0};
private _convoyVehicles=[];
{_convoyVehicles append (((_x select 1) param [4,[]]) select {!isNull _x})} forEach _convoyRegistry;
private _convoyRecoveries=0;
{_convoyRecoveries=_convoyRecoveries+(_x getVariable ["Waldo_Convoy_RouteRecoveries",0])} forEach _convoyGroups;
private _protocolNavy=isClass (configFile >> "CfgPatches" >> "PROTOCOL_AI_NAVY_SEAL");
private _navalGroups=_groups select {(_x getVariable ["Waldo_Cortex_NavalStatus",[]]) isNotEqualTo []};
private _checks = [
    ["ai", "cortex", _passState, [format ["enabled=%1 serverActive=%2 serverJobs=%3 paused=%4 includedSides=%5", _passEnabled, _passActive, _passJobs, [] call Waldo_fnc_CortexIsPaused, missionNamespace getVariable ["Waldo_AIPass_IncludedSides", []]], _passHint] call Waldo_fnc_DiagnosticFoldHint],
    ["ai", "cortex-regroup", if (_passEnabled && {_regroupEnabled}) then {"LOADED"} else {"DISABLED"}, format ["enabled=%1 serverRegroupsCompleted=%2 serverUnitsJoined=%3", _regroupEnabled, missionNamespace getVariable ["Waldo_AIPass_RegroupsCompleted", 0], missionNamespace getVariable ["Waldo_AIPass_RegroupJoined", 0]]],
    ["ai", "cortex-groups", if (!_passEnabled) then {"DISABLED"} else {"LOADED"}, format ["serverManaged=%1 inContact=%2 retreating=%3 garrisons=%4 flanksCompleted=%5 retreats=%6 surrenders=%7 reinforcementsSent=%8 grenadeReactions=%9",
        {local _x && {_x getVariable ["Waldo_AIPass_Managed", false]}} count _groups,
        {local _x && {((_x getVariable ["Waldo_AIPass_State", createHashMap]) getOrDefault ["phase", ""]) == "CONTACT"}} count _groups,
        {local _x && {((_x getVariable ["Waldo_AIPass_State", createHashMap]) getOrDefault ["phase", ""]) == "RETREAT"}} count _groups,
        {(_x getVariable ["Waldo_AIPass_Garrison", []]) isNotEqualTo []} count _groups,
        missionNamespace getVariable ["Waldo_AIPass_FlanksCompleted", 0], missionNamespace getVariable ["Waldo_AIPass_Retreats", 0],
        missionNamespace getVariable ["Waldo_AIPass_Surrenders", 0], missionNamespace getVariable ["Waldo_AIPass_ReinforcementsSent", 0],
        missionNamespace getVariable ["Waldo_AIPass_GrenadeReactions", 0]]],
    ["ai", "cortex-drills", if (!_passEnabled) then {"DISABLED"} else {"LOADED"}, format ["assaults=%1 advances=%2 investigations=%3 coordinatedAssaults=%4 magazinesShared=%5 defences=%6",
        missionNamespace getVariable ["Waldo_AIPass_Assaults", 0], missionNamespace getVariable ["Waldo_AIPass_AdvancesCompleted", 0],
        missionNamespace getVariable ["Waldo_AIPass_Investigations", 0], missionNamespace getVariable ["Waldo_AIPass_CoordinatedAssaults", 0],
        missionNamespace getVariable ["Waldo_AIPass_MagazinesShared", 0],
        {(_x getVariable ["Waldo_AIPass_Defend", []]) isNotEqualTo []} count _groups]],
    ["ai", "cortex-zeus", if (!_passEnabled) then {"DISABLED"} else {"LOADED"}, format ["heldByZeus=%1 zeusWaypointGroups=%2 excluded=%3 holdSeconds=%4",
        {local _x && {time < (_x getVariable ["Waldo_AIPass_ZeusLocalUntil",-1]) || {_x getVariable ["Waldo_AIPass_ZeusWaypoints",false]}}} count _groups,
        {_x getVariable ["Waldo_AIPass_ZeusWaypoints", false]} count _groups,
        {_x getVariable ["Waldo_AIPass_Exclude", false]} count _groups,
        missionNamespace getVariable ["Waldo_AIPass_ZeusHoldSeconds", 120]]],
    ["ai", "cortex-support", if (!_passEnabled) then {"DISABLED"} else {"LOADED"}, format ["artillery=%1 counterBattery=%2 serverBatteries=%3 missions=%4 radars=%5 airborne=%6 drops=%7 reactiveFlares=%8 attackRunFlares=%9 adaptiveAirAttacks=%10 activeAirAttacks=%11",
        missionNamespace getVariable ["Waldo_AIPass_Artillery_Enable", false], missionNamespace getVariable ["Waldo_AIPass_CounterBattery_Enable", false],
        count (missionNamespace getVariable ["Waldo_AIPass_LocalArtillery", []]), missionNamespace getVariable ["Waldo_AIPass_ArtilleryMissions", 0],
        count (missionNamespace getVariable ["Waldo_AIPass_CounterBatteryRadars", []]), missionNamespace getVariable ["Waldo_AIPass_Airborne_Enable", false],
        missionNamespace getVariable ["Waldo_AIPass_AirborneDrops", 0],
        missionNamespace getVariable ["Waldo_AIPass_AircraftFlares_Enable", true],
        missionNamespace getVariable ["Waldo_Cortex_AttackRunFlares_Enable", true],
        missionNamespace getVariable ["Waldo_Cortex_AirAttack_Enable", true],count _activeAirAttacks]],
    ["ai", "cortex-tuning", if (!_passEnabled) then {"DISABLED"} else {"LOADED"}, format ["profile=%1 aggression=%2 cohesion=%3 reaction=%4 artilleryRole=%5 counterBatteryMode=%6",
        [missionNamespace getVariable ["Waldo_AIPass_BehaviourProfile", ""], "FOLLOW"] select ((missionNamespace getVariable ["Waldo_AIPass_BehaviourProfile", ""]) == ""),
        missionNamespace getVariable ["Waldo_AIPass_Aggression", 1.2], missionNamespace getVariable ["Waldo_AIPass_Cohesion", 1],
        missionNamespace getVariable ["Waldo_AIPass_ReactionSpeed", 1], missionNamespace getVariable ["Waldo_AIPass_Artillery_DefaultRole", "BOTH"],
        missionNamespace getVariable ["Waldo_AIPass_CounterBattery_Mode", "AUTO"]]],
    ["ai", "cortex-lambs", if (_lambsDanger || {_lambsWaypoints} || {_lambsTurrets} || {_lambsSuppression} || {_lambsRpg}) then {"ACTIVE"} else {"UNAVAILABLE"}, format ["danger=%1 waypoints=%2 turrets=%3 suppression=%4 rpg=%5 mode=%6 scopedMovementLeases=%7 lambsOwnedGroups=%8 busyLeaseRefusals=%9; config companions remain active in every mode", _lambsDanger, _lambsWaypoints, _lambsTurrets, _lambsSuppression, _lambsRpg, missionNamespace getVariable ["Waldo_AIPass_LambsMode", "SPLIT"], _lambsMovementLeases, _lambsBusyGroups, missionNamespace getVariable ["Waldo_Cortex_LambsBusyRefusals", 0]]],
    ["ai","cortex-compatibility","LOADED",format ["vcomLoaded=%1 finiteVcomLeases=%2 imsLoaded=%3 webKnightLoaded=%4 simpleCivilianLoaded=%5 externallyOwnedActors=%6 reasons=%7. VCOM/LAMBS movement is leased only for finite Cortex work; WBK/active IMS actors are excluded without changing addon state.",missionNamespace getVariable ["Waldo_AIPass_VcomLoaded",false],_vcomMovementLeases,missionNamespace getVariable ["Waldo_AIPass_IMSLoaded",false],missionNamespace getVariable ["Waldo_AIPass_WBKLoaded",false],missionNamespace getVariable ["Waldo_AIPass_WBKCivilianLoaded",false],count _externalActors,_externalActors apply {_x select 1}]],
    ["ai","convoy-driving",if (_convoyRegistry isEqualTo []) then {"LOADED"} else {"ACTIVE"},format ["controlledGroups=%1 vehicles=%2 drivingAssist=%3 routeRecoveryEnabled=%4 recoveries=%5 hbqLoaded=%6 hbqPausedVehicles=%7. Road look-ahead is one bounded sample per convoy; WMP re-selects only an unchanged final route and never teleports, repairs or ignores a physical roadblock.",count _convoyGroups,count _convoyVehicles,missionNamespace getVariable ["Waldo_Convoy_DrivingAssist_Enable",true],missionNamespace getVariable ["Waldo_Convoy_RouteRecovery_Enable",true],_convoyRecoveries,_hbqLoaded,{_x getVariable ["HBQAD_Pause",false]} count _convoyVehicles]],
    ["ai","cortex-naval",if !(missionNamespace getVariable ["Waldo_AIPass_NavalAssault_Enable",true]) then {"DISABLED"} else {if (_protocolNavy) then {"EXTERNAL"} else {if (_navalGroups isEqualTo []) then {"LOADED"} else {"ACTIVE"}}},format ["enabled=%1 protocolNavyLoaded=%2 activeGroups=%3 statuses=%4. WMP uses the existing Cortex group scheduler, a bounded shore comparison and one finite native approach; PROTOCOL has exclusive ownership when loaded.",missionNamespace getVariable ["Waldo_AIPass_NavalAssault_Enable",true],_protocolNavy,count _navalGroups,_navalGroups apply {_x getVariable ["Waldo_Cortex_NavalStatus",[]]}]],
    ["ai","cortex-civilian-reactions",if !(missionNamespace getVariable ["Waldo_AIPass_CivilianReaction_Enable",true]) then {"DISABLED"} else {if (missionNamespace getVariable ["Waldo_AIPass_WBKCivilianLoaded",false]) then {"EXTERNAL"} else {"LOADED"}},format ["eligibleUnarmedCivilians=%1 reactingNow=%2 radius=%3 distance=%4 cooldown=%5. FiredNear/Hit handlers are event-driven; Simple Civilian Behaviour has exclusive ownership when present.",count _civilianActors,_civilianReactions,missionNamespace getVariable ["Waldo_AIPass_CivilianReaction_Radius",45],missionNamespace getVariable ["Waldo_AIPass_CivilianReaction_Distance",180],missionNamespace getVariable ["Waldo_AIPass_CivilianReaction_Cooldown",20]]],
    ["ai", "ai-profile", if (_enabled) then {"ACTIVE"} else {"DISABLED"}, format ["profile=%1 mode=%2 serverActive=%3", missionNamespace getVariable ["Waldo_AIRebalance_Profile", "LINE"], missionNamespace getVariable ["Waldo_AIRebalance_Mode", "AUTO"], missionNamespace getVariable ["Waldo_AI_RebalanceActive", false]]],
    ["ai", "ai-weapon-dispersion", if (!_enabled) then {"DISABLED"} else {"ACTIVE"}, format ["operatingCrew=%1 dynamicAAExempt=%2 infantry=%3 crewSkillMultiplier=%4 groundVehicle=%5 aircraft=%6 locallyAdjusted=%7 lambsTurrets=%8 scriptVehicleLayer=%9. Dynamic AA retains authored effectiveness; LAMBS Turrets prevents WMP's extra vehicle coefficient from stacking.",count _operatingCrew,count _dynamicAACrew,missionNamespace getVariable ["Waldo_AI_InfantryDispersion",1.35],missionNamespace getVariable ["Waldo_AI_VehicleCrewAimMultiplier",0.6],missionNamespace getVariable ["Waldo_AI_VehicleCrewDispersion",3.5],missionNamespace getVariable ["Waldo_AI_AirCrewDispersion",4.25],_crewAimAdjusted,_lambsTurrets,!_lambsTurrets]],
    ["ai", "ai-headless-adoption", if (!_enabled) then {"DISABLED"} else {if (count _missing > 0) then {"ERROR"} else {if (count _hcGroups > 0) then {"ACTIVE"} else {"UNCONFIGURED"}}}, format ["connectedHCs=%1 hcOwnedGroups=%2 missingVerifiedAdoption=%3", count _hcOwners, count _hcGroups, count _missing]],
    ["ai", "improved-helicopter-landing", if !(missionNamespace getVariable ["Waldo_ImprovedHelicopterLanding_Enable", true]) then {"DISABLED"} else {if (count _staleLanding > 0 || {count _groupedLanding > 0}) then {"ERROR"} else {if (count _activeLanding > 0) then {"ACTIVE"} else {"LOADED"}}}, format ["helicopters=%1 movementOwned=%2 activeControllers=%3 staleGroundAnchors=%4 groupedControllers=%5", count _helicopters, count _orphanedMovementControl, count _activeLanding, count _staleLanding, count _groupedLanding]],
    ["ai", "helicopter-deceleration", if (!_decelerationEnabled) then {"DISABLED"} else {if (count _decelerationLandingConflict > 0) then {"ERROR"} else {"ACTIVE"}}, format ["enabled=%1 tracked=%2 activelyCorrecting=%3 landingConflicts=%4 includeVTOL=%5", _decelerationEnabled, count _decelerationAircraft, count _decelerationActive, count _decelerationLandingConflict, missionNamespace getVariable ["Waldo_HelicopterDeceleration_IncludeVTOL", false]]]
];
// Shared tuning metadata supplies current values and defaults; feature notes explain execution prerequisites.
// Build diagnostics from the same canonical key set used by Cortex Control. This keeps a stale
// mission extension from showing the same setting, gate and trigger explanation more than once.
private _tuningSpec=[];
private _seenTuningKeys=createHashMap;
{
    private _key=_x param [0,"",[""]];
    if (_key != "" && {!(_seenTuningKeys getOrDefault [_key,false])}) then {
        _seenTuningKeys set [_key,true];
        _tuningSpec pushBack _x;
    };
} forEach ([] call Waldo_fnc_CortexTuningSpec);
private _featureNotes=createHashMapFromArray [
    ["Regroup","Requires casualty survivors and a compatible nearby host; inspect living leader, travel before merge, and replacement-order ownership."],
    ["Contact","Uses natural engine knowledge. Check last-seen age and group phase; known enemies are not necessarily visible."],
    ["PostContact","Requires lost contact; inspect phase age, search members and return to the authored route."],
    ["Flank","Requires eligible contact and a viable movement element. Inspect drill stage/bound, covering roles and actual commands; elapsed time alone is not a stall."],
    ["StreetCrossing","Requires a manoeuvre crossing an engine road; inspect approach/crossing stages, smoke inventory and far-side travel."],
    ["FireControl","Requires known threats and permitted ROE. Ordered suppression alternates within a squad and uses a short random delay per squad; assigned targets are not shots. Check BLUE mode, ammunition and friendly obstruction."],
    ["Morale","Uses casualties, pressure and leader state; inspect morale value/state and physical retreat, not only RETREAT phase."],
    ["Surrender","Requires broken isolated survivors and surrender enabled; check captive state and real weapon removal. ACE captivity is optional."],
    ["GrenadeEvasion","Requires a qualifying live projectile and eligible observer. Check projectile handler, movement ownership and evasion release."],
    ["AntiArmour","Requires a known armoured threat, capable launcher/ammunition and clear backblast; targeting alone does not prove firing."],
    ["Vehicles","Inspect crew versus passengers, vehicle mobility and contact. Separate cargo squads retain their own order authority."],
    ["ContactReports","Requires a deliverable report; jamming/voice range and freshness can prevent delivery. A radio inventory item is not required."],
    ["Reinforce","Requires an eligible idle helper and a report/request; inspect reservation, responding state and physical approach."],
    ["Artillery","Requires an explicitly assigned spotter and eligible same-side battery with range/ammunition. Inspect fire mission phase, warning and confirmed shots."],
    ["CounterBattery","Requires an enemy artillery emission and eligible counter-role battery. Radar shortens delay but is not required; inspect pending/uncertain missions and friendly clearance."],
    ["Airborne","Requires eligible passengers in a suitable flying aircraft; inspect altitude, chute configuration, operating crew and post-landing orders."],
    ["AttackRunFlares","Assigned hostile target, airborne speed at least 40 km/h, closing within 1500 m then opening past closest approach. Two requests per leg; inspect actual countermeasure fire and finite ammunition. Phase is intent, not proof of release."],
    ["AirAttack","Requires a moving airborne AI aircraft, hostile assigned target and attack ROE. Inspect pattern/stage, observed AA, physical ingress/egress, real weapon fire, clearance, outcome and Zeus handover."],
    ["AircraftFlares","Applies to eligible AI aircraft under missile threat; inspect countermeasure ammunition and actual Fired events."],
    ["Investigate","Requires a known uncertain area; inspect area source, search team and actual travel without revealing hidden targets."],
    ["Assault","Requires a viable approach transition; inspect assault/frag/clear/consolidate stages. Live frag clearance must precede movement."],
    ["Advance","Requires a contact manoeuvre and viable fire teams; inspect team roles, successive bounds, stragglers and physical forward progress."],
    ["CoordinatedAssault","Requires supporting squads and a valid lease; inspect role sequence, rally areas, readiness and moving/covering elements."],
    ["Stance","Only eligible stationary actors should take cover stances; inspect applied stance and firing clearance. Movers must retain movement."],
    ["AmmoShare","Requires compatible spare magazines, a needy recipient and range; compare real inventories and conserved rounds, not a transfer counter."],
    ["VehicleGunnery","Requires an armed crew and permitted ROE; inspect actual target priority, ammunition and AT separation."],
    ["ArtillerySmoke","Requires artillery support and a valid retreat requester; smoke missions must not receive lethal red warning smoke."],
    ["AircraftBreak","Applies to eligible AI aircraft; inspect missile response, ground clearance and return to route."],
    ["VehicleDismount","Requires vehicle drills and a safely stopped vehicle on dry ground; unload passengers, retain operating crew."],
    ["VehicleRemount","Requires owned dismount intent and safe reboarding; a new Zeus order must cancel old remount intent."],
    ["VehicleWithdraw","Requires a damaged mobile vehicle and vehicle drills; inspect actual increased separation, existing smoke and retained crew."],
    ["CoverValidation","Checks candidate slope and body clearance; a valid cover candidate is not physical arrival or a usable firing position."],
    ["Hearing","Requires an installed local hearing handler and a real nearby shot; records an uncertain area, not target revelation."],
    ["MountedFire","Convoy weapon crew engage within existing ROE; cargo and crew roles must remain distinct."],
    ["Cover","Convoy passengers move clear after dismount; inspect threat-relative positions and newer squad orders."],
    ["AvoidInfantry","Requires a convoy and a friendly pedestrian in its driving corridor; inspect yielding, clearance and resumed travel."],
    ["ContactHalt","Requires convoy contact/pinning; inspect halt reason. Player roadblocks must remain effective; no teleport recovery."],
    ["Unload","Requires a convoy halt/arrival with cargo; inspect actual passenger exits and operating crew retention."]
];
private _dependencies=createHashMapFromArray [
    ["AttackRunFlares",["Waldo_AIPass_Enable"]],
    ["Surrender",["Waldo_AIPass_Morale_Enable"]],
    ["ArtillerySmoke",["Waldo_AIPass_Artillery_Enable"]],
    ["VehicleDismount",["Waldo_AIPass_Vehicles_Enable"]],
    ["VehicleRemount",["Waldo_AIPass_Vehicles_Enable"]],
    ["VehicleWithdraw",["Waldo_AIPass_Vehicles_Enable"]]
];
{
    _x params ["_key","_label","","_kind","","_default"];
    if (_kind == "CHECKBOX") then {
        private _value=missionNamespace getVariable [_key,_default];
        private _parts=_key splitString "_";
        private _name=_parts param [2,""];
        private _parents=+(_dependencies getOrDefault [_name,[]]);
        if (_key find "Waldo_AIPass_" == 0 && {_key != "Waldo_AIPass_Enable"} && {_name != "CoverValidation"}) then {_parents pushBackUnique "Waldo_AIPass_Enable"};
        private _parentValues=_parents apply {[_x,missionNamespace getVariable [_x,false]]};
        private _blockedParents=_parentValues select {!(_x select 1)};
        private _prefix=(_parts select [0,3]) joinString "_";
        private _related=(_tuningSpec select {(_x select 0) find (_prefix+"_") == 0 && {(_x select 3) != "CHECKBOX"}}) apply {[_x select 1,missionNamespace getVariable [_x select 0,_x select 5],_x select 5]};
        private _scope=if (_key find "Waldo_Convoy_" == 0) then {"Convoy owner; independent of Cortex master. Registry rows below."} else {"Owner-local execution; server counters do not include HC-private activity. Master, pause, group exclusions and compatibility can prevent automatic actions."};
        private _status=if (!_value) then {"DISABLED"} else {if (_blockedParents isNotEqualTo []) then {"UNCONFIGURED"} else {"LOADED"}};
        _checks pushBack ["ai","cortex-setting-"+_key,_status,format ["%1: selected=%2 default=%3; prerequisites=%4; related tuning [label,current,default]=%5. %6 Expected evidence: %7 A selected switch only permits the feature; it is not an action trigger or success result.",_label,_value,_default,_parentValues,_related,_scope,_featureNotes getOrDefault [_name,"Inspect the corresponding controller/profile rows; no dedicated activity counter is available for this option."]]];
    };
} forEach _tuningSpec;
// Queue health is measured locally once per requested report, without executing or rescheduling jobs.
private _queue=+(missionNamespace getVariable ["Waldo_AIPass_Jobs",[]]);
_queue append (missionNamespace getVariable ["Waldo_AIPass_PendingJobs",[]]);
private _overdue=0;
private _oldest=0;
private _staleOwners=0;
private _earliestQueued=-1;
{
    _x params ["_due","","_jobState"];
    if (_earliestQueued < 0 || {_due < _earliestQueued}) then {_earliestQueued=_due};
    if (_due < time) then {_overdue=_overdue+1; _oldest=_oldest max (time-_due)};
    private _jobGroup=_jobState getOrDefault ["group",grpNull];
    if (!isNull _jobGroup && {!local _jobGroup || {(_jobState getOrDefault ["ownerEpoch",-1]) != (_jobGroup getVariable ["Waldo_AIPass_Epoch",0])}}) then {_staleOwners=_staleOwners+1};
} forEach _queue;
private _cachedNextDue=missionNamespace getVariable ["Waldo_AIPass_NextJobDue",-1];
private _cacheConsistent=(_queue isEqualTo [] && {_cachedNextDue < 0})
    || {_queue isNotEqualTo [] && {_cachedNextDue >= 0} && {_cachedNextDue <= (_earliestQueued+0.001)}};
private _queueState=if (_cacheConsistent) then {"LOADED"} else {"ERROR"};
private _queueHint=if (_cacheConsistent) then {
    "Due jobs and stale jobs may await the next scheduler tick; repeat the report before diagnosing starvation."
} else {
    "The scheduler deadline cache is missing or later than the earliest queued job. Restart Cortex or inspect queue mutation paths before trusting idle scheduling."
};
_checks pushBack ["ai","cortex-queue-health",_queueState,format ["serverJobs=%1 dueNow=%2 oldestDueSeconds=%3 staleOwnerJobs=%4 cachedNextDueSeconds=%5 earliestQueuedDueSeconds=%6 deadlineCacheConsistent=%7 fps=%8 budgetMs=%9 paused=%10. %11",count _queue,_overdue,_oldest,_staleOwners,if (_cachedNextDue < 0) then {-1} else {_cachedNextDue-time},if (_earliestQueued < 0) then {-1} else {_earliestQueued-time},_cacheConsistent,diag_fps,missionNamespace getVariable ["Waldo_AIPass_TickBudgetMs",1],[] call Waldo_fnc_CortexIsPaused,_queueHint]];
// Coordinated work is server-owned, so expose the lease/turn state which an HC-only
// group snapshot cannot explain. This is calculated only for an on-demand report.
private _supportRequests=missionNamespace getVariable ["Waldo_AIPass_SupportRequests",createHashMap];
private _activeSupportBounds=0;
private _supportFailures=0;
private _retiredSupportTeams=0;
{
    private _request=_y;
    if ((_request getOrDefault ["boundActive",[]]) isNotEqualTo []) then {_activeSupportBounds=_activeSupportBounds+1};
    {_supportFailures=_supportFailures+_y} forEach (_request getOrDefault ["boundFailuresByToken",createHashMap]);
    _retiredSupportTeams=_retiredSupportTeams+count (_request getOrDefault ["boundRetired",[]]);
} forEach _supportRequests;
_checks pushBack ["ai","cortex-coordination-health",if (_retiredSupportTeams > 0) then {"ERROR"} else {"LOADED"},format ["requests=%1 activeBounds=%2 recordedBoundFailures=%3 retiredTeams=%4. A NOT_READY result yields immediately; TIMEOUT or repeated failures identify a movement/controller fault rather than successful support.",count _supportRequests,_activeSupportBounds,_supportFailures,_retiredSupportTeams]];
{
    private _request=_supportRequests get _x;
    private _requester=_request getOrDefault ["requester",grpNull];
    _checks pushBack ["ai","cortex-coordination-"+_x,"LOADED",format ["requester=%1 leases=%2 active=%3 completed=%4 retired=%5 failuresByToken=%6 secondsRemaining=%7",if (isNull _requester) then {"NULL"} else {groupId _requester},count (_request getOrDefault ["leases",[]]),_request getOrDefault ["boundActive",[]],_request getOrDefault ["boundCompleted",[]],_request getOrDefault ["boundRetired",[]],_request getOrDefault ["boundFailuresByToken",createHashMap],((_request getOrDefault ["expiry",serverTime])-serverTime) max 0]];
} forEach ((keys _supportRequests) select [0,20]);
private _localGroups=_groups select {local _x && {_x getVariable ["Waldo_AIPass_Managed",false]}};
_checks pushBack ["ai","cortex-snapshot-scope","LOADED",format ["Snapshot serverTime=%1; server-local managed groups=%2, sampled=%3 (limit 20); HC-owned groups=%4. HC private action/queue state is unavailable here, not zero. Stationary or PATH-disabled units may be covering; one snapshot cannot prove a stall.",serverTime,count _localGroups,(count _localGroups) min 20,count _hcGroups]];
{
    private _group=_x;
    {
        _x params ["_type","_variable"];
        private _refusal=_group getVariable [_variable,[]];
        if (_refusal isNotEqualTo []) then {
            _checks pushBack ["ai",format ["cortex-tactical-refusal-%1-%2",toLowerANSI _type,netId leader _group],"LOADED",format ["group=%1 owner=%2 type=%3 lastRefusal=[reason,time,detail]=%4. This is the latest changed start gate, not a permanent error; a later accepted lease clears it.",groupId _group,groupOwner _group,_type,_refusal]];
        };
    } forEach [["FLANK","Waldo_Cortex_FlankRefusal"],["ADVANCE","Waldo_Cortex_AdvanceRefusal"]];
} forEach (_localGroups select [0,20]);
{
    private _group=_x;
    private _state=_group getVariable ["Waldo_AIPass_State",createHashMap];
    private _phaseTransition=_group getVariable ["Waldo_Cortex_PhaseTransition",[]];
    if (count _phaseTransition == 5) then {
        private _phaseCurrent=_state getOrDefault ["phase","UNKNOWN"];
        private _phaseExpected=_phaseTransition select 2;
        _checks pushBack ["ai",format ["cortex-phase-transition-%1",netId leader _group],["ERROR","LOADED"] select (_phaseCurrent == _phaseExpected),format ["group=%1 owner=%2 current=%3 latest=[serverTime,from,to,reason,owner]=%4 historyEntries=%5. A mismatch means phase state changed outside the atomic transition path.",groupId _group,groupOwner _group,_phaseCurrent,_phaseTransition,count (_group getVariable ["Waldo_Cortex_PhaseTransitions",[]])]];
    };
    private _drill=_state getOrDefault ["drill",createHashMap];
    private _members=(units _group) select [0,8];
    if (count _drill > 0) then {
        private _lastStep=_drill getOrDefault ["lastStep",_drill getOrDefault ["started",time]];
        private _heartbeatAge=(time-_lastStep) max 0;
        private _watchdog=30;
        private _resumeGrace=((missionNamespace getVariable ["Waldo_AIPass_ResumeGraceUntil",-1])-time) max 0;
        private _movementLease=_state getOrDefault ["movementLease",[]];
        private _healthy=_heartbeatAge <= _watchdog || {_resumeGrace > 0};
        _checks pushBack ["ai",format ["cortex-drill-health-%1",netId _group],["ERROR","LOADED"] select _healthy,format ["group=%1 type=%2 stage=%3 token=%4 heartbeatAgeSeconds=%5 watchdogSeconds=%6 movementLease=%7 resumeGraceSeconds=%8. An overdue controller is released through common drill cleanup; a stored drill or waypoint is not completion evidence.",groupId _group,_drill getOrDefault ["type","UNKNOWN"],_drill getOrDefault ["stage","UNKNOWN"],_drill getOrDefault ["token",""],_heartbeatAge,_watchdog,_movementLease,_resumeGrace]];
    };
    private _remount=_group getVariable ["Waldo_Cortex_Remount",[]];
    if (count _remount == 2) then {
        private _remountDeadline=_remount select 0;
        private _remountPassengers=_remount select 1;
        private _remountConflicts=_remountPassengers select {
            _x params ["_unit","_vehicle"];
            alive _unit && {!isNull assignedVehicle _unit} && {assignedVehicle _unit != _vehicle}
        };
        private _remountPending=_remountPassengers select {
            _x params ["_unit","_vehicle"];
            alive _unit && {alive _vehicle} && {vehicle _unit != _vehicle}
        };
        private _remountHealthy=serverTime < _remountDeadline && {_remountConflicts isEqualTo []};
        _checks pushBack ["ai",format ["cortex-remount-ownership-%1",netId _group],["ERROR","LOADED"] select _remountHealthy,format ["group=%1 secondsRemaining=%2 passengers=%3 pending=%4 assignmentConflicts=%5. The stored list is boarding intent, not proof that passengers stayed aboard or re-entered; a different assignment must cancel the affected actor.",groupId _group,(_remountDeadline-serverTime) max 0,count _remountPassengers,count _remountPending,count _remountConflicts]];
    };
    private _transition=_group getVariable ["Waldo_Cortex_TransitionIntent",[]];
    if (count _transition == 6) then {
        _transition params ["_transitionPhase","_transitionTarget","_transitionStarted","_transitionDeadline","_transitionSource","_transitionTeam"];
        private _transitionGateOpen=switch (_transitionPhase) do {
            case "INVESTIGATE": {
                private _sourceGate=["Waldo_AIPass_ContactReports_Enable","Waldo_AIPass_Hearing_Enable"] select (_transitionSource == "SOUND");
                [_group,"Waldo_AIPass_Investigate_Enable",true] call Waldo_fnc_CortexFeatureEnabled
                    && {_transitionSource == "" || {[_group,_sourceGate,true] call Waldo_fnc_CortexFeatureEnabled}}
            };
            case "SEARCH": {[_group,"Waldo_AIPass_PostContact_Enable",true] call Waldo_fnc_CortexFeatureEnabled};
            default {false};
        };
        private _transitionCurrent=_state getOrDefault ["phase","UNKNOWN"];
        private _transitionHealthy=serverTime < _transitionDeadline && {_transitionGateOpen} && {_transitionCurrent == _transitionPhase};
        _checks pushBack ["ai",format ["cortex-transition-ownership-%1",netId _group],["ERROR","LOADED"] select _transitionHealthy,format ["group=%1 intentPhase=%2 currentPhase=%3 source=%4 gateOpen=%5 ageSeconds=%6 secondsRemaining=%7 teamAlive=%8 target=%9. A durable transition exists only to resume INVESTIGATE or SEARCH after locality migration; it must not survive its gate, deadline or phase.",groupId _group,_transitionPhase,_transitionCurrent,_transitionSource,_transitionGateOpen,(serverTime-_transitionStarted) max 0,(_transitionDeadline-serverTime) max 0,{alive _x} count _transitionTeam,_transitionTarget]];
    };
    private _supportLease=_group getVariable ["Waldo_AIPass_SupportLease",[]];
    private _supportToken=_state getOrDefault ["supportToken",""];
    private _supportRole=_group getVariable ["Waldo_Cortex_SupportRole",[]];
    if (_supportLease isNotEqualTo [] || {_supportToken != ""} || {_supportRole isNotEqualTo []}) then {
        private _leaseToken=_supportLease param [0,""];
        private _leaseExpiry=_supportLease param [2,0];
        private _roleToken=_supportRole param [0,""];
        private _supportHealthy=count _supportLease == 6 && {serverTime < _leaseExpiry}
            && {_supportToken in ["",_leaseToken]} && {_roleToken in ["",_leaseToken]};
        _checks pushBack ["ai",format ["cortex-support-ownership-%1",netId _group],["ERROR","LOADED"] select _supportHealthy,format ["group=%1 leaseToken=%2 localToken=%3 roleToken=%4 secondsRemaining=%5 responding=%6 assaulting=%7 movementLease=%8. Token disagreement or an expired retained lease identifies overlapping or orphaned coordinated work.",groupId _group,_leaseToken,_supportToken,_roleToken,(_leaseExpiry-serverTime) max 0,_state getOrDefault ["responding",false],_state getOrDefault ["assaulting",false],_state getOrDefault ["movementLease",[]]]];
    };
    private _combinedRole=_group getVariable ["Waldo_Cortex_CombinedRole",[]];
    if (_combinedRole isNotEqualTo []) then {
        private _combinedRequester=_combinedRole param [1,grpNull];
        private _combinedTarget=_combinedRole param [2,objNull];
        private _combinedName=_combinedRole param [4,""];
        private _combinedExpiry=_combinedRole param [5,0];
        private _combinedHealthy=count _combinedRole == 7 && {serverTime < _combinedExpiry}
            && {!isNull _combinedRequester} && {!isNull _combinedTarget} && {alive _combinedTarget}
            && {side _combinedRequester == side _group} && {_combinedName in ["GROUND_FIRE","GROUND_MANOEUVRE","AIR_ATTACK"]};
        _checks pushBack ["ai",format ["cortex-combined-role-%1",netId _group],["ERROR","LOADED"] select _combinedHealthy,format ["group=%1 token=%2 role=%3 requester=%4 target=%5 secondsRemaining=%6 applied=%7 result=%8. Combined roles share an opportunity only; they contain no assembly readiness or infantry movement gate.",groupId _group,_combinedRole param [0,""],_combinedName,groupId _combinedRequester,_combinedTarget,(_combinedExpiry-serverTime) max 0,_group getVariable ["Waldo_Cortex_CombinedApplied",[]],_group getVariable ["Waldo_Cortex_CombinedResult",[]]]];
    };
    _checks pushBack ["ai",format ["cortex-group-context-%1",netId _group],"LOADED",format ["group=%1 phaseAgeSeconds=%2 lastSeenAgeSeconds=%3 morale=%4 moraleState=%5 investigating=%6 searchMembers=%7 reinforcementResponding=%8 dismounted=%9 withdrawnVehicles=%10 disabledFeatures=%11 externalControl=%12. Ages are owner-local; unknown uses -1. Stored intentions are not physical completion.",groupId _group,if ("phaseStart" in _state) then {time-(_state get "phaseStart")} else {-1},if ("lastSeen" in _state) then {time-(_state get "lastSeen")} else {-1},_state getOrDefault ["morale",-1],_state getOrDefault ["moraleState","UNKNOWN"],_state getOrDefault ["areaInvestigation",""],count (_state getOrDefault ["searchTeam",[]]),_state getOrDefault ["responding",false],count (_state getOrDefault ["dismounted",[]]),count (_state getOrDefault ["withdrawn",[]]),_group getVariable ["Waldo_AIPass_DisabledFeatures",[]],_group getVariable ["Waldo_AI_ExternalControl",false]]];
    private _actors=_members apply {[_x,currentCommand _x,round speed _x,_x checkAIFeature "PATH",_x checkAIFeature "MOVE",behaviour _x,unitCombatMode _x]};
    _checks pushBack ["ai",format ["cortex-group-%1",netId _group],"LOADED",format ["group=%1 owner=%2 phase=%3 drill=%4 stage=%5 bound=%6 recoveryActors=%7 groupSpeed=%8 excluded=%9 ZeusWaypoints=%10 ZeusHoldRemaining=%11 supportRole=%12 supportResult=%13 supportAbort=%14 combinedRole=%15 withdrawal=[status,travel,replans]=%16; first 8 members [unit,command,km/h,PATH,MOVE,behaviour,ROE]=%17",
        groupId _group,groupOwner _group,_state getOrDefault ["phase","UNKNOWN"],_drill getOrDefault ["type","NONE"],_drill getOrDefault ["stage","NONE"],_drill getOrDefault ["index",-1],count (_drill getOrDefault ["recovery",[]]),speedMode _group,_group getVariable ["Waldo_AIPass_Exclude",false],_group getVariable ["Waldo_AIPass_ZeusWaypoints",false],((_group getVariable ["Waldo_AIPass_ZeusLocalUntil",time])-time) max 0,_group getVariable ["Waldo_Cortex_SupportRole",[]],_group getVariable ["Waldo_Cortex_SupportBoundResult",[]],_group getVariable ["Waldo_Cortex_SupportAbort",[]],_combinedRole,_group getVariable ["Waldo_Cortex_Withdrawal",[]],_actors]];
} forEach (_localGroups select [0,20]);
// Explicit orders publish assignments, so their physical distances can be inspected for any owner.
private _orderedGroups=_groups select {(_x getVariable ["Waldo_AIPass_Garrison",[]]) isNotEqualTo [] || {(_x getVariable ["Waldo_AIPass_Defend",[]]) isNotEqualTo []} || {(_x getVariable ["Waldo_AIPass_ClearOrder",[]]) isNotEqualTo []} || {(_x getVariable ["Waldo_Cortex_ClearResult",[]]) isNotEqualTo []}};
{
    private _group=_x;
    private _clearOrder=_group getVariable ["Waldo_AIPass_ClearOrder",[]];
    private _clearResult=_group getVariable ["Waldo_Cortex_ClearResult",[]];
    private _clearEvidence=if (_clearOrder isEqualTo []) then {
        _group getVariable ["Waldo_Cortex_ClearEvidence",[]]
    } else {
        [_clearOrder param [1,[]],_clearOrder param [4,[]],_clearOrder param [5,[]],_clearOrder param [6,[]],_clearOrder param [2,serverTime],_clearOrder param [7,serverTime]]
    };
    if (_clearResult isNotEqualTo []) then {
        _checks pushBack ["ai",format ["cortex-clearance-%1",netId _group],if ((_clearResult param [0,""]) == "INCOMPLETE") then {"ERROR"} else {"LOADED"},format ["group=%1 owner=%2 result=%3 visitedIndices=%4 exhaustedIndices=%5 retryCounts=%6 failedBy=%7 secondsRemaining=%8 secondsSinceProgress=%9. Position visits measure traversal, not hostile-room clearance. A finished failed order remains visible after its controller releases.",groupId _group,groupOwner _group,_clearResult,_clearEvidence param [0,[]],_clearEvidence param [1,[]],_clearEvidence param [2,[]],_clearEvidence param [3,[]],if (_clearEvidence isEqualTo []) then {-1} else {((_clearEvidence param [4,serverTime])-serverTime) max 0},if (_clearEvidence isEqualTo []) then {-1} else {(serverTime-(_clearEvidence param [5,serverTime])) max 0}]];
    };
    private _positions=((units _group) select [0,8]) apply {
        private _slot=_x getVariable ["Waldo_AIPass_GarrisonPos",_x getVariable ["Waldo_AIPass_DefendPos",[]]];
        [_x,alive _x,if (_slot isEqualTo []) then {-1} else {_x distance (_slot select 0)},getPosATL _x]
    };
    _checks pushBack ["ai",format ["cortex-orders-%1",netId _group],"LOADED",format ["group=%1 owner=%2 garrison=%3 defend=%4 clearResult=%5; first 8 [unit,alive,3D-assignment-distance-or-minus1,actualATL]=%6. Reaching an assigned point does not prove usable cover, interior pathing or a cleared room. Check building simulation, accessible positions and actual firing clearance; no teleport correction is performed.",groupId _group,groupOwner _group,_group getVariable ["Waldo_AIPass_Garrison",[]],_group getVariable ["Waldo_AIPass_Defend",[]],_group getVariable ["Waldo_Cortex_ClearResult",[]],_positions]];
} forEach (_orderedGroups select [0,20]);
_checks pushBack ["ai","cortex-order-snapshot-scope","LOADED",format ["Explicit-order groups=%1 sampled=%2. Assignment/clear-result data is public; HC-private controllers remain unavailable.",count _orderedGroups,(count _orderedGroups) min 20]];
private _missions=missionNamespace getVariable ["Waldo_AIPass_FireMissions",createHashMap];
{
    private _mission=_missions get _x;
    private _phase=_mission getOrDefault ["phase","UNKNOWN"];
    _checks pushBack ["ai","cortex-fire-"+_x,if (_phase == "UNCERTAIN") then {"ERROR"} else {"LOADED"},format ["purpose=%1 phase=%2 confirmedShots=%3 remaining=%4 burstsLeft=%5 dueInSeconds=%6 owner=%7. PENDING is awaiting a firing event, not confirmed fire; UNCERTAIN must not be retried blindly.",_mission getOrDefault ["purpose","UNKNOWN"],_phase,_mission getOrDefault ["fired",0],_mission getOrDefault ["remaining",0],_mission getOrDefault ["burstsLeft",0],(_mission getOrDefault ["due",time])-time,owner (_mission getOrDefault ["battery",objNull])]];
} forEach ((keys _missions) select [0,20]);
private _convoys=missionNamespace getVariable ["Waldo_Convoy_Registry",[]];
{
    _x params ["_group","_configuration"];
    _checks pushBack ["ai",format ["cortex-convoy-%1",netId _group],"LOADED",format ["group=%1 owner=%2 revision=%3 phase=%4 haltReason=%5 vehicles=%6. A halt reason records the controller decision, not proof of physical unloading or recovery.",groupId _group,groupOwner _group,_configuration param [0,-1],_configuration param [5,"UNKNOWN"],_configuration param [8,""],count (_configuration param [4,[]])]];
} forEach (_convoys select [0,20]);
private _scoots=vehicles select {(_x getVariable ["Waldo_Cortex_ArtilleryScootToken",""]) != ""};
{
    private _purpose=_x getVariable ["Waldo_Cortex_ArtilleryScootPurpose",""];
    private _counter=_purpose == "COUNTER";
    private _feature=["Waldo_AIPass_Artillery_Enable","Waldo_AIPass_CounterBattery_Enable"] select _counter;
    private _setting=["Waldo_AIPass_Artillery_ShootAndScoot","Waldo_AIPass_CounterBattery_ShootAndScoot"] select _counter;
    private _crewGroup=if (isNull driver _x) then {grpNull} else {group driver _x};
    private _deadline=_x getVariable ["Waldo_Cortex_ArtilleryScootDeadline",0];
    private _gateOpen=!isNull _crewGroup && {_purpose in ["SUPPORT","COUNTER"]}
        && {missionNamespace getVariable [_setting,true]}
        && {[_crewGroup,_feature,false] call Waldo_fnc_CortexFeatureEnabled};
    private _healthy=serverTime < _deadline && {_gateOpen};
    _checks pushBack ["ai",format ["cortex-artillery-scoot-ownership-%1",netId _x],["ERROR","LOADED"] select _healthy,format ["class=%1 owner=%2 group=%3 token=%4 purpose=%5 secondsRemaining=%6 gateOpen=%7 mobile=%8 speed=%9. A pending token owns one delayed relocation; it must disappear when its gate closes or deadline expires.",typeOf _x,owner _x,if (isNull _crewGroup) then {"NULL"} else {groupId _crewGroup},_x getVariable ["Waldo_Cortex_ArtilleryScootToken",""],_purpose,(_deadline-serverTime) max 0,_gateOpen,canMove _x,speed _x]];
} forEach (_scoots select [0,20]);
_checks pushBack ["ai","cortex-controller-snapshot-limits","LOADED",format ["Fire missions total=%1 sampled=%2; convoys total=%3 sampled=%4; pending artillery relocations total=%5 sampled=%6; limits 20 each. Counters are server-local unless explicitly described as registry state. No diagnostics poller is installed.",count _missions,(count _missions) min 20,count _convoys,(count _convoys) min 20,count _scoots,(count _scoots) min 20]];
private _attackAircraft=vehicles select {_x isKindOf "Air" && {(_x getVariable ["Waldo_Cortex_AttackFlarePhase",""]) != ""}};
{
    _checks pushBack ["ai",format ["cortex-attack-flares-%1",netId _x],"LOADED",format ["class=%1 owner=%2 phase=%3 cooldownRemaining=%4 speed=%5 alive=%6. Phase describes the last requested leg, not actual release; inspect Fired events and countermeasure ammunition. No flight commands are issued.",typeOf _x,owner _x,_x getVariable ["Waldo_Cortex_AttackFlarePhase",""],((_x getVariable ["Waldo_Cortex_AttackFlareCooldown",0])-serverTime) max 0,speed _x,alive _x]];
} forEach (_attackAircraft select [0,20]);
private _adaptiveAircraft=vehicles select {_x isKindOf "Air" && {
    (_x getVariable ["Waldo_Cortex_AirAttackPlan",[]]) isNotEqualTo []
        || {(_x getVariable ["Waldo_Cortex_AirAttackOutcome",[]]) isNotEqualTo []}
}};
{
    private _aircraft=_x;
    private _plan=_aircraft getVariable ["Waldo_Cortex_AirAttackPlan",[]];
    private _outcome=_aircraft getVariable ["Waldo_Cortex_AirAttackOutcome",[]];
    private _request=_aircraft getVariable ["Waldo_Cortex_CountermeasureLastRequest",[]];
    private _reason=_outcome param [0,""];
    private _healthy=alive _aircraft && {(getPosATL _aircraft select 2) >= 25}
        && {_reason in ["","COMPLETE","CONTROL_RELEASED","TARGET_LOST","AUTHORED_ROUTE_CHANGED","NOT_ATTACKING"]};
    _checks pushBack ["ai",format ["cortex-air-attack-%1",netId _aircraft],["ERROR","LOADED"] select _healthy,
        format ["class=%1 owner=%2 current=[token,pattern,stage,target,destination,remaining,actualShots,observedAA,speed,altitude,approachCM,egressCM,platform,lateralTurret,standoffWeapon,standoffTurret,fireSolution,stageAltitudes,stageSpeeds,captureRadii,attackMinimum,points,selectedWeapon,selectedSimulation,selectedTurret]=%3 lastOutcome=[reason,time,pattern,actualShots]=%4 lastCountermeasureRequest=%5 standoffBlockedSeconds=%6 crewRetained=%7. A Fired event is not an effective attack by itself; inspect the live solution, release geometry, projectile result and physical egress.",
            typeOf _aircraft,owner _aircraft,_plan,_outcome,_request,((_aircraft getVariable ["Waldo_Cortex_AirStandoffBlockedUntil",0])-serverTime) max 0,(crew _aircraft) findIf {!alive _x || {vehicle _x != _aircraft}} < 0]];
} forEach (_adaptiveAircraft select [0,20]);
_checks pushBack ["ai","cortex-air-attack-snapshot-limits","LOADED",format ["Adaptive aircraft total=%1 sampled=%2 (limit 20). Active plans and retained outcomes are included; physical travel, Fired events and explicit transitions remain the acceptance evidence.",count _adaptiveAircraft,(count _adaptiveAircraft) min 20]];
["ai", _checks] call Waldo_fnc_DiagnosticFeatureReport
