#!/usr/bin/env python3
"""
ChromeOS_PowerControl GUI
"""

import math
import os
from pathlib import Path

import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, GLib

try:
    import cairo
    CAIRO_AVAILABLE = True
except ImportError:
    CAIRO_AVAILABLE = False

def find_available_theme(*candidates):
    theme_dirs = [
        Path("/usr/share/themes"),
        Path.home() / ".local/share/themes",
        Path.home() / ".themes",
    ]
    for name in candidates:
        for d in theme_dirs:
            if (d / name).exists():
                return name
    return candidates[-1]

def gpu_config_to_mhz(gpu_type: str, value: int) -> int:
    if gpu_type in ("mali", "adreno"):
        if value >= 10000:
            return value // 1_000_000
    return value

def gpu_mhz_to_config(gpu_type: str, mhz: int) -> int:
    if gpu_type in ("mali", "adreno"):
        return mhz * 1_000_000
    return mhz

_BG       = (0.10, 0.10, 0.10)
_PLOT_BG  = (0.07, 0.07, 0.07)
_GRID     = (0.22, 0.22, 0.22)
_AXIS     = (0.55, 0.55, 0.55)
_TEXT     = (0.85, 0.85, 0.85)
_DIM_TEXT = (0.55, 0.55, 0.55)
_CPU_C    = (0.20, 0.72, 1.00)
_FAN_C    = (1.00, 0.60, 0.18)
_BAT_C    = (0.30, 0.88, 0.45)
_GPU_C    = (0.78, 0.40, 1.00)

class BaseGraph(Gtk.DrawingArea):
    PAD = dict(left=50, right=18, top=28, bottom=38)

    def __init__(self, title, w=380, h=210):
        super().__init__()
        self.title = title
        self.set_size_request(w, h)
        self.connect("draw", self._on_draw)

    def _plot_rect(self, W, H):
        p = self.PAD
        return (p['left'], p['top'],
                W - p['left'] - p['right'],
                H - p['top']  - p['bottom'])

    def _to_screen(self, vx, vy, px, py, pw, ph, xr, yr):
        sx = px + (vx - xr[0]) / (xr[1] - xr[0]) * pw
        sy = py + ph - (vy - yr[0]) / (yr[1] - yr[0]) * ph
        return sx, sy

    def _draw_frame(self, cr, W, H, xr, yr, xlabel, ylabel, xticks=5, yticks=5):
        px, py, pw, ph = self._plot_rect(W, H)
        cr.set_source_rgb(*_BG)
        cr.paint()
        cr.set_source_rgb(*_TEXT)
        cr.set_font_size(12)
        ext = cr.text_extents(self.title)
        cr.move_to(W / 2 - ext[2] / 2, py - 8)
        cr.show_text(self.title)
        cr.set_source_rgb(*_PLOT_BG)
        cr.rectangle(px, py, pw, ph)
        cr.fill()
        cr.set_source_rgba(*_GRID, 1.0)
        cr.set_line_width(0.5)
        for i in range(xticks + 1):
            xi = px + pw * i / xticks
            cr.move_to(xi, py);  cr.line_to(xi, py + ph);  cr.stroke()
        for i in range(yticks + 1):
            yi = py + ph * i / yticks
            cr.move_to(px, yi);  cr.line_to(px + pw, yi);  cr.stroke()
        cr.set_source_rgb(*_AXIS)
        cr.set_line_width(1.2)
        cr.rectangle(px, py, pw, ph)
        cr.stroke()
        cr.set_source_rgb(*_TEXT)
        cr.set_font_size(9)
        for i in range(xticks + 1):
            xi  = px + pw * i / xticks
            val = xr[0] + (xr[1] - xr[0]) * i / xticks
            lbl = str(int(val))
            ext = cr.text_extents(lbl)
            cr.move_to(xi - ext[2] / 2, py + ph + 14)
            cr.show_text(lbl)
        for i in range(yticks + 1):
            yi  = py + ph - ph * i / yticks
            val = yr[0] + (yr[1] - yr[0]) * i / yticks
            lbl = str(int(val))
            ext = cr.text_extents(lbl)
            cr.move_to(px - ext[2] - 5, yi + 4)
            cr.show_text(lbl)

        cr.set_font_size(10)
        cr.set_source_rgb(*_DIM_TEXT)
        if xlabel:
            ext = cr.text_extents(xlabel)
            cr.move_to(px + pw / 2 - ext[2] / 2, py + ph + 30)
            cr.show_text(xlabel)
        if ylabel:
            cr.save()
            cr.translate(12, py + ph / 2)
            cr.rotate(-math.pi / 2)
            ext = cr.text_extents(ylabel)
            cr.move_to(-ext[2] / 2, 0)
            cr.show_text(ylabel)
            cr.restore()

        return px, py, pw, ph

    def _vmarker(self, cr, xi, py, ph, color, label=None):
        cr.set_source_rgba(*color, 0.75)
        cr.set_line_width(1.0)
        cr.set_dash([4, 3])
        cr.move_to(xi, py);  cr.line_to(xi, py + ph);  cr.stroke()
        cr.set_dash([])
        if label:
            cr.set_source_rgb(*color)
            cr.set_font_size(9)
            cr.move_to(xi + 3, py + 12)
            cr.show_text(label)

    def _filled_curve(self, cr, points, px, py, pw, ph, xr, yr, color):
        s = lambda vx, vy: self._to_screen(vx, vy, px, py, pw, ph, xr, yr)
        cr.set_source_rgba(*color, 0.18)
        sx0, sy0 = s(*points[0])
        cr.move_to(sx0, py + ph)
        cr.line_to(sx0, sy0)
        for pt in points[1:]:
            cr.line_to(*s(*pt))
        sxL, _ = s(*points[-1])
        cr.line_to(sxL, py + ph)
        cr.close_path()
        cr.fill()

        cr.set_source_rgb(*color)
        cr.set_line_width(2.2)
        cr.move_to(*s(*points[0]))
        for pt in points[1:]:
            cr.line_to(*s(*pt))
        cr.stroke()

    def _on_draw(self, widget, cr):
        pass

    def refresh(self):
        self.queue_draw()

