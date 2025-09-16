# Real-Time System Health Monitoring Script 🖥️

A simple yet powerful Bash script that provides a real-time, terminal-based dashboard to monitor key system metrics. It's lightweight, easy to use, and requires no external dependencies.

## Example Output

Here's a sneak peek of what the monitor looks like in action:

```
╔══════════════════════════════════════════╗
║          Interactive System Monitor      ║
╠══════════════════════════════════════════╣
║ Commands: [q]uit | [n]ext view | [p]ause ║
╚══════════════════════════════════════════╝

System Information:
Hostname: my-linux-box
Uptime:   up 2 hours, 15 minutes

CPU Usage:
CPU: [#########.........................................] 18%

Memory Usage:
RAM: [##########################..........................] 52% (4015MB / 7689MB used)

Top 5 Processes (by CPU):
COMMAND                 %CPU   %MEM
firefox                 12.3    8.1
gnome-shell              4.5    3.2
code                     2.1    5.5
pulseaudio               0.9    0.5
Xorg                     0.7    1.1

```

## Features

* **Real-Time Monitoring**: Continuously updates system health information.
* **CPU Usage**: Displays current CPU utilization with a dynamic progress bar.
* **Memory Usage**: Shows detailed RAM usage (`Used/Total`) with a progress bar.
* **Disk Space**: Lists all mounted filesystems and highlights any that exceed a configurable usage threshold.
* **Top Processes**: Shows the top 5 processes currently consuming the most CPU.
* **Interactive Controls**:
    * Switch between **Top Processes** and **Disk Usage** views.
    * Pause and resume the monitoring.
    * Quit gracefully.
* **Color-Coded Output**: Uses colors to make the data easy to read at a glance. Thresholds for CPU and Memory turn yellow or red for high usage.

---

## Getting Started

### Prerequisites

All you need is a Linux/Unix-like environment with standard shell utilities (`awk`, `ps`, `df`, `grep`, etc.), which are available on virtually all systems out of the box.

### Installation

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/priyadeepsenwork/Bash-Script-Collection](https://github.com/priyadeepsenwork/Bash-Script-Collection)
    ```
2.  **Navigate to the directory:**
    ```bash
    cd your-repo-name
    ```
3.  **Make the script executable:**
    *(Replace `monitor.sh` with the actual name of your script file)*
    ```bash
    chmod +x monitor.sh
    ```

---

## Usage

Simply run the script from your terminal:

```bash
./monitor.sh
```

### Interactive Controls

While the script is running, use the following keys:

* `q` or `Q` : **Quit** the monitor.
* `n` or `N` : Switch to the **Next** view (toggles between Processes and Disk).
* `p` or `P` : **Pause** or resume the real-time updates.

---

## Configuration

You can easily customize the script's behavior by editing these variables at the top of the file:

```bash
#       Configuration
DISK_USAGE_THRESHOLD=80
# value in percentage

#       Real time monitoring
REFRESH_INTERVAL=1
# value in seconds
```

* `DISK_USAGE_THRESHOLD`: Sets the percentage at which disk usage will be highlighted in red.
* `REFRESH_INTERVAL`: Sets the data refresh rate in seconds.

---

## License

This project is licensed under the MIT License.