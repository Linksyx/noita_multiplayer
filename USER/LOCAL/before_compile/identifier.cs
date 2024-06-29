// Compile with: csc identifier_before_compile.cs /reference:Pluralinput.Sdk.dll

using Pluralinput.Sdk;
using System;
using System.Collections.Generic;
using System.Threading;

public class Functions
{
    private static InputManager im = new InputManager();
    private static IEnumerable<Mouse> mice = im.Devices.Mice;
    private static IEnumerable<Keyboard> keyboards = im.Devices.Keyboards;

    public static void Main(string[] args)
    {
        Console.WriteLine("Pressing keys and mouse buttons will give you their name and the device number to set in settings.json\nAvoid clicking on the window!");
        // Handle events for all available mice
        int mouseNumber = 1;
        foreach (var mouse in mice)
        {
            int currentMouseNumber = mouseNumber;
            mouse.ButtonDown += (o, e) =>
            {
                Console.WriteLine("Mouse number " + currentMouseNumber + " pressed " + e.Button.ToString());
            };

            mouseNumber++;
        }

        // Handle events for all available keyboards
        int keyboardNumber = 1;
        foreach (var keyboard in keyboards)
        {
            int currentKeyboardNumber = keyboardNumber;
            keyboard.KeyDown += (o, e) =>
            {
                Console.WriteLine("Keyboard number " + currentKeyboardNumber + " pressed " + e.Key.ToString());
            };
            keyboardNumber++;
        }

        // Keep the main thread running
        while (true)
        {
            Thread.Sleep(1000); // Sleep for 1 second to avoid CPU hogging
        }
    }
}
