/*
 * Author: Waldo
 * Adds the CAS (close air support) check-in format reference to the player's map diary.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * call Waldo_fnc_CASCHECKIN;
 */

player createDiaryRecord["Support Calls",
    ["CAS CHECK IN",
        "
<img image='MissionScripts\MissionInit\BriefingDocuments\BriefImages\CASCHECKIN.jpg' width='400' height='587'/>
        "
    ]
];