class CPUCurveGraph(BaseGraph):
    """
    PowerControl Curve
    """
    def __init__(self, get_val):
        super().__init__("PowerControl Curve")
        self.get_val = get_val

    def _on_draw(self, widget, cr):
        W, H = widget.get_allocated_width(), widget.get_allocated_height()
        gv = self.get_val

        min_t  = gv("MIN_TEMP",     50)
        hot_t  = gv("HOTZONE",      70)
        max_t  = gv("MAX_TEMP",     85)
        min_p  = gv("MIN_PERF_PCT", 10)
        max_p  = gv("MAX_PERF_PCT", 100)

        xr = (30, 100);  yr = (0, 100)
        px, py, pw, ph = self._draw_frame(cr, W, H, xr, yr,
                                          "Temperature (°C)", "Performance (%)")
        s = lambda vx, vy: self._to_screen(vx, vy, px, py, pw, ph, xr, yr)

        d1 = hot_t - min_t
        d2 = max_t - hot_t

        hot_perf = (2 * d2 * max_p + d1 * min_p) / (2 * d2 + d1) if (2*d2 + d1) != 0 else (max_p + min_p) / 2

        x1, _ = s(hot_t, 0);  x2, _ = s(max_t, 0)
        cr.set_source_rgba(1.0, 0.70, 0.20, 0.10)
        cr.rectangle(x1, py, x2 - x1, ph);  cr.fill()

        x3 = px + pw
        cr.set_source_rgba(1.0, 0.30, 0.30, 0.12)
        cr.rectangle(x2, py, x3 - x2, ph);  cr.fill()
        
        points = [
            (xr[0], max_p),
            (min_t,  max_p),
            (hot_t,  hot_perf),
            (max_t,  min_p),
            (xr[1],  min_p),
        ]
        self._filled_curve(cr, points, px, py, pw, ph, xr, yr, _CPU_C)

        for temp, col, lbl in [
            (min_t, (0.40, 0.90, 0.40), f" {int(min_t)}°"),
            (hot_t, (1.00, 0.70, 0.20), f" {int(hot_t)}°"),
            (max_t, (1.00, 0.40, 0.30), f" {int(max_t)}°"),
        ]:
            xi, _ = s(temp, 0)
            self._vmarker(cr, xi, py, ph, col, lbl)

        for perf, col in [(max_p, _CPU_C), (min_p, (0.7, 0.7, 0.7))]:
            _, yi = s(0, perf)
            cr.set_source_rgba(*col, 0.5)
            cr.set_line_width(0.8)
            cr.set_dash([2, 4])
            cr.move_to(px, yi);  cr.line_to(px + pw, yi);  cr.stroke()
            cr.set_dash([])

class FanCurveGraph(BaseGraph):
    """
    FanControl Curve
    """
    def __init__(self, get_val):
        super().__init__("FanControl Curve")
        self.get_val = get_val

    def _on_draw(self, widget, cr):
        W, H = widget.get_allocated_width(), widget.get_allocated_height()
        gv = self.get_val

        fmin_t  = gv("FAN_MIN_TEMP", 40)
        fmax_t  = gv("FAN_MAX_TEMP", 80)
        min_fan = gv("MIN_FAN",       0)
        max_fan = gv("MAX_FAN",      100)

        xr = (30, 100);  yr = (0, 100)
        px, py, pw, ph = self._draw_frame(cr, W, H, xr, yr,
                                          "Temperature (°C)", "Fan Speed (%)")
        s = lambda vx, vy: self._to_screen(vx, vy, px, py, pw, ph, xr, yr)

        points = [
            (xr[0],  min_fan),
            (fmin_t, min_fan),
            (fmax_t, max_fan),
            (xr[1],  max_fan),
        ]
        self._filled_curve(cr, points, px, py, pw, ph, xr, yr, _FAN_C)

        for temp, col, lbl in [
            (fmin_t, (0.40, 0.90, 0.40), f"{int(fmin_t)}°"),
            (fmax_t, (1.00, 0.40, 0.30), f"{int(fmax_t)}°"),
        ]:
            xi, _ = s(temp, 0)
            self._vmarker(cr, xi, py, ph, col, lbl)

        for speed, col in [(min_fan, (0.6, 0.6, 0.6)), (max_fan, _FAN_C)]:
            _, yi = s(0, speed)
            cr.set_source_rgba(*col, 0.45)
            cr.set_line_width(0.8)
            cr.set_dash([2, 4])
            cr.move_to(px, yi);  cr.line_to(px + pw, yi);  cr.stroke()
            cr.set_dash([])


