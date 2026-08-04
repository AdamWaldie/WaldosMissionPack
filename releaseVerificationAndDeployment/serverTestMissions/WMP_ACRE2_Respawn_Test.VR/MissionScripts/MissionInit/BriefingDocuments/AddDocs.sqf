/*
 * Author: WaldoTheWarfighter
 * Registers all WMP briefing and reference entries in the player's map diary - radio
 * reports (SPOTREP/SITREP/ACEREP), checklists (LZ specs/insert/extract/brief, jumpmaster,
 * rotary pickup) and support-call formats (CFF, CAS check-in, 9-line, gunship, fire commands)
 * - by creating the diary subjects and calling each individual document function. Called after the
 * local player object exists from initPlayerLocal.sqf; dedicated servers and headless clients exit.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * BOOL - true when documents are present for the current local player object.
 *
 * Example:
 * call Waldo_fnc_AddDocs;
 */

if (!hasInterface || {isNull player}) exitWith {false};
if ((missionNamespace getVariable ["Waldo_BriefingDocumentsOwner", objNull]) == player) exitWith {true};

player createDiarySubject ["Radio Reports","Radio Reports"];
call Waldo_fnc_ACEREP;
call Waldo_fnc_SPOTREP;
call Waldo_fnc_SITREP;

player createDiarySubject ["Checklists","Checklists"];
call Waldo_fnc_LZSPECS;
call Waldo_fnc_LZEXTRACT;
call Waldo_fnc_LZINSERT;
call Waldo_fnc_ROTARYPICKUPREQUEST;
call Waldo_fnc_JUMPMASTER;
call Waldo_fnc_LZBRIEF;

player createDiarySubject ["Support Calls","Support Calls"];
call Waldo_fnc_CALLFORFIRE;
call Waldo_fnc_FIVELINEGUNSHIP;
call Waldo_fnc_CASCHECKIN;
call Waldo_fnc_NINELINE;

player createDiarySubject ["Preperation","Preperation"];
call Waldo_fnc_FIRECOMMANDS;
call Waldo_fnc_FIRETEAMPREPDOC;
call Waldo_fnc_SQUADPREDOC;

player createDiarySubject ["Player Information","Player Information"];
call Waldo_fnc_GENINFO;

// CEOI and planned Babel information are briefing documents too. These builders do not wait for
// live ACRE radio IDs, so enabled ACRE content is visible before the mission starts. Runtime ACRE
// application replaces the same records later with verified current state.
[] call Waldo_fnc_ACRE2BuildCEOI;
[] call Waldo_fnc_ACRE2BuildBabelDiary;
missionNamespace setVariable ["Waldo_BriefingDocumentsOwner", player];
diag_log format ["[WMP BRIEFING] Rich briefing documents installed for %1.", name player];
true
