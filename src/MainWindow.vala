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

namespace Wammer {

    using Services;
    using Utils;
    using GLib;
    
    public enum UIState {
        INACTIVE,
        STARTING,
        STOPPING,
        ACTIVE,
        NOINTERFACE,
        DISCLAIMER
    }
    
    public class MainWindow : Gtk.Window {
    
        List<string> interface_list;
        Services.Jammer jammer;
                        
        // headerbar
        Gtk.HeaderBar headerbar;
        Gtk.ComboBoxText interface_chooser;
        
        // main_box and stack
        Gtk.Box main_box;
        Gtk.InfoBar infobar;
        Gtk.Container infobar_container;
        Gtk.Label infobar_label;
        Gtk.Stack stack;
                
        // inactive stack       
        Granite.Widgets.AlertView inactive_view;    
        
        // starting stack
        Granite.Widgets.AlertView starting_view;    
        
        // stopping stack
        Granite.Widgets.AlertView active_view;   
        
        // active stack 
        Granite.Widgets.AlertView stopping_view; 
        
        // no interface stack 
        Granite.Widgets.AlertView no_interface_view;  
                
        // disclaimer stack 
        Granite.Widgets.AlertView disclaimer_view;  
         
                
        public MainWindow () {
            
            jammer = new Services.Jammer ();
                        
            interface_list = Utils.Utils.get_wifi_interfaces (); 
                        
            jammer.state_changed.connect ((t,state) => {
                JammerState j_state = (JammerState) state;
                
                switch (j_state) {
                    case JammerState.INACTIVE:
                        stdout.printf ("[+] JAMMER is INACTIVE now\n");
                        toggleUIState (UIState.INACTIVE);
                        break;
                    case JammerState.STARTING:
                        stdout.printf ("[+] JAMMER is STARTING\n");
                        toggleUIState (UIState.STARTING);
                        break;
                    case JammerState.ACTIVE:
                        stdout.printf ("[+] JAMMER is ACTIVE now\n");
                        toggleUIState (UIState.ACTIVE);
                        break;
                    case JammerState.STOPPING:
                        stdout.printf ("[+] JAMMER is STOPPING\n");
                        toggleUIState (UIState.STOPPING);
                        break;
                }
            });
            
            jammer.message.connect ((t, msg) => {
                infobar_label.label = msg;
                infobar.show ();
            });
                        
            build_ui ();  
        }
        
                                
        private void build_ui () {
            // window and stack            
            //this.width_request = 400;
            //this.height_request = 300;
            this.resizable = false;   
            this.window_position = Gtk.WindowPosition.CENTER; 
            
            // TODO check on startup if airmon + aireplay is installed (like with wifi interfaces)
            // workaround 1: in main meson.build: run_command('sudo', 'apt', 'install', 'aircrack-ng')
            // workaround 2: add on startup (or on running the command) if Aircrack is installed. if not show error
            
            // headerbar
            headerbar = new Gtk.HeaderBar ();
            headerbar.title = "Wammer";
            headerbar.show_close_button = true;
            headerbar.get_style_context ().add_class ("default-decoration");
            this.set_titlebar (headerbar);
              
            interface_chooser = new Gtk.ComboBoxText ();
            interface_chooser.tooltip_text = _("Select the WiFi interface, which will be used for jamming.");
            foreach (string iface in interface_list) {
                interface_chooser.append (iface, iface);
            }
            if (interface_list.length () > 0 ) {
                interface_chooser.active_id = interface_list.first ().data;
            }
            if (interface_list.length () > 1) { 
                // show chooser only if more than interface is installed 
                headerbar.pack_end (interface_chooser);
            }
            
            // main_box and stack
            main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 1);
            this.add (main_box);
            
            infobar = new Gtk.InfoBar ();
            infobar.show_close_button = true;
            infobar.response.connect (() => {
                infobar.hide ();
            });
            infobar.set_message_type (Gtk.MessageType.WARNING);
            infobar_container = infobar.get_content_area (); 
            infobar_label = new Gtk.Label ("");
            infobar_label.set_use_markup (true);
            infobar_container.add (infobar_label);
            main_box.pack_start (infobar);
                                                
