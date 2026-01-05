#!/usr/bin/env python3
"""
ChromeOS_PowerControl GUI
"""

import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, GLib
import os
from pathlib import Path

class ConfigEditor(Gtk.Window):
    def __init__(self):
        settings = Gtk.Settings.get_default()
        settings.set_property("gtk-application-prefer-dark-theme", True)
        
        super().__init__(title="ChromeOS_PowerControl GUI")
        self.set_default_size(1000, 700)
        self.set_border_width(10)
        self.set_decorated(True)
        
        self.config_path = self.find_config_file()
        self.config_data = {}
        self.widgets = {}
        self.original_gpu_max = None
        self.updating_constraints = False
        self.initial_load = True
        
        if not self.config_path:
            self.show_error_dialog(
                "Config File Not Found",
                "Could not find config file at:\n"
                "/mnt/chromeos/MyFiles/Downloads/ChromeOS_PowerControl_Config/config\n"
                "~/user/MyFiles/Downloads/ChromeOS_PowerControl_Config/config\n\n"
                "Please ensure the folder is shared to Crostini/Chard."
            )
            self.destroy()
            return
        
        self.create_ui()
        self.load_config()
        self.setup_constraints()
        self.initial_load = False
    
    def find_config_file(self):
        """Find config file in possible locations"""
        possible_paths = [
            "/mnt/chromeos/MyFiles/Downloads/ChromeOS_PowerControl_Config/config",
            os.path.expanduser("~/user/MyFiles/Downloads/ChromeOS_PowerControl_Config/config")
        ]
        
        for path in possible_paths:
            if os.path.exists(path):
                return path
        
        return None
    
    def create_ui(self):
        """UI"""
        main_vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        self.add(main_vbox)
        header_bar = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=5)
        header_bar.set_margin_bottom(1)
        main_vbox.pack_start(header_bar, False, False, 0)
        title_label = Gtk.Label()
        title_label.set_halign(Gtk.Align.START)
        title_label.set_hexpand(True)
        header_bar.pack_start(title_label, True, True, 0)
        reload_btn = Gtk.Button(label="Reload")
        reload_btn.connect("clicked", self.on_reload_clicked)
        header_bar.pack_start(reload_btn, False, False, 0)
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_vexpand(True)
        scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        main_vbox.pack_start(scrolled, True, True, 0)
        self.grid = Gtk.Grid()
        self.grid.set_column_spacing(5)
        self.grid.set_row_spacing(5)
        self.grid.set_margin_start(10)
        self.grid.set_margin_end(10)
        self.grid.set_margin_top(10)
        self.grid.set_margin_bottom(10)
        scrolled.add(self.grid)
        self.create_config_sections()
        button_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=5)
        button_box.set_halign(Gtk.Align.CENTER)
        main_vbox.pack_start(button_box, False, False, 0)
        save_btn = Gtk.Button(label="Save Config")
        save_btn.connect("clicked", self.on_save_clicked)
        button_box.pack_start(save_btn, False, False, 0)
        exit_btn = Gtk.Button(label="Exit")
        exit_btn.connect("clicked", lambda x: self.destroy())
        button_box.pack_start(exit_btn, False, False, 0)

    def create_slider(self, min_val, max_val, step=1):
        """Slider"""
        scale = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, min_val, max_val, step)
        if step < 1:
            scale.set_digits(1)
        else:
            scale.set_digits(0)
        scale.set_value_pos(Gtk.PositionType.RIGHT)
        scale.set_hexpand(True)
        scale.set_size_request(400, -1)
        return scale

    def create_slider_with_spinbutton(self, min_val, max_val, step=1):
        """Slider"""
        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=5)
        scale = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, min_val, max_val, step)
        if step < 1:
            scale.set_digits(1)
        else:
            scale.set_digits(0)
        scale.set_value_pos(Gtk.PositionType.RIGHT)
        scale.set_hexpand(True)
        scale.set_size_request(100, -1)
        scale.set_draw_value(False)
        adjustment = Gtk.Adjustment(value=min_val, lower=min_val, upper=max_val, 
                                   step_increment=step, page_increment=step*10)
        spinbutton = Gtk.SpinButton(adjustment=adjustment, climb_rate=step, digits=0)
        spinbutton.set_width_chars(6)
        def on_scale_changed(s):
            if not spinbutton.get_value() == s.get_value():
                spinbutton.set_value(s.get_value())
        def on_spin_changed(s):
            if not scale.get_value() == s.get_value():
                scale.set_value(s.get_value())
        scale.connect("value-changed", on_scale_changed)
        spinbutton.connect("value-changed", on_spin_changed)
        box.pack_start(scale, True, True, 0)
        box.pack_start(spinbutton, False, False, 0)
        return box, scale, spinbutton

    def create_switch(self):
        """Create an on/off switch"""
        switch = Gtk.Switch()
        switch.set_halign(Gtk.Align.START)
        return switch

    def create_combo(self, options):
        """Create a dropdown combo box"""
        combo = Gtk.ComboBoxText()
        for option in options:
            combo.append_text(option)
        return combo

    def create_config_sections(self):
        """Create all configuration sections"""
        sections = {
            "PowerControl": [
                ("MAX_TEMP", "Maximum Temperature (°C)", "slider", 50, 90, 1, False),
                ("HOTZONE", "Hotzone Temperature (°C)", "slider", 50, 90, 1, False),
                ("MIN_TEMP", "Minimum Temperature (°C)", "slider", 30, 90, 1, False),
                ("MAX_PERF_PCT", "Maximum Performance %", "slider", 10, 100, 1, False),
                ("MIN_PERF_PCT", "Minimum Performance %", "slider", 10, 100, 1, False),
                ("RAMP_UP", "Ramp Up Speed (%)", "slider", 1, 50, 1, False),
                ("RAMP_DOWN", "Ramp Down Speed (%)", "slider", 1, 50, 1, False),
                ("CPU_POLL", "CPU Poll Interval (s)", "slider", 0.1, 5.0, 0.1, False),
            ],
            "GPUControl": [
                ("GPU_MAX_FREQ", "GPU Max Frequency", "slider", 100, 2000, 50, False),
            ],
            "FanControl": [
                ("MIN_FAN", "Minimum Fan Speed %", "slider", 0, 100, 1, False),
                ("MAX_FAN", "Maximum Fan Speed %", "slider", 0, 100, 1, False),
                ("FAN_MIN_TEMP", "Fan Minimum Temp (°C)", "slider", 30, 80, 1, False),
                ("FAN_MAX_TEMP", "Fan Maximum Temp (°C)", "slider", 50, 80, 1, False),
                ("STEP_UP", "Fan Step Up (%)", "slider", 1, 20, 1, False),
                ("STEP_DOWN", "Fan Step Down (%)", "slider", 1, 20, 1, False),
                ("FAN_POLL", "Fan Poll Interval (s)", "slider", 1, 10, 1, False),
            ],
            "BatteryControl": [
                ("CHARGE_MAX", "Maximum Charge %", "slider", 20, 100, 1, False),
            ],
            "SleepControl - Battery": [
                ("BATTERY_DIM_DELAY", "Dim Delay (min)", "slider", 1, 10080, 1, True),
                ("BATTERY_BACKLIGHT", "Display Off (min)", "slider", 1, 10080, 1, True),
                ("BATTERY_DELAY", "Sleep Delay (min)", "slider", 1, 10080, 1, True),
                ("AUDIO_DETECTION_BATTERY", "Audio Detection", "switch", None, None, None, False),
                ("LIDSLEEP_BATTERY", "Lid Sleep", "switch", None, None, None, False),
            ],
            "SleepControl - AC Power": [
                ("POWER_DIM_DELAY", "Dim Delay (min)", "slider", 1, 10080, 1, True),
                ("POWER_BACKLIGHT", "Display Off (min)", "slider", 1, 10080, 1, True),
                ("POWER_DELAY", "Sleep Delay (min)", "slider", 1, 10080, 1, True),
                ("AUDIO_DETECTION_POWER", "Audio Detection", "switch", None, None, None, False),
                ("LIDSLEEP_POWER", "Lid Sleep", "switch", None, None, None, False),
            ],
            "SleepControl - Mode": [
                ("SUSPEND_MODE", "Suspend Mode", "combo", ["deep", "s2idle"], None, None, False),
            ],
            "Startup": [
                ("STARTUP_BATTERYCONTROL", "Start BatteryControl", "switch", None, None, None, False),
                ("STARTUP_POWERCONTROL", "Start PowerControl", "switch", None, None, None, False),
                ("STARTUP_FANCONTROL", "Start FanControl", "switch", None, None, None, False),
                ("STARTUP_GPUCONTROL", "Start GPUControl", "switch", None, None, None, False),
                ("STARTUP_SLEEPCONTROL", "Start SleepControl", "switch", None, None, None, False),
            ],
        }

        row = 0
        for section_name, fields in sections.items():
            header = Gtk.Label()
            header.set_markup(f"<b><big>{section_name}</big></b>")
            header.set_halign(Gtk.Align.START)
            header.set_margin_start(20)
            header.set_margin_top(15)
            header.set_margin_bottom(5)
            self.grid.attach(header, 0, row, 2, 1)
            row += 1
            separator = Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL)
            separator.set_margin_bottom(5)
            separator.set_margin_start(10)
            self.grid.attach(separator, 0, row, 2, 1)
            row += 1
            for field in fields:
                key = field[0]
                label = field[1]
                widget_type = field[2]
                if key == "MAX_PERF_PCT":
                    lbl = Gtk.Label()
                    lbl.set_markup(f"<b>{label}</b>")
                else:
                    lbl = Gtk.Label(label=label)
                lbl.set_halign(Gtk.Align.END)
                lbl.set_margin_start(10)
                lbl.set_size_request(100, -1)
                self.grid.attach(lbl, 0, row, 1, 1)
                if widget_type == "slider":
                    min_val = field[3]
                    max_val = field[4]
                    step = field[5]
                    with_spinbutton = field[6]
                    if with_spinbutton:
                        box, scale, spinbutton = self.create_slider_with_spinbutton(min_val, max_val, step)
                        self.grid.attach(box, 1, row, 1, 1)
                        self.widgets[key] = scale
                    else:
                        widget = self.create_slider(min_val, max_val, step)
                        self.grid.attach(widget, 1, row, 1, 1)
                        self.widgets[key] = widget
                elif widget_type == "switch":
                    widget = self.create_switch()
                    self.grid.attach(widget, 1, row, 1, 1)
                    self.widgets[key] = widget
                elif widget_type == "combo":
                    options = field[3]
                    widget = self.create_combo(options)
                    self.grid.attach(widget, 1, row, 1, 1)
                    self.widgets[key] = widget
                row += 1

    def setup_constraints(self):
        """Setup slider constraints"""
        if all(k in self.widgets for k in ["MIN_TEMP", "HOTZONE", "MAX_TEMP"]):
            self.widgets["MIN_TEMP"].connect("value-changed", self.on_temp_constraint)
            self.widgets["HOTZONE"].connect("value-changed", self.on_temp_constraint)
            self.widgets["MAX_TEMP"].connect("value-changed", self.on_temp_constraint)
        if all(k in self.widgets for k in ["MIN_PERF_PCT", "MAX_PERF_PCT"]):
            self.widgets["MIN_PERF_PCT"].connect("value-changed", self.on_perf_constraint)
            self.widgets["MAX_PERF_PCT"].connect("value-changed", self.on_perf_constraint)
        if all(k in self.widgets for k in ["MIN_FAN", "MAX_FAN"]):
            self.widgets["MIN_FAN"].connect("value-changed", self.on_fan_speed_constraint)
            self.widgets["MAX_FAN"].connect("value-changed", self.on_fan_speed_constraint)
        if all(k in self.widgets for k in ["FAN_MIN_TEMP", "FAN_MAX_TEMP"]):
            self.widgets["FAN_MIN_TEMP"].connect("value-changed", self.on_fan_temp_constraint)
            self.widgets["FAN_MAX_TEMP"].connect("value-changed", self.on_fan_temp_constraint)
        if all(k in self.widgets for k in ["BATTERY_DIM_DELAY", "BATTERY_BACKLIGHT", "BATTERY_DELAY"]):
            self.widgets["BATTERY_DIM_DELAY"].connect("value-changed", self.on_battery_sleep_constraint)
            self.widgets["BATTERY_BACKLIGHT"].connect("value-changed", self.on_battery_sleep_constraint)
            self.widgets["BATTERY_DELAY"].connect("value-changed", self.on_battery_sleep_constraint)
        if all(k in self.widgets for k in ["POWER_DIM_DELAY", "POWER_BACKLIGHT", "POWER_DELAY"]):
            self.widgets["POWER_DIM_DELAY"].connect("value-changed", self.on_power_sleep_constraint)
            self.widgets["POWER_BACKLIGHT"].connect("value-changed", self.on_power_sleep_constraint)
            self.widgets["POWER_DELAY"].connect("value-changed", self.on_power_sleep_constraint)

    def on_temp_constraint(self, scale):
        if self.updating_constraints:
            return
        self.updating_constraints = True
        min_temp = self.widgets["MIN_TEMP"].get_value()
        hotzone = self.widgets["HOTZONE"].get_value()
        max_temp = self.widgets["MAX_TEMP"].get_value()
        if min_temp >= hotzone:
            self.widgets["MIN_TEMP"].set_value(hotzone - 1)
        if min_temp >= max_temp:
            self.widgets["MIN_TEMP"].set_value(max_temp - 2)
        if hotzone <= min_temp:
            self.widgets["HOTZONE"].set_value(min_temp + 1)
        if hotzone >= max_temp:
            self.widgets["HOTZONE"].set_value(max_temp - 1)
        if max_temp <= hotzone:
            self.widgets["MAX_TEMP"].set_value(hotzone + 1)
        if max_temp <= min_temp:
            self.widgets["MAX_TEMP"].set_value(min_temp + 2)
        self.updating_constraints = False
    
    def on_perf_constraint(self, scale):
        if self.updating_constraints:
            return
        self.updating_constraints = True
        
        min_perf = self.widgets["MIN_PERF_PCT"].get_value()
        max_perf = self.widgets["MAX_PERF_PCT"].get_value()
        
        if min_perf > max_perf:
            self.widgets["MAX_PERF_PCT"].set_value(min_perf)
        if max_perf < min_perf:
            self.widgets["MIN_PERF_PCT"].set_value(max_perf)
        
        self.updating_constraints = False
    
    def on_fan_speed_constraint(self, scale):
        if self.updating_constraints:
            return
        self.updating_constraints = True
        min_fan = self.widgets["MIN_FAN"].get_value()
        max_fan = self.widgets["MAX_FAN"].get_value()
        
        if min_fan > max_fan:
            self.widgets["MAX_FAN"].set_value(min_fan)
        if max_fan < min_fan:
            self.widgets["MIN_FAN"].set_value(max_fan)
        self.updating_constraints = False
    
    def on_fan_temp_constraint(self, scale):
        if self.updating_constraints:
            return
        self.updating_constraints = True
        min_temp = self.widgets["FAN_MIN_TEMP"].get_value()
        max_temp = self.widgets["FAN_MAX_TEMP"].get_value()
        if min_temp > max_temp:
            self.widgets["FAN_MAX_TEMP"].set_value(min_temp)
        if max_temp < min_temp:
            self.widgets["FAN_MIN_TEMP"].set_value(max_temp)
        self.updating_constraints = False
    
    def on_battery_sleep_constraint(self, scale):
        if self.updating_constraints or self.initial_load:
            return
        self.updating_constraints = True
        
        dim = self.widgets["BATTERY_DIM_DELAY"].get_value()
        backlight = self.widgets["BATTERY_BACKLIGHT"].get_value()
        delay = self.widgets["BATTERY_DELAY"].get_value()
        
        # Only adjust the values that violate constraints
        if dim >= backlight:
            self.widgets["BATTERY_DIM_DELAY"].set_value(backlight - 1)
        if backlight >= delay:
            self.widgets["BATTERY_BACKLIGHT"].set_value(delay - 1)
        
        self.updating_constraints = False
    
    def on_power_sleep_constraint(self, scale):
        if self.updating_constraints or self.initial_load:
            return
        self.updating_constraints = True
        
        dim = self.widgets["POWER_DIM_DELAY"].get_value()
        backlight = self.widgets["POWER_BACKLIGHT"].get_value()
        delay = self.widgets["POWER_DELAY"].get_value()
        
        # Only adjust the values that violate constraints
        if dim >= backlight:
            self.widgets["POWER_DIM_DELAY"].set_value(backlight - 1)
        if backlight >= delay:
            self.widgets["POWER_BACKLIGHT"].set_value(delay - 1)
        
        self.updating_constraints = False
    
    def load_config(self):
        """Load configuration from file"""
        if not os.path.exists(self.config_path):
            self.show_error_dialog("Error", f"Config file not found: {self.config_path}")
            return
        self.config_data = {}
        try:
            with open(self.config_path, 'r') as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith('#'):
                        if '=' in line:
                            key, value = line.split('=', 1)
                            self.config_data[key.strip()] = value.strip()
            if "ORIGINAL_GPU_MAX_FREQ" in self.config_data:
                self.original_gpu_max = int(self.config_data["ORIGINAL_GPU_MAX_FREQ"])
                if "GPU_MAX_FREQ" in self.widgets:
                    gpu_min = int(self.original_gpu_max * 0.1)
                    self.widgets["GPU_MAX_FREQ"].set_range(gpu_min, self.original_gpu_max)
            else:
                if "GPU_MAX_FREQ" in self.widgets:
                    self.widgets["GPU_MAX_FREQ"].set_range(100, 2000)
            sleep_keys = ["BATTERY_DELAY", "BATTERY_BACKLIGHT", "BATTERY_DIM_DELAY", 
                         "POWER_DELAY", "POWER_BACKLIGHT", "POWER_DIM_DELAY"]
            self.updating_constraints = True
            for key, widget in self.widgets.items():
                if key in self.config_data:
                    value = self.config_data[key]
                    if isinstance(widget, Gtk.Scale):
                        try:
                            widget.set_value(float(value))
                        except ValueError:
                            widget.set_value(0)
                    elif isinstance(widget, Gtk.Switch):
                        widget.set_active(value == "1")
                    elif isinstance(widget, Gtk.ComboBoxText):
                        if key == "SUSPEND_MODE":
                            if value == "freeze":
                                value = "deep"
                        idx = 0
                        model = widget.get_model()
                        for i, row in enumerate(model):
                            if row[0] == value:
                                idx = i
                                break
                        widget.set_active(idx)
            self.updating_constraints = False
        except Exception as e:
            self.updating_constraints = False
            self.show_error_dialog("Error", f"Failed to load config: {str(e)}")
    
    def save_config(self):
        """Save configuration to file"""
        try:
            with open(self.config_path, 'r') as f:
                lines = f.readlines()
            
            sleep_keys = ["BATTERY_DELAY", "BATTERY_BACKLIGHT", "BATTERY_DIM_DELAY", 
                         "POWER_DELAY", "POWER_BACKLIGHT", "POWER_DIM_DELAY"]
            
            new_lines = []
            for line in lines:
                if line.strip() and not line.strip().startswith('#'):
                    if '=' in line:
                        key = line.split('=', 1)[0].strip()
                        if key in self.widgets:
                            widget = self.widgets[key]
                            
                            if isinstance(widget, Gtk.Scale):
                                value = widget.get_value()
                                if key in sleep_keys:
                                    value = int(value * 60)
                                elif key == "CPU_POLL":
                                    new_value = f"{value:.1f}"
                                    new_lines.append(f"{key}={new_value}\n")
                                    continue
                                else:
                                    value = int(value)
                                new_value = str(value)
                            elif isinstance(widget, Gtk.Switch):
                                new_value = "1" if widget.get_active() else "0"
                            elif isinstance(widget, Gtk.ComboBoxText):
                                new_value = widget.get_active_text()
                            
                            new_lines.append(f"{key}={new_value}\n")
                        else:
                            new_lines.append(line)
                    else:
                        new_lines.append(line)
                else:
                    new_lines.append(line)
            
            with open(self.config_path, 'w') as f:
                f.writelines(new_lines)
            
            self.show_info_dialog("Success", "Configuration saved successfully!")
        except PermissionError:
            self.show_error_dialog("Permission Denied", 
                "Cannot write to config file.\n\n")
        except Exception as e:
            self.show_error_dialog("Error", f"Failed to save config: {str(e)}")
    
    def on_reload_clicked(self, button):
        """Handle reload button click"""
        self.load_config()
    
    def on_save_clicked(self, button):
        """Handle save button click"""
        self.save_config()
    
    def on_reset_clicked(self, button):
        """Handle reset button click"""
        dialog = Gtk.MessageDialog(
            transient_for=self,
            flags=0,
            message_type=Gtk.MessageType.QUESTION,
            buttons=Gtk.ButtonsType.YES_NO,
            text="Confirm Reset",
        )
        dialog.format_secondary_text(
            "Reset all values to those currently in the config file?"
        )
        response = dialog.run()
        dialog.destroy()
        
        if response == Gtk.ResponseType.YES:
            self.load_config()
    
    def show_error_dialog(self, title, message):
        """Show error dialog"""
        dialog = Gtk.MessageDialog(
            transient_for=self,
            flags=0,
            message_type=Gtk.MessageType.ERROR,
            buttons=Gtk.ButtonsType.OK,
            text=title,
        )
        dialog.format_secondary_text(message)
        dialog.run()
        dialog.destroy()
    
    def show_info_dialog(self, title, message):
        """Show info dialog"""
        dialog = Gtk.MessageDialog(
            transient_for=self,
            flags=0,
            message_type=Gtk.MessageType.INFO,
            buttons=Gtk.ButtonsType.OK,
            text=title,
        )
        dialog.format_secondary_text(message)
        dialog.run()
        dialog.destroy()

def main():
    settings = Gtk.Settings.get_default()
    settings.set_property("gtk-application-prefer-dark-theme", True)
    settings.set_property("gtk-theme-name", "Adwaita-dark")
    
    win = ConfigEditor()
    if win.config_path:
        win.connect("destroy", Gtk.main_quit)
        win.show_all()
        Gtk.main()

if __name__ == "__main__":
    main()