class SleepTimelineGraph(Gtk.DrawingArea):
    """
    SleepControl Bars
    """
    PAD = dict(left=90, right=18, top=36, bottom=12)
    ROW_H = 32
    ROW_GAP = 14

    _SEG_COLORS = [
        (0.25, 0.55, 0.85),
        (0.12, 0.30, 0.65),
        (0.06, 0.12, 0.35),
    ]
    _SEG_LABELS = ["Dim Display ➜", "Display Off ➜", "Sleep ➜"]

    def __init__(self, get_val):
        super().__init__()
        self.get_val = get_val
        self.set_size_request(760, 148)
        self.connect("draw", self._on_draw)

    def _draw_row(self, cr, W, label, dim, backlight, delay, y0):
        p = self.PAD
        pw = W - p['left'] - p['right']
        px = p['left']
        ph = self.ROW_H

        total = max(delay, 1)

        cr.set_source_rgb(*_TEXT)
        cr.set_font_size(10)
        ext = cr.text_extents(label)
        cr.move_to(px - ext[2] - 10, y0 + ph / 2 + 4)
        cr.show_text(label)

        cr.set_source_rgb(*_PLOT_BG)
        cr.rectangle(px, y0, pw, ph)
        cr.fill()
        cr.set_source_rgb(*_AXIS)
        cr.set_line_width(0.8)
        cr.rectangle(px, y0, pw, ph)
        cr.stroke()

        boundaries = [0, dim, backlight, delay]
        for i, (col, seg_label) in enumerate(zip(self._SEG_COLORS, self._SEG_LABELS)):
            t0, t1 = boundaries[i], boundaries[i + 1]
            x0 = px + (t0 / total) * pw
            x1 = px + (t1 / total) * pw
            sw = x1 - x0
            if sw < 1:
                continue
            cr.set_source_rgb(*col)
            cr.rectangle(x0, y0, sw, ph)
            cr.fill()
            cr.set_source_rgba(1, 1, 1, 0.06)
            cr.rectangle(x0, y0, sw, ph / 2)
            cr.fill()
            cr.set_source_rgba(0, 0, 0, 0.4)
            cr.set_line_width(0.5)
            cr.rectangle(x0, y0, sw, ph)
            cr.stroke()
            if sw > 36:
                cr.set_source_rgb(0.85, 0.85, 0.85)
                cr.set_font_size(9)
                ext = cr.text_extents(seg_label)
                if ext[2] < sw - 6:
                    cr.move_to(x0 + sw / 2 - ext[2] / 2, y0 + ph / 2 + 4)
                    cr.show_text(seg_label)
        cr.set_source_rgb(*_DIM_TEXT)
        cr.set_font_size(8)
        for t in [dim, backlight, delay]:
            xi = px + (t / total) * pw
            mins = int(t)
            if mins >= 60:
                lbl = f"{mins // 60}h{mins % 60:02d}m" if mins % 60 else f"{mins // 60}h"
            else:
                lbl = f"{mins}m"
            ext = cr.text_extents(lbl)
            cr.move_to(xi - ext[2] / 2, y0 + ph + 12)
            cr.show_text(lbl)
            cr.set_source_rgba(*_AXIS, 0.6)
            cr.set_line_width(0.8)
            cr.move_to(xi, y0 + ph)
            cr.line_to(xi, y0 + ph + 4)
            cr.stroke()
            cr.set_source_rgb(*_DIM_TEXT)

    def _on_draw(self, widget, cr):
        W, H = widget.get_allocated_width(), widget.get_allocated_height()
        gv = self.get_val

        cr.set_source_rgb(*_BG)
        cr.paint()

        cr.set_source_rgb(*_TEXT)
        cr.set_font_size(12)
        title = "SleepControl"
        ext = cr.text_extents(title)
        cr.move_to(W / 2 - ext[2] / 2, 20)
        cr.show_text(title)

        bat_dim   = gv("BATTERY_DIM_DELAY",  5)
        bat_bl    = gv("BATTERY_BACKLIGHT",  10)
        bat_delay = gv("BATTERY_DELAY",      15)
        ac_dim    = gv("POWER_DIM_DELAY",    10)
        ac_bl     = gv("POWER_BACKLIGHT",    20)
        ac_delay  = gv("POWER_DELAY",        30)

        y0 = self.PAD['top']
        self._draw_row(cr, W, " Battery",
                       bat_dim, bat_bl, bat_delay, y0)
        self._draw_row(cr, W, " AC Power",
                       ac_dim, ac_bl, ac_delay, y0 + self.ROW_H + self.ROW_GAP)

        lx = W - self.PAD['right'] - 180
        ly = H - 14
        for i, (col, lbl) in enumerate(zip(self._SEG_COLORS, self._SEG_LABELS)):
            x = lx + i * 62
            cr.set_source_rgb(*col)
            cr.rectangle(x, ly - 8, 10, 8)
            cr.fill()
            cr.set_source_rgb(*_DIM_TEXT)
            cr.set_font_size(8)
            cr.move_to(x + 13, ly)
            cr.show_text(lbl)

    def refresh(self):
        self.queue_draw()

