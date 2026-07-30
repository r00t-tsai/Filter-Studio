<div align="center">
  <img width="312" height="312" alt="record-button" src="https://github.com/user-attachments/assets/6efc45b2-5330-45fb-850c-c7b699ac13f1" />
</div>

# <p align="center">Filter Studio </p>

### <p align="center">*A lightweight tool that manages screen brightness and color filters.* </p>

---
<div align="center">
  <img src="https://github.com/user-attachments/assets/9d453837-8e7d-4c5e-bf6c-666b826df1ad" width="800" alt="Demonstration" />
</div>

---

### Overview
A background-friendly Windows application designed to reduce eye strain, adjust monitor hardware brightness, and apply custom 12 color filters across single or multi-monitor setups. It operates efficiently using native Windows APIs without heavy system overhead.

Made using AutoHotKey and compiled using AHK2Exe.

---

### Features

1. Has 12 pre-configured display color tints to choose from.
2. A slider (0–100%) that adjusts how strongly the color filter tints your screen by modifying system GDI Gamma Ramps.
3. Directly adjusts physical monitor brightness (10–100%) using WMI (for laptops) and DDC/CI for external monitors.
4. Multi-monitor is supported for gamma ramps and dimming.
5. Automated scheduling for different presets in specified hours.
6. Highly customizable and intentionally supports Quality-Of-Life day-to-day operations.

#### VERSION 1.1 Additional Features
1. Includes a screen-time tracker and general recommendations based on performance and metrics.
2. Additional automated ergonomics and health reminders such as live user monitoring.
3. AC/DC automated power detection and preset switching.
4. Live monitoring and screen tracking only takes up 4mb of memory at most and will not scrape any personal information/data.

---

### Workflow

1. Select a quick preset or adjust your brightness, color, and strength sliders manually.
2. You can set the preferred time when to apply the filters and the app will apply it automatically.
3. Close the window to minimize the app directly to the system tray.
4. Press `Ctrl` + `Shift` + `F` at any time to toggle the interface.
5. Alternatively, you can check the app minimized in your hidden icons.
6. You can access the metrics of screen-time through the screen-statistics menu.

---

## Downloads
#### Check the [releases](https://github.com/r00t-tsai/Filter-Studio/releases).

---
## License & Distribution

Filter Studio is released as **Freeware**. 

* You are free to download, use, and share the compiled `.exe` executable for personal or commercial use.
* Source code for **v1.0** remains accessible in my other repository and commit history as open reference.
* **v1.1+** binaries are closed-source freeware. See the [LICENSE](LICENSE) file for full terms.

---
## References
[AutoHotkey v2](https://www.autohotkey.com/)
[AHK2Exe](https://github.com/AutoHotkey/Ahk2Exe)
