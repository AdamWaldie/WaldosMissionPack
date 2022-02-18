# WaldosMissionPack
A package of mission scripts for new mission makers.

# missionParameters.sqf

This project was created originally for the mission makers of the Rooster Teeth Gaming Discord, with the intent to provide them with the easiest possible method 
to utilise critical systems of arma 3.

To this end, the majority of QOL & critical scripts can be utilised via the missionParameters.sqf file.

While this is more inefficent than directly tweaking each file, it does provide an easy method for new mission makers, or those less programatically inclined
to become aquanited with the scripting side of Arma 3.

# Required Steps To Utilse Scripts
1. Copy the contents of the WMP_VERSION folder into your user directory (This will provide you with an exemplar mission on Altis - utilising RHS.
2. Copy everything bar the mission.sqm from that folder into your mission
3. Fill out the relevant information in the description.ext
4. IF YOU ARE USING ACE 3:
   - Disable ACE 3 Respawn in server & mission addon settings.
5. IF YOU ARE USING ACRE2:
   - Player Groups MUST be given a Callsign in Eden & have their Callsign & radio frequiencies assigned in missionParameters.sqf.
6. Waldo's AI tweaks can be set via the missionParameters.sqf file.

# Other Information
- All files are provided with description on their utilisation, their parameters and how you can use them.
- missionParameters.sqf is heavily documented and should be worth a look.
- initPlayerLocal.sqf utilises CBA eventhandlers to provide respawn loadout saving/loading. You can choose whether to respawn with starting equipment, or what they died with in that file.

# Required Addons
- CBA_A3

# Supported Addons
- ACE 3
- ACRE 2 (You can disable this via missionParameters.sqf)
- TFAR (Inherrent support via 3Eden)
- LAMBS Series of mods (Tutorial Mission Requires this, the pack can work without it)
- All unit mods compatable