class GaugeGraph(Gtk.DrawingArea):
    PAD = dict(left=18, right=18, top=30, bottom=10)
    BAR_H = 34

    def __init__(self, title, get_val, key, color, fmt_fn=None, w=370, h=90):
        super().__init__()
        self.title   = title
        self.get_val = get_val
        self.key     = key
        self.color   = color
        self.fmt_fn  = fmt_fn or (lambda v, mx: f"{int(v)}")
        self.set_size_request(w, h)
        self.connect("draw", self._on_draw)

    def _fraction(self):
        """Override return"""
        return 0.5, 1.0

    def _on_draw(self, widget, cr):
        W, H = widget.get_allocated_width(), widget.get_allocated_height()
        p    = self.PAD
        px   = p['left'];  py = p['top']
        pw   = W - p['left'] - p['right']
        ph   = self.BAR_H

        cr.set_source_rgb(*_BG)
        cr.paint()
        cr.set_source_rgb(*_TEXT)
        cr.set_font_size(12)
        ext = cr.text_extents(self.title)
        cr.move_to(W / 2 - ext[2] / 2, py - 8)
        cr.show_text(self.title)

        cur, mx = self._fraction()
        frac = max(0.0, min(1.0, cur / mx if mx else 0))

        cr.set_source_rgb(*_PLOT_BG)
        cr.rectangle(px, py, pw, ph)
        cr.fill()
        cr.set_source_rgb(*_AXIS)
        cr.set_line_width(1.0)
        cr.rectangle(px, py, pw, ph)
        cr.stroke()

        fill_w = pw * frac
        if fill_w > 1 and CAIRO_AVAILABLE:
            pat = cairo.LinearGradient(px, 0, px + fill_w, 0)
            
            if self.key == "CHARGE_MAX":
                pat.add_color_stop_rgb(0.0, 0.00, 0.22, 0.00)
                pat.add_color_stop_rgb(0.5, 0.08, 0.50, 0.08)
                pat.add_color_stop_rgb(1.0, 0.15, 0.75, 0.15)
            else:
                r, g, b = self.color
                pat.add_color_stop_rgb(0.0, r * 0.15, g * 0.45, b * 0.45)
                pat.add_color_stop_rgb(0.8, r, g, b)
                pat.add_color_stop_rgb(1.0, min(r + 0.1, 1), min(g + 0.1, 1), min(b + 0.1, 1))
                
            cr.set_source(pat)
        else:
            cr.set_source_rgb(*self.color)
            
        cr.rectangle(px, py, fill_w, ph)
        cr.fill()

        cr.set_source_rgba(1, 1, 1, 0.07)
        cr.rectangle(px, py, fill_w, ph / 2)
        cr.fill()

        label = self.fmt_fn(cur, mx)
        cr.set_source_rgb(1, 1, 1)
        cr.set_font_size(13)
        ext = cr.text_extents(label)
        cr.move_to(px + pw / 2 - ext[2] / 2, py + ph / 2 + 5)
        cr.show_text(label)

        cr.set_source_rgba(*_AXIS, 0.4)
        cr.set_line_width(0.7)
        for frac_tick in [0.25, 0.50, 0.75]:
            xt = px + pw * frac_tick
            cr.move_to(xt, py + ph - 6)
            cr.line_to(xt, py + ph)
            cr.stroke()

    def refresh(self):
        self.queue_draw()



class BatteryGauge(GaugeGraph):
    def __init__(self, get_val):
        super().__init__("BatteryControl", get_val, "CHARGE_MAX", _BAT_C,
                         fmt_fn=lambda v, mx: f"Limited to: {int(v)}%")

    def _fraction(self):
        v = self.get_val("CHARGE_MAX", 80)
        return v, 100


class GPUGauge(GaugeGraph):
    def __init__(self, get_val, get_gpu_max_fn):
        super().__init__("GPUControl", get_val, "GPU_MAX_FREQ", _GPU_C,
                         fmt_fn=lambda v, mx: f"{int(v)} MHz  /  {int(mx)} MHz max")
        self.get_gpu_max = get_gpu_max_fn

    def _fraction(self):
        cur = self.get_val("GPU_MAX_FREQ", 500)
        mx  = self.get_gpu_max()
        return cur, max(mx, 1)


class GraphPanel(Gtk.ScrolledWindow):
    def __init__(self, get_val, get_gpu_max_fn):
        super().__init__()
        self.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)

        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        vbox.set_border_width(12)
        self.add(vbox)

        row1 = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        vbox.pack_start(row1, False, False, 0)

        self.cpu_graph = CPUCurveGraph(get_val)
        row1.pack_start(self.cpu_graph, True, True, 0)

        self.fan_graph = FanCurveGraph(get_val)
        row1.pack_start(self.fan_graph, True, True, 0)

        row3 = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        vbox.pack_start(row3, False, False, 0)

        self.bat_gauge = BatteryGauge(get_val)
        row3.pack_start(self.bat_gauge, True, True, 0)

        self.gpu_gauge = GPUGauge(get_val, get_gpu_max_fn)
        row3.pack_start(self.gpu_gauge, True, True, 0)
        
        self.sleep_graph = SleepTimelineGraph(get_val)
        vbox.pack_start(self.sleep_graph, False, False, 0)

        self._graphs = [
            self.cpu_graph, self.fan_graph,
            self.sleep_graph,
            self.bat_gauge, self.gpu_gauge,
        ]

    def refresh_all(self):
        for g in self._graphs:
            g.refresh()

