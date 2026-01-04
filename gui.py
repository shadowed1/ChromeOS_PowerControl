#!/usr/bin/env python3
"""
ChromeOS PowerControl Config Editor
A GUI application for editing ChromeOS PowerControl configuration files
Uses GTK3 (pre-installed with Crostini)
"""

import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk
import os
from pathlib import Path

class ConfigEditor(Gtk.Window):
    def __init__(self):
        super().__init__(title="ChromeOS_PowerControl GUI")
        self.set_default_size(900, 700)
        self.set_border_width(10)
        
        self.config_path = self.find_config_file()
        self.config_data = {}
        self.widgets = {}
        
        if not self.config_path:
            self.show_error_dialog(
                "Config File Not Found",
                "Could not find config file at either:\n"
                "/mnt/chromeos/MyFiles/Downloads/ChromeOS_PowerControl_Config/config\n"
                "~/user/MyFiles/ChromeOS_PowerControl_Config/config\n\n"
                "Please ensure the folder is shared to Crostini/chroot."
            )
            self.destroy()
            return
        
        self.create_ui()
        self.load_config()
    
    def find_config_file(self):
        """Find config file in possible locations"""
        possible_paths = [
            "/mnt/chromeos/MyFiles/ChromeOS_PowerControl_Config/config",
            os.path.expanduser("~/user/MyFiles/Downloads/ChromeOS_PowerControl_Config/config")
        ]
        
        for path in possible_paths:
            if os.path.exists(path):
                return path
        
        return None
    
    def create_ui(self):
        """Create the user interface"""
        main_vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        self.add(main_vbox)
        
        top_hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=5)
        main_vbox.pack_start(top_hbox, False, False, 0)
        
        path_label = Gtk.Label(label="Config File:")
        top_hbox.pack_start(path_label, False, False, 0)
        
        self.path_entry = Gtk.Entry()
        self.path_entry.set_text(self.config_path)
        self.path_entry.set_hexpand(True)
        top_hbox.pack_start(self.path_entry, True, True, 0)
        
        reload_btn = Gtk.Button(label="Reload")
        reload_btn.connect("clicked", self.on_reload_clicked)
        top_hbox.pack_start(reload_btn, False, False, 0)
        
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_vexpand(True)
        scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        main_vbox.pack_start(scrolled, True, True, 0)
        
        self.grid = Gtk.Grid()
        self.grid.set_column_spacing(10)
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
        
        reset_btn = Gtk.Button(label="Reset to Current File")
        reset_btn.connect("clicked", self.on_reset_clicked)
        button_box.pack_start(reset_btn, False, False, 0)
        
        exit_btn = Gtk.Button(label="Exit")
        exit_btn.connect("clicked", lambda x: self.destroy())
        button_box.pack_start(exit_btn, False, False, 0)
    
    def create_config_sections(self):
        """Create all configuration sections with input fields"""
        sections = {
            "PowerControl": [
                ("MAX_TEMP", "Maximum Temperature (°C)", "Temperature threshold for maximum performance"),
                ("MIN_TEMP", "Minimum Temperature (°C)", "Temperature threshold for minimum performance"),
                ("MAX_PERF_PCT", "Maximum Performance %", "Maximum CPU performance percentage (0-100)"),
                ("MIN_PERF_PCT", "Minimum Performance %", "Minimum CPU performance percentage (0-100)"),
                ("HOTZONE", "Hotzone Temperature (°C)", "Temperature when aggressive throttling begins."),
                ("CPU_POLL", "CPU Poll Interval (s)", "How often to check CPU temperature"),
                ("RAMP_UP", "Ramp Up Speed", "Speed to increase performance"),
                ("RAMP_DOWN", "Ramp Down Speed", "Speed to decrease performance"),
            ],
            "BatteryControl": [
                ("CHARGE_MAX", "Maximum Charge %", "Maximum battery charge level (0-100)"),
            ],
            "FanControl": [
                ("MIN_FAN", "Minimum Fan Speed %", "Minimum fan speed percentage (0-100)"),
                ("MAX_FAN", "Maximum Fan Speed %", "Maximum fan speed percentage (0-100)"),
                ("FAN_MIN_TEMP", "Fan Minimum Temp (°C)", "Temperature to start fan"),
                ("FAN_MAX_TEMP", "Fan Maximum Temp (°C)", "Temperature for maximum fan speed"),
                ("STEP_UP", "Fan Step Up", "Speed to increase fan RPM"),
                ("STEP_DOWN", "Fan Step Down", "Speed to decrease fan RPM"),
                ("FAN_POLL", "Fan Poll Interval (s)", "How often to check fan speed"),
            ],
            "GPUControl": [
                ("GPU_MAX_FREQ", "GPU Max Frequency (MHz)", "Maximum GPU frequency in MHz"),
            ],
            "SleepControl": [
                ("BATTERY_DELAY", "Battery Delay (min)", "Idle time before sleep on battery"),
                ("BATTERY_BACKLIGHT", "Battery Backlight Timeout (min)", "Screen timeout on battery"),
                ("BATTERY_DIM_DELAY", "Battery Dim Delay (min)", "Screen dim delay on battery"),
                ("POWER_DELAY", "Power Delay (min)", "Idle time before sleep on AC power"),
                ("POWER_BACKLIGHT", "Power Backlight Timeout (min)", "Screen timeout on AC power"),
                ("POWER_DIM_DELAY", "Power Dim Delay (min)", "Screen dim delay on AC power"),
                ("AUDIO_DETECTION_BATTERY", "Audio Detection (Battery)", "Prevent sleep during audio on battery (0/1)"),
                ("AUDIO_DETECTION_POWER", "Audio Detection (Power)", "Prevent sleep during audio on AC (0/1)"),
                ("SUSPEND_MODE", "Suspend Mode", "Sleep mode: deep or s2idle"),
                ("LIDSLEEP_BATTERY", "Lid Sleep (Battery)", "Sleep when lid closed on battery (0/1)"),
                ("LIDSLEEP_POWER", "Lid Sleep (Power)", "Sleep when lid closed on AC (0/1)"),
            ],
            "Startup Services": [
                ("STARTUP_BATTERYCONTROL", "Start BatteryControl", "Enable BatteryControl at startup (0/1)"),
                ("STARTUP_POWERCONTROL", "Start PowerControl", "Enable PowerControl at startup (0/1)"),
                ("STARTUP_FANCONTROL", "Start FanControl", "Enable FanControl at startup (0/1)"),
                ("STARTUP_GPUCONTROL", "Start GPUControl", "Enable GPUControl at startup (0/1)"),
                ("STARTUP_SLEEPCONTROL", "Start SleepControl", "Enable SleepControl at startup (0/1)"),
            ],
        }
        
        row = 0
        for section_name, fields in sections.items():
            header = Gtk.Label()
            header.set_markup(f"<b><big>{section_name}</big></b>")
            header.set_halign(Gtk.Align.START)
            header.set_margin_top(15)
            header.set_margin_bottom(5)
            self.grid.attach(header, 0, row, 3, 1)
            row += 1
            
            separator = Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL)
            separator.set_margin_bottom(10)
            self.grid.attach(separator, 0, row, 3, 1)
            row += 1
            
            for key, label, tooltip in fields:
                lbl = Gtk.Label(label=label)
                lbl.set_halign(Gtk.Align.START)
                lbl.set_margin_start(20)
                lbl.set_tooltip_text(tooltip)
                self.grid.attach(lbl, 0, row, 1, 1)
                
                entry = Gtk.Entry()
                entry.set_width_chars(20)
                entry.set_tooltip_text(tooltip)
                self.grid.attach(entry, 1, row, 1, 1)
                
                tooltip_lbl = Gtk.Label()
                tooltip_lbl.set_markup(f"<small><span foreground='gray'>{tooltip}</span></small>")
                tooltip_lbl.set_halign(Gtk.Align.START)
                tooltip_lbl.set_line_wrap(True)
                tooltip_lbl.set_max_width_chars(50)
                self.grid.attach(tooltip_lbl, 2, row, 1, 1)
                
                self.widgets[key] = entry
                row += 1
    
    def load_config(self):
        """Load configuration from file"""
        self.config_path = self.path_entry.get_text()
        
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
            
            for key, entry in self.widgets.items():
                if key in self.config_data:
                    entry.set_text(self.config_data[key])
            
            self.show_info_dialog("Success", "Configuration loaded successfully!")
        except Exception as e:
            self.show_error_dialog("Error", f"Failed to load config: {str(e)}")
    
    def save_config(self):
        """Save configuration to file"""
        try:
            with open(self.config_path, 'r') as f:
                lines = f.readlines()
            
            new_lines = []
            for line in lines:
                if line.strip() and not line.strip().startswith('#'):
                    if '=' in line:
                        key = line.split('=', 1)[0].strip()
                        if key in self.widgets:
                            new_value = self.widgets[key].get_text()
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
    win = ConfigEditor()
    if win.config_path:
        win.connect("destroy", Gtk.main_quit)
        win.show_all()
        Gtk.main()

if __name__ == "__main__":
    main()
