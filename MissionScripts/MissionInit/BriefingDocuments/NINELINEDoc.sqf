/*
 * Author: Waldo
 * Adds the 9-line MEDEVAC request format reference to the player's map diary.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * call Waldo_fnc_NINELINE;
 */

player createDiaryRecord["Support Calls",
    ["9-Line CAS",
        "
<img image='MissionScripts\MissionInit\BriefingDocuments\BriefImages\9LINE.jpg' width='400' height='587'/>
        "
    ]
];