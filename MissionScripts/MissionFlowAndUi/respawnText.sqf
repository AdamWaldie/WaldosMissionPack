/*
 * Author: WaldoTheWarfighter
 * Compact respawn location overlay - shows only mission time, date and the
 * player's current grid reference. Registered as Waldo_fnc_RespawnText.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] spawn Waldo_fnc_RespawnText;
 */

private _timeConfig = [dayTime, "ARRAY"] call BIS_fnc_timeToString; // Returns ingame time
private _time = (_timeConfig select 0) + (_timeConfig select 1) + ' hrs';
private _date =  str (date select 2) + '/' + str (date select 1) + '/' + str (date select 0); //Returns ingame Date. (Would ususally be in "_date")
// INFO TEXT >> Do not edit the below =============================================================================
private _localePos = 'Grid ' + mapGridPosition player; // Combo to give Eg - "Grid 061223".
waitUntil { sleep 1; (!isNull player && time > 0) };
sleep 1;
[
    [
        [_time, "<t align = 'center' shadow = '1' size = '0.7'>%1</t><br/>"],
        [_date, "<t align = 'center' shadow = '1' size = '0.6' font='PuristaBold'>%1</t><br/>"],
        [_localePos, "<t align = 'center' shadow = '1' size = '0.6'>%1</t><br/>", 10]
    ],
    -safezoneX + 0.2, ((safeZoneY + safeZoneH / 2) + 0.2)
] spawn BIS_fnc_typeText;
