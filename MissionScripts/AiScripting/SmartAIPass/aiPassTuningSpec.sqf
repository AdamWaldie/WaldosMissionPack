/*
 * Author: WaldoTheWarfighter
 * The list of Smart AI Pass difficulty and tuning settings that can be changed during a mission.
 *
 * One list feeds the AI Tuning Zeus dialog, the validation in Waldo_fnc_AIPassTuning and the
 * snapshot joining headless clients request, so the three cannot drift apart. Every setting is read
 * live by the behaviours, so a change takes effect on each squad's next step. Defaults are the
 * MissionConfig\aiConfig.sqf values.
 * Locality and authority: read-only; callable anywhere.
 *
 * Repeat/JIP: current feature gates and eligibility are rechecked; owner jobs are retired on migration.
 * Arguments:
 * None
 *
 * Return Value:
 * Array of [variable, label, tooltip, kind, options, default]:
 * - kind "SLIDER": options [min, max, decimals]
 * - kind "CHECKBOX": options []
 * - kind "COMBO": options [values, labels]
 *
 * Example:
 * private _variables = ([] call Waldo_fnc_AIPassTuningSpec) apply {_x select 0};
 * Result: every tunable Smart AI Pass variable name.
 *
 * Current callers: Waldo_fnc_AIPassTuning, Waldo_fnc_FeatureRuntimeZen (AI Tuning) and
 * Waldo_fnc_FeatureRuntimeRequestState.
 */

private _profiles = ["", "MILITIA", "LINE", "VETERAN", "ELITE"];
private _profileLabels = ["Follow the AI Rebalance profile", "Militia", "Line", "Veteran", "Elite"];
{
    if !(_x in _profiles || {_x in ["LEGACY", "PUBLIC", "STANDARD"]}) then {_profiles pushBack _x; _profileLabels pushBack _x};
} forEach keys (missionNamespace getVariable ["Waldo_AIPass_ProfileBehaviour", createHashMap]);

[
    ["Waldo_AIPass_VehicleDismount_Enable", "Vehicle contact dismount", "Unloads capable passengers only when safely stopped on dry ground.", "CHECKBOX", [], true],
    ["Waldo_AIPass_VehicleRemount_Enable", "Vehicle remount", "Allows safe conscious passengers to reboard after Smart AI contact. Convoy resume stays explicit.", "CHECKBOX", [], true],
    ["Waldo_AIPass_VehicleWithdraw_Enable", "Vehicle withdrawal", "Allows damaged vehicles to withdraw and use existing smoke.", "CHECKBOX", [], true],
    ["Waldo_AIPass_CoverValidation_Enable", "Additional cover checks", "Adds bounded slope and body clearance checks to shared cover selection.", "CHECKBOX", [], true],
    ["Waldo_Convoy_MountedFire_Enable", "Convoy mounted targeting", "WMP assigns targets to weapon crew under existing ROE. Disable to leave targeting to another AI mod.", "CHECKBOX", [], true],
    ["Waldo_Convoy_Cover_Enable", "Convoy passenger cover", "Issues the finite cover move after an ambush dismount.", "CHECKBOX", [], true],
    ["Waldo_Convoy_AvoidInfantry_Enable", "Convoy infantry avoidance", "Optional short-range friendly infantry corridor checks before driving.", "CHECKBOX", [], false],
    ["Waldo_Convoy_ContactHalt_Enable", "Convoy contact halts", "Automatic ambush halt using push-through and pinned rules. Route arrival and explicit stop remain available.", "CHECKBOX", [], true],
    ["Waldo_Convoy_Unload_Enable", "Convoy cargo unloading", "Allows WMP passenger unloading on halt. Operating crews remain aboard.", "CHECKBOX", [], true],
    ["Waldo_AIPass_Hearing_Enable", "Nearby gunfire investigation", "Optional FiredNear awareness within the engine event range. Records an uncertain area, never a target reveal. Disabled by default.", "CHECKBOX", [], false],
    // Squad behaviour
    ["Waldo_AIPass_BehaviourProfile", "Behaviour profile", "Tactics profile for every squad without a group or faction profile of its own. Skill values are not changed.", "COMBO", [_profiles, _profileLabels], ""],
    ["Waldo_AIPass_Aggression", "Aggression", "Scales how often squads flank, assault, advance, investigate and join coordinated assaults. 1 is the profile's own value, 0 never, 2 twice as often.", "SLIDER", [0, 2, 2], 1],
    ["Waldo_AIPass_Cohesion", "Cohesion", "How much punishment squads take before morale breaks. Above 1 they hold longer, below 1 they break sooner.", "SLIDER", [0.5, 2, 2], 1],
    ["Waldo_AIPass_ReactionSpeed", "Reaction speed", "How often squads re-assess. Above 1 they react faster and use more server time; below 1 slower.", "SLIDER", [0.5, 2, 2], 1],
    ["Waldo_AIPass_EngageRange", "Engagement range (m)", "Known enemies within this range of a squad leader are acted on.", "SLIDER", [200, 1500, 0], 800],
    ["Waldo_AIPass_Flank_MaxRange", "Flank range (m)", "Enemies farther than this are not flanked.", "SLIDER", [100, 800, 0], 400],
    ["Waldo_AIPass_Morale_RetreatDistance", "Retreat distance (m)", "How far a broken squad falls back.", "SLIDER", [50, 500, 0], 200],
    ["Waldo_AIPass_ZeusHoldSeconds", "Zeus hold (s)", "How long the pass leaves a squad alone after Zeus selects or edits it.", "SLIDER", [0, 600, 0], 120],
    // Support
    ["Waldo_AIPass_ContactReports_Radius", "Radio report range (m)", "How far squads pass sightings by radio.", "SLIDER", [0, 1500, 0], 500],
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
]
