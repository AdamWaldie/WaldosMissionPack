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
    // Artillery support
    ["Waldo_AIPass_Artillery_Rounds", "Support: rounds", "Rounds per fire mission called by a squad.", "SLIDER", [1, 10, 0], 3],
    ["Waldo_AIPass_Artillery_MaxError", "Support: accuracy needed (m)", "Largest target position error a squad may call fire on. Lower means fewer, more accurate missions.", "SLIDER", [10, 200, 0], 50],
    ["Waldo_AIPass_Artillery_Cooldown", "Support: cooldown (s)", "Time between missions called by one squad.", "SLIDER", [30, 600, 0], 120],
    ["Waldo_AIPass_Artillery_MinFriendlyDistance", "Support: safety distance (m)", "No mission lands this close to friendlies or civilians.", "SLIDER", [50, 500, 0], 200],
    ["Waldo_AIPass_Artillery_ShootAndScoot", "Support: shoot and scoot", "Mobile guns move after a support mission.", "CHECKBOX", [], true],
    ["Waldo_AIPass_Artillery_DefaultRole", "Default battery role", "Missions taken by guns without a role of their own.", "COMBO", [["BOTH", "SUPPORT", "COUNTER"], ["Support and counter-battery", "Support only", "Counter-battery only"]], "BOTH"],
    // Counter-battery
    ["Waldo_AIPass_CounterBattery_Mode", "Counter-battery: detection", "Known: only enemy guns a squad has located. Radar: also guns in range of a registered radar.", "COMBO", [["KNOWN", "RADAR"], ["Known positions only", "Known positions and radar"]], "KNOWN"],
    ["Waldo_AIPass_CounterBattery_Rounds", "Counter-battery: rounds", "Rounds fired back at an enemy gun.", "SLIDER", [1, 10, 0], 4],
    ["Waldo_AIPass_CounterBattery_MaxError", "Counter-battery: accuracy needed (m)", "Largest position error on the enemy gun accepted in Known mode.", "SLIDER", [10, 300, 0], 100],
    ["Waldo_AIPass_CounterBattery_Delay", "Counter-battery: delay (s)", "Time before fire is returned.", "SLIDER", [0, 120, 0], 20],
    ["Waldo_AIPass_CounterBattery_Interval", "Counter-battery: interval (s)", "Time before the same enemy gun is answered again.", "SLIDER", [10, 600, 0], 60],
    ["Waldo_AIPass_CounterBattery_MinFriendlyDistance", "Counter-battery: safety distance (m)", "No fire back when friendlies or civilians are this close to the enemy gun.", "SLIDER", [50, 500, 0], 200],
    ["Waldo_AIPass_CounterBattery_ShootAndScoot", "Counter-battery: shoot and scoot", "Mobile guns move after a counter-battery mission.", "CHECKBOX", [], true],
    // Airborne insertion
    ["Waldo_AIPass_Airborne_DeployDistance", "Airborne: jump distance (m)", "AI passengers jump when their aircraft is this close to a known enemy.", "SLIDER", [200, 2000, 0], 700],
    ["Waldo_AIPass_Airborne_Altitude", "Airborne: jump altitude (m)", "Height the aircraft climbs to for the drop.", "SLIDER", [150, 600, 0], 250],
    ["Waldo_AIPass_Airborne_MinAltitude", "Airborne: lowest jump (m)", "Never jump lower than this.", "SLIDER", [80, 300, 0], 120]
]
