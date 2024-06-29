--Important notes:
Check the README.txt in REMOTE too, it has complementary information.
If you are the host and just want to control player 1 use the send_inputs.exe and settings.json of the REMOTE folder instead, this one is only if you want to use multiple mice and keyboards on the same computer.
On the other side, you can be remote but would like to play with several mice and keyboard on the same computer. It is possible with this, but note that the quality of mouse movements is still a lot better in the REMOTE script.
The local send_inputs.exe is only for Windows for now. The REMOTE script can be used on Linux but may require to execute the .py in before_compile.

For each player you can copy the player_copiable, player1 or player2 folder and make a unique settings.json in each of them to set personnalised controls and controlled player number.
The only important files for you in the player folders are settings.json and send_inputs.exe.
You'll have to setup a settings.json and open a send_inputs.exe for each player.

-- For connection settings:
If playing locally keep the default ip address ("localhost" won't work it has to be "127.0.0.1"). For remote players you can set it to the host's public IPv4 address.
Modify the port to correspond to the one in game (in Mod settings). If you are not in local or LAN then the host will need to forward the port to UDP in his router's menu.

The player number correspond to the player you will control in game.
The mouse and keyboard identifiers correspond to which keyboard will be used on the computer. It's what allows the use of multiple mice and keyboards on a single computer.
You can get the identifier with identifier.exe which will print the source of any input. In the identifier, avoid clicking directly on the text.

Invert mouse scrolling if you feel like it.

-- Control notes:
Keys on the left can only appear once, so if you want a key to do multiple action you do it in this fashion: "Key": ["action1", "action2"] (more actions possible).
Actions on the right can be used as many times as you want. All available are originally mapped, so you can see their name.

-- To modify the left value in the settings:

Mouse valid buttons:
Left click: LeftButton
Right click: RightButton
Middle clock: MiddleButton
Thumb down: ExtraButton1
Thumb up: ExtraButton2

Keyboard valid buttons:
Basic keys: A, B, C... (in capital)
Arrow Keys: Left, Right, Down, Up
Special keys: Escape, Tab, CapsLock, Shift, Control, Delete, End, Next...
Other buttons: Use identifier.exe to find their name

-- In game notes:
As long as the inventory isn't reworked completely, some actions such as drinking from a flask, selecting a wand, wand tinkering or menu interaction are controlled by the main Windows cursor.
This cursor is affected by all mice of the host's computer, so menu interaction will be easier if only one player on the host's side moves their mouse.
For remote player, they'll just see a supplementary cursor hanging out, maybe requiring to only have one display screen, or lock it on Parsec's (or any low latency screen share app) window (possible by connecting the adjacent screens in diagonal in the Windows display settings)