class ConfigEditor(Gtk.Window):
    def __init__(self):
        settings = Gtk.Settings.get_default()
        settings.set_property("gtk-application-prefer-dark-theme", True)
        super().__init__(title="ChromeOS_PowerControl GUI")
        self.set_default_size(820, 680)

        headerbar = Gtk.HeaderBar()
        headerbar.set_show_close_button(True)
        headerbar.props.title = "ChromeOS_PowerControl GUI"
        headerbar.set_decoration_layout("menu:minimize,maximize,close")
        self.set_titlebar(headerbar)

        self.reload_btn = Gtk.Button()
        reload_icon = Gtk.Image.new_from_icon_name("view-refresh-symbolic",
                                                    Gtk.IconSize.BUTTON)
        self.reload_btn.set_image(reload_icon)
        self.reload_btn.set_tooltip_text("Reload config from disk")
        self.reload_btn.connect("clicked", self.on_reload_clicked)
        headerbar.pack_end(self.reload_btn)

        self.config_path      = self.find_config_file()
        self.config_data      = {}
        self.widgets          = {}
        self.original_gpu_max = None
        self.gpu_type         = None
        self.updating_constraints = False
        self.initial_load     = True
        self.focusable_widgets = []

        if not self.config_path:
            self.show_error_dialog(
                "Config File Not Found",
                "Could not find config file at:\n"
                "/mnt/chromeos/MyFiles/Downloads/ChromeOS_PowerControl_Config/config\n"
                "/mnt/shared/MyFiles/Downloads/ChromeOS_PowerControl_Config/config\n"
                "/usr/local/bin/ChromeOS_PowerControl_Config/config\n"
                "/home/chronos/user/MyFiles/Downloads/ChromeOS_PowerControl_Config/config\n\n"
                "Please ensure the folder is shared to Crostini/Chard."
            )
            self.destroy()
            return

        self.create_ui()
        self.load_config()
        self.setup_constraints()
        self.connect_graph_signals()
        self.setup_keyboard_navigation()
        self.initial_load = False

    def find_config_file(self):
        possible_paths = [
            "/mnt/chromeos/MyFiles/Downloads/ChromeOS_PowerControl_Config/config",
            "/usr/local/bin/ChromeOS_PowerControl_Config/config",
            os.path.expanduser(
                "/home/chronos/user/MyFiles/Downloads/ChromeOS_PowerControl_Config/config"),
            "/mnt/shared/MyFiles/Downloads/ChromeOS_PowerControl_Config/config",
        ]
        for path in possible_paths:
            if os.path.exists(path):
                return path
        return None

    def get_widget_value(self, key, default=0.0):
        if key in self.widgets:
            w = self.widgets[key]
            if isinstance(w, Gtk.Scale):
                return w.get_value()
            if isinstance(w, Gtk.Switch):
                return 1.0 if w.get_active() else 0.0
        return float(default)

    def get_gpu_max(self):
        if self.original_gpu_max and self.gpu_type:
            return float(gpu_config_to_mhz(self.gpu_type, self.original_gpu_max))
        if "GPU_MAX_FREQ" in self.widgets:
            adj = self.widgets["GPU_MAX_FREQ"].get_adjustment()
            return adj.get_upper()
        return 2000.0

    def connect_graph_signals(self):
        graph_keys = [
            "MIN_TEMP", "HOTZONE", "MAX_TEMP", "MIN_PERF_PCT", "MAX_PERF_PCT",
            "MIN_FAN", "MAX_FAN", "FAN_MIN_TEMP", "FAN_MAX_TEMP",
            "CHARGE_MAX", "GPU_MAX_FREQ",
            "BATTERY_DIM_DELAY", "BATTERY_BACKLIGHT", "BATTERY_DELAY",
            "POWER_DIM_DELAY",  "POWER_BACKLIGHT",  "POWER_DELAY",
        ]
        for key in graph_keys:
            if key in self.widgets:
                w = self.widgets[key]
                if isinstance(w, Gtk.Scale):
                    w.connect("value-changed", lambda *_: self.graph_panel.refresh_all())
                elif isinstance(w, Gtk.Switch):
                    w.connect("notify::active", lambda *_: self.graph_panel.refresh_all())

    def setup_keyboard_navigation(self):
        self.connect("key-press-event", self.on_key_press)

    def on_key_press(self, widget, event):
        keyval = event.keyval
        if keyval in (Gdk.KEY_Up, Gdk.KEY_Down):
            focus = self.get_focus()
            if focus is None:
                if self.focusable_widgets:
                    self.focusable_widgets[0].grab_focus()
                return True
            try:
                idx = self.focusable_widgets.index(focus)
            except ValueError:
                return False
            if keyval == Gdk.KEY_Up:
                idx = (idx - 1) % len(self.focusable_widgets)
            else:
                idx = (idx + 1) % len(self.focusable_widgets)
            self.focusable_widgets[idx].grab_focus()
            return True
        return False

    def create_ui(self):
        main_vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        self.add(main_vbox)

        notebook = Gtk.Notebook()
        notebook.set_tab_pos(Gtk.PositionType.TOP)
        main_vbox.pack_start(notebook, True, True, 0)

        settings_vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        settings_vbox.set_border_width(10)

        scrolled = Gtk.ScrolledWindow()
        scrolled.set_vexpand(True)
        scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        settings_vbox.pack_start(scrolled, True, True, 0)

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
        button_box.set_border_width(8)
        settings_vbox.pack_start(button_box, False, False, 0)

        self.save_btn = Gtk.Button(label="Apply")
        self.save_btn.connect("clicked", self.on_save_clicked)
        button_box.pack_start(self.save_btn, False, False, 0)
        self.focusable_widgets.append(self.save_btn)

        exit_btn = Gtk.Button(label="Exit")
        exit_btn.connect("clicked", lambda x: self.destroy())
        button_box.pack_start(exit_btn, False, False, 0)
        self.focusable_widgets.append(exit_btn)

        tab1_label = Gtk.Label(label="⚙  Settings")
        notebook.append_page(settings_vbox, tab1_label)

        if CAIRO_AVAILABLE:
            self.graph_panel = GraphPanel(self.get_widget_value, self.get_gpu_max)
            tab2_label = Gtk.Label(label="◫  Live Graphs")
            notebook.append_page(self.graph_panel, tab2_label)
            notebook.connect("switch-page", self._on_tab_switch)
        else:
            no_cairo = Gtk.Label(label="pycairo not available — install python3-gi-cairo")
            tab2_label = Gtk.Label(label="◫  Live Graphs")
            notebook.append_page(no_cairo, tab2_label)

    def _on_tab_switch(self, notebook, page, page_num):
        if page_num == 1:
            GLib.idle_add(self.graph_panel.refresh_all)

    def create_slider(self, min_val, max_val, step=1):
        scale = Gtk.Scale.new_with_range(
            Gtk.Orientation.HORIZONTAL, min_val, max_val, step)
        scale.set_digits(0 if step >= 1 else 1)
        scale.set_value_pos(Gtk.PositionType.RIGHT)
        scale.set_hexpand(True)
        scale.set_size_request(400, -1)
        return scale

    def create_slider_with_spinbutton(self, min_val, max_val, step=1):
        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=5)
        scale = Gtk.Scale.new_with_range(
            Gtk.Orientation.HORIZONTAL, min_val, max_val, step)
        scale.set_digits(0 if step >= 1 else 1)
        scale.set_value_pos(Gtk.PositionType.RIGHT)
        scale.set_hexpand(True)
        scale.set_size_request(100, -1)
        scale.set_draw_value(False)
        adjustment = Gtk.Adjustment(
            value=min_val, lower=min_val, upper=max_val,
            step_increment=step, page_increment=step * 10)
        spinbutton = Gtk.SpinButton(
            adjustment=adjustment, climb_rate=step, digits=0)
        spinbutton.set_width_chars(6)

        def on_scale_changed(s):
            if spinbutton.get_value() != s.get_value():
                spinbutton.set_value(s.get_value())

        def on_spin_changed(s):
            if scale.get_value() != s.get_value():
                scale.set_value(s.get_value())

        scale.connect("value-changed", on_scale_changed)
        spinbutton.connect("value-changed", on_spin_changed)
        box.pack_start(scale, True, True, 0)
        box.pack_start(spinbutton, False, False, 0)
        return box, scale, spinbutton

    def create_switch(self):
        switch = Gtk.Switch()
        switch.set_halign(Gtk.Align.START)
        return switch

    def create_combo(self, options):
        combo = Gtk.ComboBoxText()
        for option in options:
            combo.append_text(option)
        return combo

    def create_config_sections(self):
        sections = {
            "PowerControl": [
                ("MAX_TEMP",      "Maximum Temperature (°C)",  "slider", 30, 95,   1,   False),
                ("HOTZONE",       "Hotzone Temperature (°C)",  "slider", 30, 90,   1,   False),
                ("MIN_TEMP",      "Minimum Temperature (°C)",  "slider", 30, 90,   1,   False),
                ("MAX_PERF_PCT",  "Maximum Performance (%)",   "slider", 10, 100,  1,   False),
                ("MIN_PERF_PCT",  "Minimum Performance (%)",   "slider", 10, 100,  1,   False),
                ("RAMP_UP",       "Ramp Up Speed (%)",         "slider",  1, 50,   1,   False),
                ("RAMP_DOWN",     "Ramp Down Speed (%)",       "slider",  1, 50,   1,   False),
                ("CPU_POLL",      "CPU Poll Interval (s)",     "slider", 0.1, 5.0, 0.1, False),
            ],
            "GPUControl": [
                ("GPU_MAX_FREQ",  "GPU Max Frequency (MHz)",   "slider", 100, 2000, 10, False),
            ],
            "FanControl": [
                ("MIN_FAN",       "Minimum Fan Speed (%)",     "slider",  0, 100,  1,   False),
                ("MAX_FAN",       "Maximum Fan Speed (%)",     "slider",  0, 100,  1,   False),
                ("FAN_MIN_TEMP",  "Fan Minimum Temp (°C)",     "slider", 30,  70,  1,   False),
                ("FAN_MAX_TEMP",  "Fan Maximum Temp (°C)",     "slider", 30,  94,  1,   False),
                ("STEP_UP",       "Fan Step Up (%)",           "slider",  1,  20,  1,   False),
                ("STEP_DOWN",     "Fan Step Down (%)",         "slider",  1,  20,  1,   False),
                ("FAN_POLL",      "Fan Poll Interval (s)",     "slider",  1,  10,  1,   False),
            ],
            "BatteryControl": [
                ("CHARGE_MAX",    "Maximum Charge (%)",        "slider", 20, 100,  1,   False),
            ],
            "SleepControl - Battery": [
                ("BATTERY_DIM_DELAY", "Dim Delay (minutes)",     "slider", 1, 1440, 1, True),
                ("BATTERY_BACKLIGHT", "Display Off (minutes)",   "slider", 1, 1440, 1, True),
                ("BATTERY_DELAY",     "Sleep Delay (minutes)",   "slider", 1, 1440, 1, True),
                ("AUDIO_DETECTION_BATTERY", "Audio Detection",   "switch", None, None, None, False),
                ("LIDSLEEP_BATTERY",        "Lid Sleep",         "switch", None, None, None, False),
            ],
            "SleepControl - AC Power": [
                ("POWER_DIM_DELAY", "Dim Delay (minutes)",       "slider", 1, 4320, 1, True),
                ("POWER_BACKLIGHT", "Display Off (minutes)",     "slider", 1, 4320, 1, True),
                ("POWER_DELAY",     "Sleep Delay (minutes)",     "slider", 1, 4320, 1, True),
                ("AUDIO_DETECTION_POWER", "Audio Detection",     "switch", None, None, None, False),
                ("LIDSLEEP_POWER",        "Lid Sleep",           "switch", None, None, None, False),
            ],
            "Start on Boot": [
                ("STARTUP_BATTERYCONTROL", "BatteryControl",     "switch", None, None, None, False),
                ("STARTUP_POWERCONTROL",   "PowerControl",       "switch", None, None, None, False),
                ("STARTUP_FANCONTROL",     "FanControl",         "switch", None, None, None, False),
                ("STARTUP_GPUCONTROL",     "GPUControl",         "switch", None, None, None, False),
                ("STARTUP_SLEEPCONTROL",   "SleepControl",       "switch", None, None, None, False),
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
                key         = field[0]
                label       = field[1]
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
                    min_val, max_val, step, with_spinbutton = (
                        field[3], field[4], field[5], field[6])
                    if key == "GPU_MAX_FREQ" and self.original_gpu_max:
                        display_max = gpu_config_to_mhz(self.gpu_type, self.original_gpu_max)
                        display_min = max(100, int(display_max * 0.1))
                        max_val = display_max
                        min_val = display_min
                    if with_spinbutton:
                        box, scale, spinbutton = self.create_slider_with_spinbutton(
                            min_val, max_val, step)
                        self.grid.attach(box, 1, row, 1, 1)
                        self.widgets[key] = scale
                        self.focusable_widgets.append(scale)
                    else:
                        widget = self.create_slider(min_val, max_val, step)
                        self.grid.attach(widget, 1, row, 1, 1)
                        self.widgets[key] = widget
                        self.focusable_widgets.append(widget)

                elif widget_type == "switch":
                    widget = self.create_switch()
                    self.grid.attach(widget, 1, row, 1, 1)
                    self.widgets[key] = widget
                    self.focusable_widgets.append(widget)

                elif widget_type == "combo":
                    options = field[3]
                    widget  = self.create_combo(options)
                    self.grid.attach(widget, 1, row, 1, 1)
                    self.widgets[key] = widget
                    self.focusable_widgets.append(widget)

                row += 1

    def setup_constraints(self):
        pairs = [
            (["MIN_TEMP", "HOTZONE", "MAX_TEMP"],
             self.on_temp_constraint),
            (["MIN_PERF_PCT", "MAX_PERF_PCT"],
             self.on_perf_constraint),
            (["MIN_FAN", "MAX_FAN"],
             self.on_fan_speed_constraint),
            (["FAN_MIN_TEMP", "FAN_MAX_TEMP"],
             self.on_fan_temp_constraint),
            (["BATTERY_DIM_DELAY", "BATTERY_BACKLIGHT", "BATTERY_DELAY"],
             self.on_battery_sleep_constraint),
            (["POWER_DIM_DELAY", "POWER_BACKLIGHT", "POWER_DELAY"],
             self.on_power_sleep_constraint),
        ]
        for keys, handler in pairs:
            if all(k in self.widgets for k in keys):
                for k in keys:
                    self.widgets[k].connect("value-changed", handler)

    def on_temp_constraint(self, scale):
        if self.updating_constraints:
            return
        self.updating_constraints = True
        min_t = self.widgets["MIN_TEMP"].get_value()
        hot   = self.widgets["HOTZONE"].get_value()
        max_t = self.widgets["MAX_TEMP"].get_value()
        if min_t >= hot:
            self.widgets["MIN_TEMP"].set_value(hot - 1)
        if min_t >= max_t:
            self.widgets["MIN_TEMP"].set_value(max_t - 2)
        if hot <= min_t:
            self.widgets["HOTZONE"].set_value(min_t + 1)
        if hot >= max_t:
            self.widgets["HOTZONE"].set_value(max_t - 1)
        if max_t <= hot:
            self.widgets["MAX_TEMP"].set_value(hot + 1)
        if max_t <= min_t:
            self.widgets["MAX_TEMP"].set_value(min_t + 2)
        self.updating_constraints = False

    def on_perf_constraint(self, scale):
        if self.updating_constraints:
            return
        self.updating_constraints = True
        mn = self.widgets["MIN_PERF_PCT"].get_value()
        mx = self.widgets["MAX_PERF_PCT"].get_value()
        if mn > mx:
            self.widgets["MAX_PERF_PCT"].set_value(mn)
        if mx < mn:
            self.widgets["MIN_PERF_PCT"].set_value(mx)
        self.updating_constraints = False

    def on_fan_speed_constraint(self, scale):
        if self.updating_constraints:
            return
        self.updating_constraints = True
        mn = self.widgets["MIN_FAN"].get_value()
        mx = self.widgets["MAX_FAN"].get_value()
        if mn > mx:
            self.widgets["MAX_FAN"].set_value(mn)
        if mx < mn:
            self.widgets["MIN_FAN"].set_value(mx)
        self.updating_constraints = False

    def on_fan_temp_constraint(self, scale):
        if self.updating_constraints:
            return
        self.updating_constraints = True
        mn = self.widgets["FAN_MIN_TEMP"].get_value()
        mx = self.widgets["FAN_MAX_TEMP"].get_value()
        if mn > mx:
            self.widgets["FAN_MAX_TEMP"].set_value(mn)
        if mx < mn:
            self.widgets["FAN_MIN_TEMP"].set_value(mx)
        self.updating_constraints = False

    def on_battery_sleep_constraint(self, scale):
        if self.updating_constraints or self.initial_load:
            return
        self.updating_constraints = True
        dim      = self.widgets["BATTERY_DIM_DELAY"].get_value()
        backlight = self.widgets["BATTERY_BACKLIGHT"].get_value()
        delay    = self.widgets["BATTERY_DELAY"].get_value()
        if dim >= backlight:
            self.widgets["BATTERY_DIM_DELAY"].set_value(backlight - 1)
        if backlight >= delay:
            self.widgets["BATTERY_BACKLIGHT"].set_value(delay - 1)
        self.updating_constraints = False

    def on_power_sleep_constraint(self, scale):
        if self.updating_constraints or self.initial_load:
            return
        self.updating_constraints = True
        dim      = self.widgets["POWER_DIM_DELAY"].get_value()
        backlight = self.widgets["POWER_BACKLIGHT"].get_value()
        delay    = self.widgets["POWER_DELAY"].get_value()
        if dim >= backlight:
            self.widgets["POWER_DIM_DELAY"].set_value(backlight - 1)
        if backlight >= delay:
            self.widgets["POWER_BACKLIGHT"].set_value(delay - 1)
        self.updating_constraints = False

    def load_config(self):
        if not os.path.exists(self.config_path):
            self.show_error_dialog("Error",
                                   f"Config file not found: {self.config_path}")
            return
        self.config_data = {}
        try:
            with open(self.config_path, 'r') as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith('#') and '=' in line:
                        key, value = line.split('=', 1)
                        self.config_data[key.strip()] = value.strip()

            if "ORIGINAL_GPU_MAX_FREQ" in self.config_data:
                raw = self.config_data["ORIGINAL_GPU_MAX_FREQ"]
                if raw:
                    self.original_gpu_max = int(raw)
                    self.gpu_type = self.config_data.get("GPU_TYPE", "intel").lower()
                    if "GPU_MAX_FREQ" in self.widgets:
                        display_max = gpu_config_to_mhz(self.gpu_type, self.original_gpu_max)
                        display_min = max(100, int(display_max * 0.1))
                        self.widgets["GPU_MAX_FREQ"].set_range(display_min, display_max)

            self.updating_constraints = True
            for key, widget in self.widgets.items():
                if key in self.config_data:
                    value = self.config_data[key]
                    if isinstance(widget, Gtk.Scale):
                        try:
                            if key == "GPU_MAX_FREQ":
                                if value:
                                    widget.set_value(
                                        gpu_config_to_mhz(self.gpu_type, int(value)))
                            else:
                                widget.set_value(float(value))
                        except ValueError:
                            widget.set_value(0)
                    elif isinstance(widget, Gtk.Switch):
                        widget.set_active(value == "1")
                    elif isinstance(widget, Gtk.ComboBoxText):
                        idx   = 0
                        model = widget.get_model()
                        for i, row in enumerate(model):
                            if row[0] == value:
                                idx = i
                                break
                        widget.set_active(idx)
            self.updating_constraints = False

        except Exception as e:
            self.updating_constraints = False
            self.show_error_dialog("Error", f"Failed to load config: {e}")

    def save_config(self):
        sleep_keys = [
            "BATTERY_DELAY", "BATTERY_BACKLIGHT", "BATTERY_DIM_DELAY",
            "POWER_DELAY",   "POWER_BACKLIGHT",   "POWER_DIM_DELAY",
        ]
        try:
            with open(self.config_path, 'r') as f:
                lines = f.readlines()

            new_lines = []
            for line in lines:
                stripped = line.strip()
                if stripped and not stripped.startswith('#') and '=' in stripped:
                    key = stripped.split('=', 1)[0].strip()
                    if key in self.widgets:
                        widget = self.widgets[key]
                        if isinstance(widget, Gtk.Scale):
                            value = widget.get_value()
                            if key in sleep_keys:
                                new_value = str(int(value))
                            elif key == "CPU_POLL":
                                new_value = f"{value:.1f}"
                            elif key == "GPU_MAX_FREQ":
                                new_value = str(gpu_mhz_to_config(self.gpu_type, int(value)))
                            else:
                                new_value = str(int(value))
                        elif isinstance(widget, Gtk.Switch):
                            new_value = "1" if widget.get_active() else "0"
                        elif isinstance(widget, Gtk.ComboBoxText):
                            new_value = widget.get_active_text()
                        new_lines.append(f"{key}={new_value}\n")
                    else:
                        new_lines.append(line)
                else:
                    new_lines.append(line)

            with open(self.config_path, 'w') as f:
                f.writelines(new_lines)
            self.show_save_success()

        except PermissionError:
            self.show_error_dialog("Permission Denied",
                                   "Run: sudo chown 1000:1000 to the config file.")
        except Exception as e:
            self.show_error_dialog("Error", f"Failed to save config: {e}")

    def show_save_success(self):
        original = self.save_btn.get_label()
        self.save_btn.set_label("Saved!")
        css = Gtk.CssProvider()
        css.load_from_data(b"button { background: #4caf50; color: white; }")
        ctx = self.save_btn.get_style_context()
        ctx.add_provider(css, Gtk.STYLE_PROVIDER_PRIORITY_USER)

        def reset():
            self.save_btn.set_label(original)
            ctx.remove_provider(css)
            return False
        GLib.timeout_add(1500, reset)

    def show_reload_success(self):
        css = Gtk.CssProvider()
        css.load_from_data(b"button { background: #2196f3; color: white; }")
        ctx = self.reload_btn.get_style_context()
        ctx.add_provider(css, Gtk.STYLE_PROVIDER_PRIORITY_USER)

        def reset():
            ctx.remove_provider(css)
            return False
        GLib.timeout_add(1000, reset)

    def on_reload_clicked(self, button):
        self.load_config()
        if CAIRO_AVAILABLE:
            self.graph_panel.refresh_all()
        self.show_reload_success()

    def on_save_clicked(self, button):
        self.save_config()

    def show_error_dialog(self, title, message):
        dialog = Gtk.MessageDialog(
            transient_for=self, flags=0,
            message_type=Gtk.MessageType.ERROR,
            buttons=Gtk.ButtonsType.OK, text=title)
        dialog.format_secondary_text(message)
        dialog.run()
        dialog.destroy()

    def show_info_dialog(self, title, message):
        dialog = Gtk.MessageDialog(
            transient_for=self, flags=0,
            message_type=Gtk.MessageType.INFO,
            buttons=Gtk.ButtonsType.OK, text=title)
        dialog.format_secondary_text(message)
        dialog.run()
        dialog.destroy()

def main():
    os.environ['GDK_RENDERING'] = 'gl'
    os.environ['GSK_RENDERER']  = 'gl'
    os.environ['GDK_GL']        = '1'

    settings = Gtk.Settings.get_default()
    settings.set_property("gtk-application-prefer-dark-theme", True)
    theme = find_available_theme("Breeze-Dark", "Adwaita-dark")
    settings.set_property("gtk-theme-name", theme)
    settings.set_property("gtk-decoration-layout", "menu:minimize,maximize,close")

    win = ConfigEditor()
    if win.config_path:
        win.connect("destroy", Gtk.main_quit)
        win.show_all()
        Gtk.main()

if __name__ == "__main__":
    main()
