using Pluralinput.Sdk;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Threading;
using System.IO;

public class Config
{
    public string server_address { get; set; }
    public int server_port { get; set; }
    public int player_id { get; set; }
    public int keyboard_id { get; set; }
    public int mouse_id { get; set; }
    public bool invert_scroll { get; set; }
    public Dictionary<string, List<string>> controls { get; set; }
}
public class Functions
{
    private static UdpClient? client = null;
    private static InputManager im = new InputManager();
    private static IEnumerable<Mouse> mice = im.Devices.Mice;
    private static IEnumerable<Keyboard> keyboards = im.Devices.Keyboards;

    private static string json = File.ReadAllText("settings.json");
    private static Config config = JsonConvert.DeserializeObject<Config>(json);

    public static void Send(int target_player, string key, int data)
    {
        if (config.controls.ContainsKey(key))
        {
            foreach (var action in config.controls[key])
            {
                string message = target_player.ToString();
                message += " " + action + " " + data.ToString();

                Console.WriteLine(message);
                byte[] message_bytes = Encoding.ASCII.GetBytes(message);
                client.Send(message_bytes, message_bytes.Length);
            }
        }
    }

    public static void Main(string[] args)
    {
        try
        {
            // Add mouse movements to the dictionnary
            config.controls.Add("partial_x", new List<string> { "partial_x" });
            config.controls.Add("partial_y", new List<string> { "partial_y" });
            config.controls.Add("wheel", new List<string> { "wheel" });

            // Setup UDP client
            IPAddress localAddr = IPAddress.Parse(config.server_address);
            client = new UdpClient(localAddr.ToString(), config.server_port);

            // Start a new thread to handle mouse events
            Thread EventThread = new Thread(() => EventHandler(config.player_id, config.mouse_id - 1, config.keyboard_id - 1));
            EventThread.Start();

            // Keep the main thread running
            while (true)
            {
                Console.WriteLine("Printed lines are what is sent to the host.\nCheck settings.json and README.txt if nothing is printed or something seems odd.\nMouse movements will appear as partial_x and partial_y, it's normal to see a lot of them.");
                Thread.Sleep(5000); // Sleep for 1 second to avoid CPU hogging -- I'm not sure if it's really necessary
                Console.Clear();
            }
        }
        catch (SocketException e)
        {
            Console.WriteLine("SocketException: {0}", e);
            client.Close();
            Console.WriteLine("Connexion closed. Type 1 then press Enter to restart and 0 and Enter to close");
            var input = Console.Read();
            if (input == 1)
            {
                Main(args);
            }
            Console.WriteLine("Closing...");
        }
    }

    public static void EventHandler(int target_player, int mouse_i, int keyboard_i)
    {
        keyboards.ElementAt(keyboard_i).KeyDown += (o, e) =>
        {
            Send(target_player, e.Key.ToString(), 1);
        };
        keyboards.ElementAt(keyboard_i).KeyUp += (o, e) =>
        {
            Send(target_player, e.Key.ToString(), 0);
        };

        mice.ElementAt(mouse_i).Move += (o, e) =>
        {
            Send(target_player, "partial_x", e.LastX); // TODO: maybe only send if not 0 AND maybe accumulate for a bit before sending
            Send(target_player, "partial_y", e.LastY);
        };
        mice.ElementAt(mouse_i).Wheel += (o, e) =>
        {
            if (e.WheelDelta == 120 && !config.invert_scroll)
            {
                Send(target_player, "wheel", 1); // TODO: Implement invert scroll option
            }
            else
            {
                Send(target_player, "wheel", -1);
            }
        };
        mice.ElementAt(mouse_i).ButtonDown += (o, e) =>
        {
            Send(target_player, e.Button.ToString(), 1);
        };
        mice.ElementAt(mouse_i).ButtonUp += (o, e) =>
        {
            Send(target_player, e.Button.ToString(), 0);
        };
    }
}
