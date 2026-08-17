/*
 * WMP Headless Client Kit - headlessConfig.examples.sqf
 *
 * NOT loaded by any mission - this is not a #include-able config file, it is a reference sheet.
 * Copy the block you want and paste its rows over the matching rows in your mission's own
 * MissionConfig\headlessConfig.sqf. Do not add this file to WaldosFunctions.sqf, description.ext,
 * or featureConfigManifest.sqf - it has no header contract of its own and is not part of the pack.
 *
 * Both examples below only change the three ADVANCED TUNING rows (StartDelaySeconds,
 * MinGroupAgeSeconds, MigrationPaceSeconds) - Waldo_Headless_Enable and Waldo_Headless_Debug are
 * left as the shipped defaults (false) since those are mission-maker choices, not pacing tuning.
 * See MissionConfig\headlessConfig.sqf's own header for what each of these three values does.
 */

// ---------------------------------------------------------------------------------------------
// CONSERVATIVE - a good starting point for your FIRST headless-client test on a new mission.
// Waits longer before migrating anything, and spaces migrations further apart, so it is easier to
// watch what happens one step at a time in RPT/Diagnostics without a burst of simultaneous moves.
// ---------------------------------------------------------------------------------------------
["Waldo_Headless_StartDelaySeconds", 60],   // wait a full minute after mission start before anything migrates
["Waldo_Headless_MinGroupAgeSeconds", 20],  // give spawner scripts extra time to finish configuring a group
["Waldo_Headless_MigrationPaceSeconds", 5], // one migration every 5 seconds, easy to follow in RPT

// ---------------------------------------------------------------------------------------------
// AGGRESSIVE - for a large, already-tested AI population where you want groups offloaded to the
// headless client quickly rather than trickling over the first few minutes of the mission.
// ---------------------------------------------------------------------------------------------
["Waldo_Headless_StartDelaySeconds", 15],   // still leaves other AI-setup scripts a short head start
["Waldo_Headless_MinGroupAgeSeconds", 5],   // shorter settle time - only safe once you trust your spawners
["Waldo_Headless_MigrationPaceSeconds", 1], // move a queued group roughly once per second
