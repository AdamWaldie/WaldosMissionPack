/*
 * Author: Waldo
 * Registers all WMP briefing and reference entries in the player's map diary - radio
 * reports (SPOTREP/SITREP/ACEREP), checklists (LZ specs/insert/extract/brief, jumpmaster,
 * rotary pickup) and support-call formats (CFF, CAS check-in, 9-line, gunship, fire commands)
 * - by creating the diary subjects and calling each individual document function. Called from
 * init.sqf via Waldo_fnc_AddDocs; runs client-side on the player.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * call Waldo_fnc_AddDocs;
 */

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