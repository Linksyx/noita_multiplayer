from pynput import mouse, keyboard
import json
import socket
import os
from time import sleep, time

# Load the settings from the JSON file
with open('settings.json') as f:
    settings = json.load(f)

# Parse the settings
server_address = settings.get('server_address', 'localhost')
server_port = int(settings.get('server_port', 25565))
player_id = str(settings.get('player_id', 2))
sending_sleep = float(settings.get('sending_sleep', 0.005))
invert_scroll = settings.get('invert_scroll', False)

# Parse the controls
controls = {}
for key, actions in settings.get('controls', {}).items():
    if key.startswith('keyboard.Key.'):
        key = getattr(keyboard.Key, key.split('.')[-1])
    elif key.startswith('mouse.Button.'):
        key = getattr(mouse.Button, key.split('.')[-1])
    controls[key] = actions

# Create a UDP socket
client_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
print("Press Suppr/Delete to quit.\nClicking this application's console will lag for some reason.\nPress escape or click outside to stop lagging")
quit = False

accumulation = []
def on_press(key): 
    if key == keyboard.Key.delete: # Press Sup/Delete to quit
        mouse_listener.stop()
        keyboard_listener.stop()
        print("Closing")
        global quit
        quit = True
    else:
        try:
            actions = controls[key.char]
            for action in actions:
                msg = player_id + " " + action + " 1"
                accumulation.append(msg)
                print(msg)
        except AttributeError:
            if key in controls:
                actions = controls[key]
                for action in actions:
                    msg = player_id + " " + action + " 1"
                    accumulation.append(msg)
                    print(msg)
        except KeyError:
            pass

def on_release(key):
    try:
        actions = controls[key.char]
        for action in actions:
            msg = player_id + " " + action + " 0"
            accumulation.append(msg)
            print(msg)
    except AttributeError:
        if key in controls:
            actions = controls[key]
            for action in actions:
                msg = player_id + " " + action + " 0"
                accumulation.append(msg)
                print(msg)
    except KeyError:
        pass

def on_move(x, y):
    msg_x = player_id + " " + "move_x " + str(x)
    client_socket.sendto(msg_x.encode(), (server_address, server_port))
    msg_y = player_id + " " + "move_y " + str(y)
    print(msg_x, msg_y)
    client_socket.sendto(msg_y.encode(), (server_address, server_port))


def on_click(x, y, button, pressed):
    if button in controls:
        actions = controls[button]
        if pressed:
            for action in actions:
                msg = player_id + " " + action + " 1"
                accumulation.append(msg)
                print(msg)
        elif button in controls:
            for action in actions:
                msg = player_id + " " + action + " 0"
                accumulation.append(msg)
                print(msg)

def on_scroll(x, y, dx, dy):
    if invert_scroll:
        dy = -dy
    msg = player_id + " " + "wheel " + str(dy)
    accumulation.append(msg)
    print(msg)


mouse_listener = mouse.Listener( 
    #on_move=move(player_id), # Don't send mouse movements for player one; taken care of by the game
    on_move=on_move,
    on_click=on_click,
    on_scroll=on_scroll)
keyboard_listener = keyboard.Listener(
    on_press=on_press,
    on_release=on_release)

# Non blocking mouse and keyboard listeners (hidden threading)
mouse_listener.start()
keyboard_listener.start()

clear_clock = time()
while not quit:
    if time()-clear_clock>5: # clear console every 5 seconds
        clear_clock = time()
        os.system('cls' if os.name == 'nt' else 'clear')
        print("Press Suppr/Delete to quit.\nClicking this application's console will lag for some reason.\nPress escape or click outside to stop lagging")
    acc_copy = accumulation.copy()
    accumulation = []
    for msg in acc_copy:
        client_socket.sendto(msg.encode(), (server_address, server_port))
    sleep(sending_sleep)
