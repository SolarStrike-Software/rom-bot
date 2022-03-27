# RoM-Bot

RoM-Bot is a C++ and Lua-powered simplistic bot for Runes of Magic.
This project is intended for learning and research; you should expect to
dig into the code and configure things rather than simply click some buttons.

# Setup

1. Download and extract [MicroMacro](https://solarstrike.net/project/micromacro)
2. Download and extract the [RoM-bot scripts](https://github.com/SolarStrike-Software/rom-bot/archive/refs/heads/master.zip) to `micromacro/scripts`
    - If you did this correctly, you should see this file as `micromacro/scripts/rom-bot/readme.md`
3. Create a copy of `profiles/Default.xml`. Name it after your character instead of 'Default'
    - Example: If your character is named "Bob", name this file `Bob.xml` and place it in the `profiles` folder.
4. Modify your character profile -- modify the options to your liking, add skills, etc.
5. Copy the folders in `micromacro/scripts/rom-bot/devtools/` to `.../RunesOfMagic/interface/addons/`
    - If the `interface` or `addons` directories don't exist, you may have to create them.
    - Use whichever folder you installed ROM to. Example: `C:\Program Files (x86)\GameforgeClient\Games\RunesOfMagic\interface\addons`
6. Open `micromacro.exe` and try entering this command: `rom-bot/bot`
    - If all is set up correctly, the bot should start up and prompt you for more details

# Updating

## Use the updater tool
The easiest approach is to simply run the `rombot_updater.exe`. This will
automatically update all of your RoM-Bot files.

## Do it manually
Alternatively, you can always download a fresh copy of the latest RoM-Bot scripts
[as a .zip package](https://github.com/SolarStrike-Software/rom-bot/archive/refs/heads/master.zip).
Extract, then copy and paste these files over top of your existing RoM-Bot
scripts; **Overwrite all files**.

## Update over Git
If you have `git` installed, you may use the command `rom-bot/gitupdate` to attempt to merge local changes with upstream.
