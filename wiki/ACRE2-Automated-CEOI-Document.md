_Associated Files: MissionScripts\MissionInit\ACRE2\CreateACRECEOI.sqf_

This function takes available ACRE Radio information and documents it in a CEOI for the player to reference.
Covered:
- All LR channels and their denotation
- Highlighting of LR channels if the player's squad is noted as supposed to be on that net.
- AN/PRC-343 Block & Channel for the squad that the player is in.

Arguments:
_LRAssignments - from init.sqd via ACRE2Init.sqf - contains player squad LR channels from init.sqf ONLY.
_SquadCallsigns - from ACRE2Init.sqf - contains a list of callsigns only


Example:

Should only really be called from ACRE2Init.sqf and not manually.


## Setup

The below example CEOI will use the same setup as seen in the ACRE2 Long Range Radio & Short Range Radio Presetting documentation. See those for details.

Here is that for your reference: Each number is a Long Range Radio assignment for one of the following - 152,148,117F.
![image](https://i.imgur.com/3CHplvL.png)

Short range radio channels are automatically allocated based on the callsign defined in the section above.

Long Range channel names have to be provided manually per side. These are defined here:
![image](https://i.imgur.com/Mlnrkav.png)

Channel names are broken down per side, and side is automatically chosen based on the players own side.

The final CEOI looks like this:
![](https://i.imgur.com/kyYkNQo.jpg)

With the radio channels the player is preset on coloured in green.