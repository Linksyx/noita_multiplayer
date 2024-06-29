# noita_multiplayer
A local Noita Multiplayer mod that can be used locally and remetely (with Parsec for example) with several sets of mice and keyboards and which features 2-3-4 players splitscreen and no limit on shared screen. Upcoming in order: 1. fix for inventory issues (very problematic at more than 2 players), 2. add the last remaining controls (hotbar quickswith, etc), 3. fix polymorphine supports some cases, 4. player skins and, 5. Parsec-like system to send full screens to each player.

For help, suggestions and bug report message or ping @linksyx on the Noita official discord.

To setup:
put the multiplayer folder into .../Noita/mods
enable unsafe mods in the mod menu
activate and preferably put this mod high in the mod order
in the vanilla control pannel, map the "select item in slot X" to something unused (there is problematic hardcoded functionnality to it) and set "Pause the game when unfocused" to disabled.
check mod settings to make sure it's what you want. Polymorphine can still break the mod in some particular situations and can be disabled for players if wanted. Experimental zoom out options can be useful for splitscreen but can increase lag.

To control the players:
Details are available in USER/LOCAL and USER/REMOTE folders but for a TLDR:
settings.json have to be modified the enter the player id, player controls and the ip/port to use. The syntax of this file depends on wether you are in REMOTE or LOCAL, and is explained in the associated README.
If there is at least one remote player who is not on LAN, you have to open the port you decide to use for UDP (default being 25565).
If you are a remote player, you need to put the local ipv4 (192.xxxx available with "ipconfig" in the cmd) of the host in settings if you are on LAN and the public one if you are not on LAN (most cases).
If, on one computer, you are playing alone use the script in REMOTE (even for the host).
If, on one computer, you are several players, use the script in local (for both the host or even a remote player if you like strange setups).

I know the names are confusing, and I am open to suggestions to make them clearer.
The general idea is that in REMOTE the script used is simple and returns the inputs from all devices combined and the mouse position while the script in LOCAL uses the PluralInput API which allows to differentiate inputs from different devices on the same computer, but returns mouse movements and not the position, making it unprecise.

On windows, for Parsec, use build 150-95 or above if available or use the portable (not installed one) instead if not.
On Linux, there is no script yet in LOCAL but you can still use the python script directly in REMOTE/before_compile (requires putting a settings.json next to it).

Notes:
The inventory is currently bugged. For 2 players, if they overlap throw a wand on the ground and grab it back. For more, there is no fix. For now, the host has to do most of the inventory work including choosing grabbed wands slots and wand tinkering. For skins, they are not implemented yet but there is an important chance that existing skin mods will affect only player 1 or affect only partially other players, making them useful for differentiation at 2 players on shared screen mod. If there is a lot of corruption (ex: Holy Mountains not spawning) you should disable the experimental zoom out options in mod options or lower the number of players or try to fix it in the mod yourself by touching at the STREAMING_CHUNK_TARGET (default 12) magic number (edit the existing code that's modifying it on the go).
