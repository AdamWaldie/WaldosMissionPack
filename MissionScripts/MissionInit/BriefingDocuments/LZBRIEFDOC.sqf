/*
 * Author: Waldo
 * Adds the landing-zone brief checklist to the player's map diary.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * call Waldo_fnc_LZBRIEF;
 */

player createDiaryRecord["Checklists",
    ["LZ Brief",
        "
<img image='MissionScripts\MissionInit\BriefingDocuments\BriefImages\LZBRIEF.jpg' width='400' height='587'/>
        "
    ]
];