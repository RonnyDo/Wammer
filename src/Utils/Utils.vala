/*
* Copyright (c) 2018 Ronny Dobra (https://github.com/RonnyDo/Wammer)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public 
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Ronny Dobra <ronnydobra at arcor dot de>
*/

namespace Wammer.Utils {
    public class Utils {
        public static List<string> get_wifi_interfaces () {
            List<string> interface_list = new List<string> ();
            
            string[] cmd = {"iwconfig"};

            SubprocessLauncher launcher = new SubprocessLauncher (SubprocessFlags.STDOUT_PIPE);    
            
            try {
                Subprocess subprocess = launcher.spawnv (cmd);  
                var input_stream = subprocess.get_stdout_pipe ();
                
                // wait for process to exit
                subprocess.wait_check ();
                
                // check if the subprocess was successful (exit code 0)                 
                if (subprocess.get_successful ()) {
                    // try to extract cmd output
                    DataInputStream dis = new DataInputStream (input_stream);
                    string line = "";
                    while ((line = dis.read_line (null)) != null) {
                        if (line.contains ("IEEE 802.11")) {
                            string interface_name = extract_wifi_interface (line);
                            interface_list.append (interface_name);
                        }
                    }
                } else {
                    error ("Process for getting wifi interfaces exited abnormally.");                
                }
            } catch (Error e) {
                error ("Couldn't spawn process for getting wifi interface: %s\n", e.message);
            }
            
            return interface_list;
            // DEBUG return new List<string> ();
        } 
        
        /*
         * Extract wifi interface name
         */
        public static string extract_wifi_interface (string input) {
            string interface_name = input.split (" ")[0];
            
            try {
                Regex regex = new Regex ("[a-zA-Z0-9]+");

                MatchInfo matchInfo = null;
                regex.match (input, 0, out matchInfo);
                if (matchInfo.matches ()) {
		            interface_name = matchInfo.fetch_all()[0];
                }
            } catch (Error e) {
                warning ("Extraction of interface_name failed: %s\n", e.message);
            }
            
            return interface_name;
        }
    
        /*
         * Extract the MAC address from the given input in uppercase fasion.
         * Returns empty string if MAC wasn't found
         */
        public static string extract_mac (string input) {
            string mac = "00:00:00:00:00:00";

            try {
                Regex regex = new Regex ("([0-9A-Fa-f]{2}[:]){5}([0-9A-Fa-f]{2})");

                MatchInfo matchInfo = null;
                regex.match (input, 0, out matchInfo);
                if (matchInfo.matches ()) {
		            mac = matchInfo.fetch_all()[0];		            
                }
            } catch (Error e) {
                warning ("Extraction of MAC address failed: %s\n", e.message);
            }
            
            // return empty string if mac is default (see man iwconfig)
            if (mac == "00:00:00:00:00:00") {
                mac = "";
            }

            return mac.up ();
        }
        
        
        /*
         * Extract name of monitor interface from airmon-ng output
         */
        public static string extract_monitor_interface (string processout) {
            string monitor_interface = "";
            try {
                Regex regex = new Regex ("monitor mode enabled on [a-z0-9]+");

                MatchInfo matchInfo = null;
                regex.match (processout, 0, out matchInfo);
                if (matchInfo.matches ()) {
			        monitor_interface = matchInfo.fetch_all()[0].split("monitor mode enabled on ")[1];
		        }
            } catch (Error err) {

            }
            return monitor_interface;
        }
        
        
        /*
         * Check if interface with the name of monitor_interface is running
         */
        public static bool monitor_interface_running (string monitor_interface) {            
            string[] cmd = {"ifconfig"};

            SubprocessLauncher launcher = new SubprocessLauncher (SubprocessFlags.STDOUT_PIPE);
            
            try {
                Subprocess subprocess = launcher.spawnv (cmd);  
                InputStream stdout_stream = subprocess.get_stdout_pipe ();
                
                subprocess.wait_check ();
                
                string stdout_line = "";
                DataInputStream stdout_datastream = new DataInputStream (stdout_stream);
                
                while ((stdout_line = stdout_datastream.read_line (null)) != null) {
                    if (stdout_line.contains (monitor_interface)) {
                        return true;
                    }
                }                
            } catch (Error e) {
                warning ("Can't verify if monitor interface is rnnning: %s\n", e.message);
            }
            
            return false;
        }
        
        /*
         * Convert command array to single line string
         */
        public static string cmd_to_string (string[] argv) {            
            string cmd = "";
            
            foreach (string arg in argv) {
                cmd += arg + " ";
            }
            
            return cmd.strip ();
        }
        
    }
}
