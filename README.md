# WaldosMissionPack
A package of mission scripts for mission makers designed to be highly flexible, automated and as easy as possible for any mission makers to interact with.

![alt text](https://github.com/AdamWaldie/WaldosMissionPack/blob/main/Pictures/loading.jpg?raw=true)

**If you find this mission pack inside a mission, please do not utilise it. Mission Makers like to customise the pack. Download the Missionpack Folder (WMP_Version_Number_Here.zip) from github: https://github.com/AdamWaldie/WaldosMissionPack/releases/latest**

# Background Information
- This project was created originally for the mission makers of the Rooster Teeth Gaming Discord, with the intent to provide them with the easiest possible method 
to utilise critical systems of arma 3. Now, it is in continued use by at least forty known units, from all corners of the milsimsphere.
- Basic mission setup can be achieved easily through editing the supplied description.ext, and various Init files while the more interesting features can be set up by following the indepth documentation in each file.
- All features are functionalised, and simply require a function call as directed in the files themselves to work.
- All functions follow the follwing Syntax "Waldo_fnc_FunctionName", you may find a full list of these in WaldosFunctions.sqf.

# Pack Features
- Loadout saving and respawn system
- Automatic ACRE2 Radio setup and respawn handling - based on mission makers specification in init.sqf
- Custom loadout & logistics system which scrapes the kits of all playable characters to fulfil base logistical needs - such as starter crates and supply crates. (Disable scenario Binarization, and edit loadouts via ACE Arsenal to ensure 100% satisfaction)
- Vehicle Ambush/Camo scripts.
- Vehicle unflipping actions
- Simple AI convoy script expanded and enhanced from Tovas original.
- Teleportation Script
- Endex & Safestart Scripts
- Custom Zeus Enhanced modules for in-game access to the logistics system and ENDEX scripts.
- HALO & Static Line Jump Scripts with equipment & weapon loss simulation.
- [WIP] Virtual Vehicle Deployment Garage
- Extensively documented files to learn how it works, and make use of this pack!
- Mission Pack Compositions to hasten the learning and mission building process


# QuickStart Guide
You can always find the most recent quickstart guide at this URL: https://github.com/AdamWaldie/WaldosMissionPack/wiki/Quickstart-Guide

# Other Information
- All files are provided with description on their utilisation and purpose.
- initPlayerLocal.sqf utilises CBA eventhandlers to provide respawn loadout saving/loading. You can choose whether to respawn with starting equipment, or what they died with in that file.
- Its recommended that you download Visual Studio Code & Its SQF plugins. Itll make any script reading in Arma 3 easier on you! 
    - Visual Studio Code: https://code.visualstudio.com/
    - SQF Language Extension: https://marketplace.visualstudio.com/items?itemName=vlad333000.sqf
    - SQF Debugger Extension: https://marketplace.visualstudio.com/items?itemName=billw2011.sqf-debugger

# Required Addons
- CBA_A3
- ACE 3 (Field Headquarters, Construction System, Quartermaster Logistics Spawner)

# Supported Addons
- ACRE 2 (You can disable this via init.sqf)
- TFAR (Inherrent support via 3Eden)
- Zeus Enhanced & Compat
- LAMBS Series of mods (Tutorial Mission Requires this, the pack can work without it)
- All unit mods compatable

# Credits
- Waldo - Lead Developer
- RazzMaTazz - Original Cover Image
- Val - Top Contributer
