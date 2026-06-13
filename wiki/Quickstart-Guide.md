## **Step 1: Download Required Files**
- Download the [latest Waldos Mission Pack](https://github.com/AdamWaldie/WaldosMissionPack/releases/latest) (labelled as WMP-VersionNumber.zip) & the accompanying compositions.

## **Step 2: Setup Your Development Environment**
- It is recommended that you download Visual Studio Code and its SQF plugins, as they will make script reading in Arma 3 easier.
  - [Visual Studio Code](https://code.visualstudio.com/)
  - [SQF Language Extension](https://marketplace.visualstudio.com/items?itemName=vlad333000.sqf)
  - [SQF Debugger Extension](https://marketplace.visualstudio.com/items?itemName=billw2011.sqf-debugger)

## **Step 3: Prepare Your Mission Folder**
- Copy everything from the downloaded folder into your mission.
- Ensure that the `mission.sqm` is unbinarized:
  - Navigate to Attributes -> General -> under Misc and uncheck the "Binarize the scenario file" box.

## **Step 4: Customize Your Mission**
- Fill out the relevant information in `description.ext` as desired. Optionally, replace the `loading.jpg` image in the Pictures folder.

## **Step 5: Configure AI Behavior**
- Set Waldo's AI Tweak mode in the `init.sqf` (DAY or NIGHT modes) as labelled in the `init.sqf` file.

## **Step 6: Edit Initialization Files**
- Edit `init.sqf`, `initServer.sqf`, & `initPlayerLocal.sqf` as you like to enable/disable different aspects of the pack.

## **Explore The Mission Framework For Things You Might Want To Use (Optional)**
- The pack is "packed" full of scripts and helpers for you to utilise. Every script is heavily documented and provides example calls for you to quickly and easily understand and use.

***

### **If Using ACE 3:**
- Disable ACE 3 Respawn in server & Mission Addon Settings (Settings -> Addon Settings -> ACE Respawn).
- See [Loadout Saving and Respawn](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Loadout-Saving-and-Respawn) for more details.

***

### **If Using ACRE2:**
- Player groups must be assigned a callsign (Click on the group -> Callsign) & have that callsign and radio frequencies assigned in `init.sqf`.
- See [ACRE 2 Radio Presetting And Saving](https://github.com/AdamWaldie/WaldosMissionPack/wiki/ACRE-2-Long-Range-Radio-Presetting) for more details.

# Additional Resources

## **Full Pack Features:**
- This quickstart guide sets up the bare minimum. For a comprehensive look at using the pack’s features, reference [Feature Tutorials](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Feature-Tutorials).

## **Compositions:**
- Several compositions are supplied via a separate download on the release page. These expedite your mission building process, including setting up the pack's arsenal, supply crate, and logistics systems.

### **Composition Installation:**
1. Download `WMP_Compositions-versionNumber.zip` (E.g `WMP_Compositions-v4.6.1.zip`) from the [latest release](https://github.com/AdamWaldie/WaldosMissionPack/releases/latest) and open it.
2. Navigate to your Arma 3 Profile folder in your documents.
3. Open your `Compositions` folder.
4. Drag and drop the contents from the downloaded compositions folder into your `Compositions` folder.
5. If you have an older version of the compositions, it is wise to delete them first and then copy across the new compositions.
