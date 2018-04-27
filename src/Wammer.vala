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

namespace Wammer {

    // namespace-wide variable
    public Services.Settings settings;
    
    public class Wammer : Gtk.Application {

        MainWindow mainwindow;
        static Wammer _instance = null;

        public Wammer () {
            Object (
                //a full list of fields can be found at
                //https://valadoc.org/granite/Granite.Application.html
                application_id: "com.github.ronnydo.wammer",
                flags: ApplicationFlags.FLAGS_NONE
            );
        }
        
        public static Wammer instance {
            get {
                if (_instance == null) {
                    _instance = new Wammer ();
                }
                return _instance;
            }
        }

        protected override void activate () {
            if (mainwindow != null) {
                mainwindow.present ();
                return;
            }
    
            settings = Services.Settings.get_instance ();

            mainwindow = new MainWindow ();
            mainwindow.set_application (this);
        }

        public static int main (string[] args) {
        
            var app = new Wammer ();
            return app.run (args);                      
            
            // starting with root privileges
            // https://greyok.github.io/simple-polkit-tutorial.html
        }
    }
}