            stack = new Gtk.Stack ();
            stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
            main_box.pack_start (stack);
           
                                        
            // inactve stack
            inactive_view = new Granite.Widgets.AlertView (_("Everything works fine."), _("The jammer is <b>inactive</b>. Your WiFi network will work as usual."), "network-wireless");
            inactive_view.show_action (_("Activate jammer"));
            inactive_view.action_activated.connect (() => {	
                if (interface_chooser.active_id != null) {
                    jammer.start (interface_chooser.active_id);
                } else {
                    warning ("Selected jammer interface is null");
                }
            });
            stack.add_titled (inactive_view, "inactive_stack", "inactive_stack");
            
            
            // starting stack
            starting_view = new Granite.Widgets.AlertView (_("We're taking off!"), _("The jammer gets started. Please hold on a moment."), "airplane-mode");
            // alt logo system-run
            stack.add_titled (starting_view, "starting_stack", "starting_stack");
            
            
            // stopping stack
            stopping_view = new Granite.Widgets.AlertView (_("Full power back…"), _("The jammer gets stopped. Please hold on a moment."), "edit-clear");
            stack.add_titled (stopping_view, "stopping_stack", "stopping_stack");
            
            
            // active stack
            active_view = new Granite.Widgets.AlertView (_("Bzzzzzz!"), _("The jammer is <b>active</b> now! Your device should be the only one,\nwhich is able to communicate with the WiFi router."), "notification-network-wireless-disconnected");
            // alt logo list-remove (Durchfahrt verboten)
            active_view.show_action (_("Deactivate jammer"));
            active_view.action_activated.connect (() => {
                jammer.stop ();
            });            
            stack.add_titled (active_view, "active_stack", "active_stack");
            
            
            // no interface stack
            no_interface_view = new Granite.Widgets.AlertView (_("That won't work!"), _("You need at least one WiFi interface installed."), "dialog-question");
            no_interface_view.show_action (_("Exit"));
            no_interface_view.action_activated.connect (() => {
                this.destroy ();
            });            
            stack.add_titled (no_interface_view, "no_interface_stack", "no_interface_stack");
                 
                 
            // disclaimer stack
            disclaimer_view = new Granite.Widgets.AlertView (_("Disclaimer"), _("Jamming WiFi networks might violate certain laws or regulations in your country.\nYou are using this software on your own risk!"), "dialog-warning");
            disclaimer_view.show_action (_("Got it!"));
            disclaimer_view.action_activated.connect (() => {
                settings.accept_disclaimer = true;
                toggleUIState (UIState.INACTIVE);
            });
            main_box.pack_start (disclaimer_view);
            
                                  
            this.show_all ();
            
            // hide infobar initially
            infobar.hide ();
            
            toggleUIState (UIState.INACTIVE);
        }
        
        private void toggleUIState (UIState state) {
            switch (state) {
                case UIState.INACTIVE:
                    if (!settings.accept_disclaimer) {
                        // show disclaimer of not accepted
                        toggleUIState (UIState.DISCLAIMER);
                    } else {
                        // hide disclaimer in case and show stack
                        stack.show ();
                        disclaimer_view.hide ();
                        if (interface_list.length () < 1 ) {
                            // show error if no interface was found
                            toggleUIState (UIState.NOINTERFACE);
                        } else {
                            interface_chooser.set_sensitive (true);
                            this.set_deletable (true);
                            stack.set_visible_child_full ("inactive_stack", Gtk.StackTransitionType.SLIDE_RIGHT);
                        }
                    }
                    break;
                case UIState.STARTING:
                    infobar.hide ();
                    interface_chooser.set_sensitive (false);
                    this.set_deletable (false);
                    stack.set_visible_child_full ("starting_stack", Gtk.StackTransitionType.SLIDE_LEFT); 
                    break;
                case UIState.STOPPING:
                    interface_chooser.set_sensitive (false);
                    this.set_deletable (false);
                    stack.set_visible_child_full ("stopping_stack", Gtk.StackTransitionType.SLIDE_RIGHT); 
                    break;
                case UIState.ACTIVE:   
                    interface_chooser.set_sensitive (false);
                    this.set_deletable (false);
                    stack.set_visible_child_full ("active_stack", Gtk.StackTransitionType.SLIDE_LEFT); 
                    break;
                case UIState.NOINTERFACE:
                    interface_chooser.set_sensitive (false);
                    this.set_deletable (true);   
                    stack.set_visible_child_full ("no_interface_stack", Gtk.StackTransitionType.SLIDE_RIGHT); 
                    break;
               case UIState.DISCLAIMER:
                   stack.hide ();
                   disclaimer_view.show ();
                   interface_chooser.set_sensitive (false);
                   break;
            }       
        }
    }
}
