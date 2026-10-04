/*
 * Author: WaldoTheWarfighter
 * The list of Cortex difficulty and tuning settings that can be changed during a mission.
 *
 * One list feeds the AI Control and Tuning Zeus pages, the validation in Waldo_fnc_CortexTuning and the
 * snapshot joining headless clients request, so the three cannot drift apart. Every setting is read
 * live by the behaviours, so a change takes effect on each squad's next step. Defaults are the
 * MissionConfig\aiConfig.sqf values.
 * Locality and authority: read-only; callable anywhere.
 *
 * Repeat/JIP: read-only and repeat-safe; joining owners use this same list for their snapshot.
 * Arguments:
 * None
 *
 * Return Value:
 * Array of [variable, label, tooltip, kind, options, default, section]:
 * - kind "SLIDER": options [min, max, decimals]
 * - kind "CHECKBOX": options []
 * - kind "COMBO": options [values, labels]
 *
 * Example:
 * private _variables = ([] call Waldo_fnc_CortexTuningSpec) apply {_x select 0};
 * Result: every tunable Cortex variable name.
 *
 * Current callers: Waldo_fnc_CortexTuning, Waldo_fnc_FeatureRuntimeZen (AI Control and Tuning) and
 * Waldo_fnc_FeatureRuntimeRequestState.
 */

private _profiles = ["", "MILITIA", "LINE", "VETERAN", "ELITE"];
private _profileLabels = ["Follow the AI Rebalance profile", "Militia", "Line", "Veteran", "Elite"];
{
    if !(_x in _profiles || {_x in ["LEGACY", "PUBLIC", "STANDARD"]}) then {_profiles pushBack _x; _profileLabels pushBack _x};
} forEach keys (missionNamespace getVariable ["Waldo_AIPass_ProfileBehaviour", createHashMap]);

