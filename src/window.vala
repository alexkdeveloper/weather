/* window.vala
 *
 * Copyright 2023 Alex
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

namespace Weather {
    [GtkTemplate (ui = "/io/github/alexkdeveloper/weather/window.ui")]
    public class Window : Adw.ApplicationWindow {
        [GtkChild]
        private unowned Gtk.Label location_label;
        [GtkChild]
        private unowned Gtk.Label temp_label;
        [GtkChild]
        private unowned Gtk.Label weather_label;
        [GtkChild]
        private unowned Gtk.Label wind_label;
        [GtkChild]
        private unowned Gtk.Label visibility_label;
        [GtkChild]
        private unowned Gtk.Label pressure_label;
        [GtkChild]
        private unowned Gtk.Image weather_icon;

        private GWeather.Location? location = null;
        private GWeather.Info weather_info;

        public Window (Gtk.Application app) {
            Object (application: app);

            weather_info = new GWeather.Info (location) {
                contact_info = "alex@dev.io"
            };

            weather_icon.icon_name = weather_info.get_icon_name ();

            temp_label.label = weather_info.get_temp ();
            weather_label.label = weather_info.get_sky ();
            wind_label.label = weather_info.get_wind ();
            visibility_label.label = weather_info.get_visibility ();
            pressure_label.label = weather_info.get_pressure ();

            var settings = new Settings ("io.github.alexkdeveloper.weather");

            settings.bind ("width", this, "default-width", SettingsBindFlags.DEFAULT);
            settings.bind ("height", this, "default-height", SettingsBindFlags.DEFAULT);
            settings.bind ("is-maximized", this, "maximized", SettingsBindFlags.DEFAULT);
            settings.bind ("is-fullscreen", this, "fullscreened", SettingsBindFlags.DEFAULT);

            get_location ();

            notify["is-active"].connect (() => {
            if (location == null) {
                get_location ();
            } else {
                weather_info.update ();
            }
        });

        weather_info.updated.connect (() => {
            if (location == null) {
                return;
            }
            location_label.label = dgettext ("libgweather-locations", location.get_city_name ());

            weather_icon.icon_name = weather_info.get_icon_name ();
            weather_label.label = dgettext ("libgweather", weather_info.get_sky ());

            double temp;
            weather_info.get_value_temp (GWeather.TemperatureUnit.CENTIGRADE, out temp);
            temp_label.label = _("%i°").printf ((int) temp);

            double visibility;
            weather_info.get_value_visibility (GWeather.DistanceUnit.KM, out visibility);
            visibility_label.label = _("%i km").printf ((int) visibility);

            double pressure;
            weather_info.get_value_pressure (GWeather.PressureUnit.MM_HG, out pressure);
            pressure_label.label = _("%i mmHg").printf ((int) pressure);

            double speed;
            GWeather.WindDirection direction;
            weather_info.get_value_wind (GWeather.SpeedUnit.MS, out speed, out direction);
            wind_label.label = _("%s,  %i m/s").printf (direction.to_string(), (int) speed);
          });
        }

    private void get_location () {
        get_gclue_simple.begin ((obj, res) => {
            var simple = get_gclue_simple.end (res);
            if (simple != null) {
                simple.notify["location"].connect (() => {
                    on_location_updated (simple.location.latitude, simple.location.longitude);
                });

                on_location_updated (simple.location.latitude, simple.location.longitude);
            } else {
                alert(_("Unable to Get Location"), _("Make sure location access is turned on in settings"));
            }
        });
    }

    private async GClue.Simple? get_gclue_simple () {
        try {
            var simple = yield new GClue.Simple ("io.github.alexkdeveloper.weather", GClue.AccuracyLevel.CITY, null);
            return simple;
        } catch (Error e) {
            warning ("Failed to connect to GeoClue2 service: %s", e.message);
            return null;
        }
    }

    private void on_location_updated (double latitude, double longitude) {
        location = GWeather.Location.get_world ();
        location = location.find_nearest_city (latitude, longitude);
        if (location != null) {
            weather_info.location = location;
            weather_info.update ();
        }
      }

    private void alert (string heading, string body){
            var dialog_alert = new Adw.MessageDialog(this, heading, body);
            if (body != "") {
                dialog_alert.set_body(body);
            }
            dialog_alert.add_response("ok", _("_OK"));
            dialog_alert.set_response_appearance("ok", SUGGESTED);
            dialog_alert.response.connect((_) => { dialog_alert.close(); });
            dialog_alert.show();
        }
    }
}
