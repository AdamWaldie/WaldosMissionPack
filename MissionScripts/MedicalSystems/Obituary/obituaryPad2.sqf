/*
 * Author: WaldoTheWarfighter
 * Zero-pads a number to two digits for HH:MM-style timestamp formatting (e.g. 5 -> "05").
 * Locality and authority: pure helper, no side effects; safe to call on any machine.
 *
 * Arguments:
 * 0: Value <NUMBER> - the number to pad
 *
 * Return Value:
 * String - the two-digit zero-padded value
 *
 * Example:
 * [5] call Waldo_fnc_ObituaryPad2;
 * Result: "05"
 * Current caller: Waldo_fnc_ObituaryPronounce, formatting discovery/death timestamps.
 */

params ["_n"];
if (_n < 10) then { "0" + str _n } else { str _n }
