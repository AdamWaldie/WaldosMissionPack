/*
 * Author: WaldoTheWarfighter
 * Opens a plain-language ZEN control for the global AI helicopter landing system. All values are
 * bounded selectors; Zeus never enters engine command names or internal object ids.
 *
 * Arguments: None (ZEN placement payload is intentionally ignored).
 *
 * Return Value: Nothing.
 *
 * Example: [] call Waldo_fnc_ImprovedHelicopterLandingZen;
 * Current caller: AI - Helicopter Landing Control in Zen_initModules.sqf.
 */

if !(hasInterface && {isClass (configFile >> "CfgPatches" >> "zen_dialog")}) exitWith {};
[
    "AI - Improved Helicopter Landing",
    [
        ["CHECKBOX", ["Enabled", "Applies only to AI-piloted helicopters, including editor, Zeus and headless-client aircraft."], missionNamespace getVariable ["Waldo_ImprovedHelicopterLanding_Enable", true]],
        ["SLIDER", ["Minimum activation distance", "Never take over a landing waypoint closer than this; minimum 50 metres protects take-off tasks."], [50, 500, missionNamespace getVariable ["Waldo_ImprovedHelicopterLanding_MinimumActivationDistance", 50], 0]],
        ["SLIDER", ["Transit height", "Minimum terrain-relative approach height before descent."], [15, 150, missionNamespace getVariable ["Waldo_ImprovedHelicopterLanding_TransitAltitude", 30], 0]],
        ["SLIDER", ["Glideslope length", "Higher values begin descent farther from the landing point."], [2, 10, missionNamespace getVariable ["Waldo_ImprovedHelicopterLanding_GlideSlopeRatio", 4], 1]],
        ["SLIDER", ["Tree scan radius", "Area around the landing point checked for nearby tree canopies."], [0, 75, missionNamespace getVariable ["Waldo_ImprovedHelicopterLanding_TreeScanRadius", 25], 0]],
        ["SLIDER", ["Canopy clearance", "Extra hover height maintained above the detected canopy."], [0, 25, missionNamespace getVariable ["Waldo_ImprovedHelicopterLanding_TreeSafetyBuffer", 5], 0]],
        ["SLIDER", ["Go-around height", "Relative height considered too high inside the final approach area."], [50, 500, missionNamespace getVariable ["Waldo_ImprovedHelicopterLanding_GoAroundHeight", 150], 0]],
        ["SLIDER", ["Maximum climb rate", "Caps scripted upward velocity to avoid excessive collective."], [1, 20, missionNamespace getVariable ["Waldo_ImprovedHelicopterLanding_MaximumClimbRate", 8], 1]],
        ["SLIDER", ["Maximum descent rate", "Caps scripted downward velocity during approach."], [1, 25, missionNamespace getVariable ["Waldo_ImprovedHelicopterLanding_MaximumDescentRate", 10], 1]],
        ["SLIDER", ["Maximum go-arounds", "Zero disables go-arounds; higher values allow another stabilised approach."], [0, 3, missionNamespace getVariable ["Waldo_ImprovedHelicopterLanding_MaximumGoArounds", 1], 0]]
    ],
    {
        params ["_values"];
        [_values] remoteExecCall ["Waldo_fnc_ImprovedHelicopterLandingConfigureServer", 2];
    },
    {}
] call zen_dialog_fnc_create;