private _skillProfiles = ["LEGACY","MILITIA","LINE","VETERAN","ELITE"];
{if !(_x in ["PUBLIC","STANDARD"]) then {_skillProfiles pushBackUnique _x}} forEach keys (missionNamespace getVariable ["Waldo_AI_Profiles",createHashMap]);
private _skillNames = missionNamespace getVariable ["Waldo_AI_ProfileDisplayNames",createHashMap];
private _skillLabels = _skillProfiles apply {_skillNames getOrDefault [_x,_x]};
private _spec = [
    ["Waldo_AIRebalance_Enable", "Apply WMP skill profiles", "Master control for WMP skill adjustment. When enabled, the selected skill profile is applied by the machine that owns each AI unit.", "CHECKBOX", [], true],
    ["Waldo_AI_InfantryDispersion", "Infantry weapon dispersion", "Owner-local aim coefficient for dismounted AI and vehicle cargo. Higher values reduce precision without changing reaction or movement skill.", "SLIDER", [1,3,2], 1.35],
    ["Waldo_AI_VehicleCrewAimMultiplier", "Vehicle crew precision", "Final multiplier for operating vehicle and aircraft crew aiming skills. Cargo keeps the normal infantry profile.", "SLIDER", [0.25,1,2], 0.6],
    ["Waldo_AI_VehicleCrewDispersion", "Ground vehicle dispersion", "Owner-local aim coefficient for ground-vehicle operators. WMP skips this layer when LAMBS Turrets is loaded to avoid double stacking.", "SLIDER", [1,6,2], 3.5],
    ["Waldo_AI_AirCrewDispersion", "Aircraft weapon dispersion", "Owner-local aim coefficient for aircraft operators. Dynamic AA aircraft remain exempt; LAMBS Turrets prevents double stacking.", "SLIDER", [1,7,2], 4.25],
    ["Waldo_AIPass_Enable", "Enable Cortex automatic tactics", "Master control for Cortex actions and reactions. The purpose switches below choose which tactics Cortex may use; convoy control remains independent.", "CHECKBOX", [], true],
    ["Waldo_AIPass_Regroup_Enable", "Survivor regroup", "Survivors of a destroyed squad walk to and join a nearby friendly squad.", "CHECKBOX", [], true],
    ["Waldo_AIPass_Contact_Enable", "Contact handling", "Squads switch to combat on contact and return to their previous behaviour and waypoints afterwards. Needed by every combat option below.", "CHECKBOX", [], true],
    ["Waldo_AIPass_PostContact_Enable", "Post-contact search", "After contact is lost: hold, send two soldiers to check the last known position, regroup.", "CHECKBOX", [], true],
    ["Waldo_AIPass_PostContact_LostSeconds", "Contact lost delay (s)", "Seconds without a sighting before Cortex leaves contact. Active manoeuvres finish or abort before this handover.", "SLIDER", [3,120,0], 30],
    ["Waldo_AIPass_PostContact_SecuritySeconds", "Security hold (s)", "Seconds spent securing the last contact before a search team moves.", "SLIDER", [0,60,0], 10],
    ["Waldo_AIPass_PostContact_SearchSeconds", "Search limit (s)", "Maximum time for the two-soldier search of the last known enemy position.", "SLIDER", [10,180,0], 45],
    ["Waldo_AIPass_PostContact_RegroupSeconds", "Regroup limit (s)", "Maximum time for surviving squad members to close up before Cortex releases control.", "SLIDER", [10,120,0], 30],
    ["Waldo_AIPass_Flank_Enable", "Flanking", "Half the squad flanks in covered bounds while the rest suppresses.", "CHECKBOX", [], true],
    ["Waldo_AIPass_StreetCrossing_Enable", "Street crossing", "Flanking squads stop at roads, throw smoke and cross in one bound.", "CHECKBOX", [], true],
    ["Waldo_AIPass_FireControl_Enable", "Fire control", "Close threats first, spread fire across visible enemies, and alternate suppression inside each squad. A short random delay keeps separate squads from firing in lockstep; every ordered burst checks for friendlies.", "CHECKBOX", [], true],
    ["Waldo_AIPass_FireControl_MaxShootersPerTarget", "Shooters per target", "Extra shooters prefer another visible enemy once this many soldiers are assigned to one target. Immediate close threats still take priority.", "SLIDER", [1,12,0], 2],
    ["Waldo_AIPass_Morale_Enable", "Morale and retreat", "Squads under heavy losses and fire break and fall back under smoke.", "CHECKBOX", [], true],
    ["Waldo_AIPass_Surrender_Enable", "Surrender", "One or two broken survivors surrender only when an enemy is within 60 m and no friendly squad is within 300 m (ACE Captives when loaded).", "CHECKBOX", [], true],
    ["Waldo_AIPass_GrenadeEvasion_Enable", "Grenade evasion", "AI move away from a live grenade they can see. Test before live use.", "CHECKBOX", [], true],
    ["Waldo_AIPass_AntiArmour_Enable", "Anti-armour", "The best anti-tank gunner engages known armour, clear of backblast.", "CHECKBOX", [], true],
    ["Waldo_AIPass_Vehicles_Enable", "Enable Cortex vehicle tactics", "Parent control for Cortex passenger dismount, remount and damaged-vehicle withdrawal. Convoy route control remains independent.", "CHECKBOX", [], true],
    ["Waldo_AIPass_NavalAssault_Enable", "Naval infantry landing", "AI boat crews make one finite shallow-water approach and deliver embarked infantry onto dry ground. PROTOCOL AI NAVY SEAL takes priority when loaded.", "CHECKBOX", [], true],
    ["Waldo_AIPass_ContactReports_Enable", "Contact reports", "Squads share sighted enemies by radio (blocked by jamming) or by voice.", "CHECKBOX", [], true],
    ["Waldo_AIPass_Reinforce_Enable", "Reinforcement", "Idle nearby squads move up behind a squad in contact.", "CHECKBOX", [], true],
    ["Waldo_AIPass_Artillery_Enable", "Enable spotter artillery support", "Parent control for spotter-requested support and retreat smoke missions. Explicitly assign a spotter and configure a friendly battery first.", "CHECKBOX", [], false],
    ["Waldo_AIPass_CounterBattery_Enable", "Counter-battery", "AI artillery answers enemy artillery whose position is known.", "CHECKBOX", [], false],
    ["Waldo_AIPass_Airborne_Enable", "Airborne insertion", "AI squads riding in AI-flown helicopters or planes parachute out when their aircraft nears a known enemy.", "CHECKBOX", [], false],
    ["Waldo_Cortex_AttackRunFlares_Enable", "Proactive attack-run countermeasures", "AI aircraft expend countermeasures while approaching and leaving an assigned hostile target. This is based on attack-run geometry, not a detected missile.", "CHECKBOX", [], true],
    ["Waldo_Cortex_AirAttack_Enable", "Adaptive aircraft attack patterns", "Eligible planes choose finite strafe, offset, hook or standoff runs. Helicopters also use hover-capable standoff and lateral gun runs. Observed AA and live weapons influence the choice; Zeus orders immediately take priority.", "CHECKBOX", [], true],
    ["Waldo_AIPass_AircraftFlares_Enable", "Missile-threat countermeasures", "Eligible AI aircraft expend a staggered countermeasure sequence after an incoming missile is detected.", "CHECKBOX", [], true],
    ["Waldo_AIPass_Investigate_Enable", "Investigation", "Squads send two riflemen to check enemies they know about but have not seen.", "CHECKBOX", [], true],
    ["Waldo_AIPass_Assault_Enable", "Final assault", "A flank can finish with a grenade and a rush on the enemy position.", "CHECKBOX", [], true],
    ["Waldo_AIPass_Advance_Enable", "Bounding advance", "Squads in a long firefight push a fire team towards their waypoint in covered bounds.", "CHECKBOX", [], true],
    ["Waldo_AIPass_Advance_MinContactSeconds", "Advance contact delay", "Seconds of confirmed contact before a bounding advance may begin. The default reacts quickly enough to take ownership before native waypoint travel consumes the manoeuvre; other movement, knowledge and eligibility checks still apply.", "SLIDER", [0,300,0], 5],
    ["Waldo_AIPass_Advance_Cooldown", "Advance repeat delay", "Seconds after an advance ends before the same squad may start another. This is shorter than the flank delay so a squad can continue progressing in successive tactical bounds without immediately restarting a finished drill.", "SLIDER", [0,180,0], 20],
    ["Waldo_AIPass_CoordinatedAssault_Enable", "Coordinated assault", "Reinforcing squads assault from both sides while the squad in contact fires.", "CHECKBOX", [], true],
    ["Waldo_AIPass_Stance_Enable", "Stance from cover", "Soldiers stand, kneel or go prone to match the cover in front of them.", "CHECKBOX", [], true],
    ["Waldo_AIPass_AmmoShare_Enable", "Ammo sharing", "Soldiers down to their last magazine get one from a nearby squad-mate.", "CHECKBOX", [], true],
    ["Waldo_AIPass_VehicleGunnery_Enable", "Vehicle gunnery", "Gunners engage AT soldiers first, then armour; armour backs away from AT teams.", "CHECKBOX", [], true],
    ["Waldo_AIPass_ArtillerySmoke_Enable", "Retreat artillery smoke mission", "Allows a retreating squad to request a non-lethal smoke screen. Requires Enable spotter artillery support and an eligible battery.", "CHECKBOX", [], true],
    ["Waldo_AIPass_AircraftBreak_Enable", "Aircraft break-away", "Eligible AI aircraft preserve forward energy while jinking away from missile launches. Test addon aircraft first.", "CHECKBOX", [], true],
    ["Waldo_AIRebalance_Mode", "Lighting", "Automatic follows ambient darkness and equipped night vision. Day disables the extra penalty; Low light retains the legacy night profile.", "COMBO", [["AUTO","DAY","NIGHT"],["Automatic visibility","Daylight override","Low light (legacy)"]], "AUTO"],
    ["Waldo_AIRebalance_Profile", "Selected WMP skill profile", "Skill values used when Apply WMP skill profiles is enabled. This is independent of the Cortex behaviour profile.", "COMBO", [_skillProfiles,_skillLabels], "LINE"],
    ["Waldo_AIPass_LambsMode", "LAMBS integration", "Shared ownership leaves Danger FSM tactics active. A finite Cortex rally or coordinated assault pauses LAMBS movement only for that responder, then restores its prior setting. Cortex only disables Danger group tactics for every managed squad. Installed LAMBS Waypoints remains the preferred Garrison and Clear Building backend in either mode. Turrets, Suppression and RPG remain active in both modes.", "COMBO", [["SPLIT","WMP"],["Shared ownership (recommended)","Cortex only"]], "SPLIT"],
    ["Waldo_AIPass_CivilianReaction_Enable", "Civilian danger reactions", "Unarmed civilians flee nearby gunfire or a hit using event handlers and one finite move. WMP yields completely when Simple Civilian Behaviour owns the civilian.", "CHECKBOX", [], true],
    ["Waldo_AIPass_CivilianReaction_Radius", "Civilian gunfire radius (m)", "FiredNear events inside this distance may trigger an escape response.", "SLIDER", [10,150,0], 45],
    ["Waldo_AIPass_CivilianReaction_Distance", "Civilian escape distance (m)", "Approximate length of the safe escape leg away from the threat.", "SLIDER", [50,500,0], 180],
    ["Waldo_AIPass_CivilianReaction_Cooldown", "Civilian reaction cooldown (s)", "Minimum delay before another danger event can replace the current escape order.", "SLIDER", [2,120,0], 20],
    ["Waldo_AIPass_VehicleDismount_Enable", "Contact: dismount passengers", "Under Enable Cortex vehicle tactics, unloads capable passengers only when safely stopped on dry ground.", "CHECKBOX", [], true],
    ["Waldo_AIPass_VehicleRemount_Enable", "Contact: remount released passengers", "Under Enable Cortex vehicle tactics, allows safe conscious passengers to reboard after contact. A newer Zeus order cancels remount intent.", "CHECKBOX", [], true],
    ["Waldo_AIPass_VehicleWithdraw_Enable", "Damage: withdraw mobile vehicle", "Under Enable Cortex vehicle tactics, allows a damaged mobile vehicle to withdraw and use existing smoke.", "CHECKBOX", [], true],
    ["Waldo_AIPass_CoverValidation_Enable", "Additional cover checks", "Adds bounded slope and body clearance checks to shared cover selection.", "CHECKBOX", [], true],
    ["Waldo_Convoy_MountedFire_Enable", "Convoy mounted targeting", "WMP assigns targets to weapon crew under existing ROE. Disable to leave targeting to another AI mod.", "CHECKBOX", [], true],
    ["Waldo_Convoy_Cover_Enable", "Convoy dismount movement", "Moves dismounted passengers clear of vehicles; seeks cover during contact.", "CHECKBOX", [], true],
    ["Waldo_Convoy_AvoidInfantry_Enable", "Convoy infantry avoidance", "Optional short-range friendly infantry corridor checks before driving.", "CHECKBOX", [], false],
    ["Waldo_Convoy_DrivingAssist_Enable", "Convoy driving assist", "Uses low-frequency road look-ahead and damped speed changes for smoother curves, junctions and grades. It does not bypass obstacles or replace authored routes.", "CHECKBOX", [], true],
    ["Waldo_Convoy_RouteRecovery_Enable", "Convoy route recovery", "Re-selects the same unchanged final MOVE waypoint when the engine completes it more than 75 m early. It never creates a route, teleports, repairs or defeats an obstruction.", "CHECKBOX", [], true],
    ["Waldo_Convoy_ContactHalt_Enable", "Convoy contact halts", "Automatic ambush halt using push-through and pinned rules. Route arrival and explicit stop remain available.", "CHECKBOX", [], true],
    ["Waldo_Convoy_Unload_Enable", "Convoy cargo unloading", "Allows WMP passenger unloading on halt. Operating crews remain aboard.", "CHECKBOX", [], true],
    ["Waldo_AIPass_Hearing_Enable", "Nearby gunfire investigation", "Hostile FiredNear events create a throttled, approximate 50 m area for investigation, never a target reveal.", "CHECKBOX", [], true],
    // Squad behaviour
    ["Waldo_AIPass_BehaviourProfile", "Behaviour profile", "Tactics profile for every squad without a group or faction profile of its own. Skill values are not changed.", "COMBO", [_profiles, _profileLabels], ""],
    ["Waldo_AIPass_Aggression", "Aggression", "Scales flank/advance preference, optional grenade preparation, investigation and coordinated-assault participation. Positive local preferences choose which viable manoeuvre starts instead of deciding whether the squad acts. Default 1.2 adds initiative; 1 is the profile value and 0 excludes proactive tactics.", "SLIDER", [0, 2, 2], 1.2],
    ["Waldo_AIPass_Cohesion", "Cohesion", "How much punishment squads take before morale breaks. Above 1 they hold longer, below 1 they break sooner.", "SLIDER", [0.5, 2, 2], 1],
    ["Waldo_AIPass_ReactionSpeed", "Reaction speed", "How often squads re-assess. Above 1 they react faster and use more server time; below 1 slower.", "SLIDER", [0.5, 2, 2], 1],
    ["Waldo_AIPass_EngageRange", "Engagement range (m)", "Known enemies within this range of a squad leader are acted on.", "SLIDER", [200, 1500, 0], 800],
    ["Waldo_AIPass_Flank_MaxRange", "Flank range (m)", "Enemies farther than this are not flanked.", "SLIDER", [100, 800, 0], 400],
    ["Waldo_AIPass_Morale_RetreatDistance", "Retreat distance (m)", "How far a broken squad falls back.", "SLIDER", [50, 500, 0], 200],
    ["Waldo_AIPass_ZeusHoldSeconds", "Zeus hold (s)", "How long Cortex leaves a squad alone after Zeus edits it or opens its attributes. Selecting a squad for inspection does not interrupt it.", "SLIDER", [0, 600, 0], 120],
    // Support
    ["Waldo_AIPass_ContactReports_Radius", "Radio report range (m)", "How far squads pass sightings by radio.", "SLIDER", [0, 1500, 0], 500],
    ["Waldo_Cortex_CombinedArms_AirRange", "Aircraft support range (m)", "How far a radio-linked aircraft may accept a fresh combined-arms opportunity. This is independent of the shorter squad report radius.", "SLIDER", [500, 10000, 0], 4000],
    ["Waldo_AIPass_Reinforce_Radius", "Reinforcement radius (m)", "How far away idle squads may be sent to help.", "SLIDER", [100, 2000, 0], 600],
    ["Waldo_AIPass_Reinforce_MaxResponders", "Reinforcing squads", "Squads sent to help one squad in contact.", "SLIDER", [0, 5, 0], 2],
    ["Waldo_AIPass_Artillery_Bursts", "Burst limit", "Maximum HE bursts per mission; smoke uses one burst.", "SLIDER", [1, 5, 0], 3],
    ["Waldo_AIPass_Artillery_RoundInterval", "Within-burst interval (s)", "Minimum seconds between confirmed rounds inside one burst.", "SLIDER", [1, 15, 0], 2],
    ["Waldo_AIPass_Artillery_LocationResetDistance", "New location distance (m)", "Reported movement in metres that resets opening offset and safety checks.", "SLIDER", [50, 500, 0], 150],
    ["Waldo_AIPass_CounterBattery_RadarDelay", "Counter-battery: radar delay (s)", "Counter-battery acquisition seconds with radar coverage; capped by the normal delay.", "SLIDER", [1, 120, 0], 20],
    // Artillery support
    ["Waldo_AIPass_Artillery_Rounds", "Support: rounds per burst", "Rounds in each support burst. The burst limit caps the mission.", "SLIDER", [1, 10, 0], 3],
    ["Waldo_AIPass_Artillery_MaxError", "Support: accuracy needed (m)", "Largest target position error a squad may call fire on. Lower means fewer, more accurate missions.", "SLIDER", [10, 200, 0], 50],
    ["Waldo_AIPass_Artillery_Cooldown", "Support: cooldown (s)", "Cooldown after a finite support mission ends.", "SLIDER", [30, 600, 0], 120],
    ["Waldo_AIPass_Artillery_MinFriendlyDistance", "Support: safety distance (m)", "No mission lands this close to friendlies or civilians.", "SLIDER", [50, 500, 0], 200],
    ["Waldo_AIPass_Artillery_ShootAndScoot", "Support: shoot and scoot", "Mobile guns move after a support mission.", "CHECKBOX", [], true],
    ["Waldo_AIPass_Artillery_DefaultRole", "Default battery role", "Missions taken by guns without a role of their own.", "COMBO", [["BOTH", "SUPPORT", "COUNTER"], ["Support and counter-battery", "Support only", "Counter-battery only"]], "BOTH"],
    ["Waldo_AIPass_Artillery_OpeningSafeDistance", "Opening safety distance (m)", "Minimum commanded opening aim distance from the reported target and living players. Player positions are rejection-only.", "SLIDER", [100, 500, 0], 200],
    ["Waldo_AIPass_Artillery_OpeningBuffer", "Opening extra buffer (m)", "Additional room for ballistic spread and player movement. Live shells are not a guarantee of harmless impacts.", "SLIDER", [50, 300, 0], 100],
    ["Waldo_AIPass_Artillery_WarningInterval", "Ranging warning interval (s)", "Minimum pause after estimated impact before the next burst.", "SLIDER", [10, 60, 0], 20],
    // Counter-battery
    ["Waldo_AIPass_CounterBattery_Rounds", "Counter-battery: rounds per burst", "Rounds in each counter-battery burst; ranging changes between bursts.", "SLIDER", [1, 10, 0], 4],
    ["Waldo_AIPass_CounterBattery_Delay", "Counter-battery: delay (s)", "Acquisition delay without radar. Radar can shorten it.", "SLIDER", [1, 120, 0], 60],
    ["Waldo_AIPass_CounterBattery_Interval", "Counter-battery: interval (s)", "Cooldown after the finite response ends; a new firing event is needed.", "SLIDER", [10, 600, 0], 60],
    ["Waldo_AIPass_CounterBattery_MinFriendlyDistance", "Counter-battery: safety distance (m)", "No fire back when friendlies or civilians are this close to the enemy gun.", "SLIDER", [50, 500, 0], 200],
    ["Waldo_AIPass_CounterBattery_ShootAndScoot", "Counter-battery: shoot and scoot", "Mobile guns move after a counter-battery mission.", "CHECKBOX", [], true],
    // Airborne insertion
    ["Waldo_AIPass_Airborne_DeployDistance", "Airborne: jump distance (m)", "AI passengers jump when their aircraft is this close to a known enemy.", "SLIDER", [200, 2000, 0], 700],
    ["Waldo_AIPass_Airborne_Altitude", "Airborne: jump altitude (m)", "Height the aircraft climbs to for the drop.", "SLIDER", [150, 600, 0], 250],
    ["Waldo_AIPass_Airborne_MinAltitude", "Airborne: lowest jump (m)", "Never jump lower than this.", "SLIDER", [80, 300, 0], 120]
];
// Section metadata keeps each switch beside its related tuning fields in one control module.
_spec apply {
    private _name = _x select 0;
    private _section = switch (true) do {
        case (_name find "Artillery" >= 0 || {_name find "CounterBattery" >= 0}): {"ARTILLERY"};
        case (_name find "Airborne" >= 0 || {_name find "Aircraft" >= 0} || {_name find "AttackRunFlares" >= 0}): {"AIR"};
        case (_name find "Vehicle" >= 0 || {_name find "Convoy" >= 0}): {"VEHICLES"};
        case (_name find "Reinforce" >= 0 || {_name find "Coordinated" >= 0} || {_name find "ContactReports" >= 0} || {_name find "AmmoShare" >= 0}): {"SUPPORT"};
        case (_name find "Morale" >= 0 || {_name find "Retreat" >= 0} || {_name find "Surrender" >= 0} || {_name find "Regroup" >= 0}): {"MORALE"};
        case (_name find "Flank" >= 0 || {_name find "Advance" >= 0} || {_name find "Assault" >= 0} || {_name find "StreetCrossing" >= 0} || {_name find "CoverValidation" >= 0}): {"MOVEMENT"};
        case (_name find "Contact_" >= 0 || {_name find "PostContact" >= 0} || {_name find "Investigate" >= 0} || {_name find "Hearing" >= 0} || {_name find "FireControl" >= 0} || {_name find "Grenade" >= 0} || {_name find "AntiArmour" >= 0} || {_name find "Stance" >= 0}): {"CONTACT"};
        case (_name find "CivilianReaction" >= 0): {"REACTIONS"};
        default {"GENERAL"};
    };
    _x + [_section]
}
