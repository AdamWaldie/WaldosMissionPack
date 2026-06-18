/*
 * Author: Waldo
 * Adds the 5-line gunship brief format reference to the player's map diary.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * call Waldo_fnc_FIVELINEGUNSHIP;
 */

player createDiaryRecord["Support Calls",
    ["5-Line Gunsip Support",
        "
<img image='MissionScripts\MissionInit\BriefingDocuments\BriefImages\5LINEGUNSHIP.jpg' width='400' height='587'/>
        "
    ]
];