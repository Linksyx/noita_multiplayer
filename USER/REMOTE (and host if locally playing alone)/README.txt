The REMOTE USER folder has to be sent to every player. The host need it to as vanilla player controls are disabled. Settings are defaulted for the host

------------------------------ To send inputs to the host:
To change settings (necessary at first) and controls open settings.json
When inside:

--For connection settings:
server_address:
If on local (you are the host) then keep "localhost"
If on LAN then ask the host to open CMD, type ipconfig and give you his IPv4 address. You need to put it between "" without spaces
If outside of LAN, ask the host to give you his public IPv4 address (he can get it there https://whatismyipaddress.com/). You need to put it between "" without spaces

server_port:
Choose a port to send the data through. The host must have forwarded it to accept UDP datagrams (you can easily find a guide how to do that for your router online). It should be between 1024 and 49151. The default value, 25565 is Minecraft's server hosting port and may already be opened for a lot of people.

player_id:
It is the number associated to the player you want to play. The host should choose 1 and each player have a different one

sending_sleep:
It is, in second, the delay between each datagram is sent to the host. If it works well with the default value, don't change it. For reference, the game is running at 60 fps (60/number of players for splitscreen actually) which means two frames are separated by about 0.017s.

invert_scroll:
Invert the default scrolling wheel rotation if set to true.

--For controls:

The left value is the key/button that is pressed. One key may only appear once.
To modify a key, change it to 'key' (with the ' ') for basic keys and to keyboard.Key.xxxx (keyboard) (full list found here https://speedsheet.io/s/pynput#SmLf), or mouse.Button.xxxx (left, right, middle, x1 for lower thumb (windows), x2 for upper thumb (windows) ) without any ' '. Do not use Sup/Delete which quits

The right value, between [], represents the actions. All possible actions are assigned to something in the default settings.
If you want a key to do several actions, change the line to something like that: "key": ["action1","action2"] (more actions possible)

COMING SOON: Quick inventory slots and when inventory is revamped quick spell equip/unequip

When you've setup your settings.json you can start send_inputs.exe. Avoid clicking inside the console, it will cause great lag. If you do, just press escape, click outside or alt+f4 and restart it.



------------------------------ To see the screen:
To see the host's screen (and play) you can use screen share software but some are a lot better than others. Here are 3 you can consider for a playable experience: 
--Option 1: Parsec (the best for Windows)
The host can simply install it from https://parsec.app/downloads. When the players will be connected, he can then disable their Parsec controls, controls being handled by send_inputs.exe
The other players must have specific versions of Parsec: either the portable app near the bottom of https://parsec.app/downloads (or directly https://builds.parsec.app/package/parsec-flat-windows.zip) or the normal download if Build 150-95 has rolled out (Should be by July or now from random rolling of it).

--Option 2: Rust Desk (all platforms)
Rust Desk is very straightforward and can be used in a portable version. You can get it there https://rustdesk.com/. The host has to put the app in Screen Share mode.

--Option 3: Steam Remote Play (partially broken)
While Steam Remote Play isn't normally available for Noita, Remote Play Whatever (https://github.com/m4dEngi/RemotePlayWhatever) allows to use it nonetheless... sometimes. Then, it has quality comparable to Parsec but has a ghost cursor that can break every player cursors. If you want to tinker a bit, it should be possible to make it work.


------------------------------ Notes on usage
For now, only the host has control of the pause menu and inventory. He his the one who has to choose where go picked wands for everyone, and wand tinkering (while players have to open their inventory themselves).
Known issues:
Unwanted actions - For example firing the held wand when clicking in menus
Inventory messed up after respawn - Fix: Throwing and grabing a wand
Inventory and health stacking on each up for more than 2 players - Fix: Don't do more than 2 players
Host can't pickup spells and sometimes items - Fix: have other players throw most of their items and grab it later or make other players buy and keep spells
Flickering on a dead player half screen - Fix: revive it!
Strange character hand movements when cursor near it


------------------------------ Troubleshooting
If send_inputs.exe shows in its console message on the form "player_id action value" (meaning it works) on a valid player_id (see Mod settings menu for the host) but the in game character isn't affected, it is probably because connection settings aren't correct or the used port isn't forwarded to UDP on the host's router.
If in game chracters seem to be broken mid-game, it's either polymorphine which can break them in some "uncommon" cases (you can disable polymorphing in mod settings if you are worried) or congrats, you have found a new bug!
If the game lags, you either have too much players, are using the zoom out option are have arrived at the limit of what your computer can handle.
If you have any question or bug to report, contact me @linksyx on Noita's official discord

