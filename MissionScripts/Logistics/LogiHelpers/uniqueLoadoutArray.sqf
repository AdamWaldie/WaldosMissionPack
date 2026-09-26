/*
 * Author: WaldoTheWarfighter
 * Flattens a loadout array, removes duplicate entries and strips empty/non-string
 * values. Centralises the str -> parseSimpleArray -> arrayIntersect cleanup idiom used
 * by the mission.sqm scraper and the limited-arsenal builder so it lives in one place.
 *
 * Arguments:
 * 0: Array <ARRAY> - raw (possibly nested) array of classname strings
 *
 * Return Value:
 * Cleaned array <ARRAY> - flat, de-duplicated, no empty strings
 *
 * Example:
 * private _clean = [_rawWeapons] call Waldo_fnc_UniqueLoadoutArray;
 * Locality and authority: Stateless array cleanup on the caller; no server mutation or JIP
 * replay. Repeating it on the same array returns the same unique values.
 * Current callers: MissionSQMLookup and CreateLimitedArsenal.
 * Result: Empty and duplicate classnames are removed from the supplied list.
 */

params [["_arr", []]];

_arr = str _arr splitString "[]," joinString ",";
_arr = parseSimpleArray ("[" + _arr + "]");
_arr arrayIntersect _arr select {_x isEqualType "" && {_x != ""}}
