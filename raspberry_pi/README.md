# IoT E-Waste Battery Monitoring - Setup Instructions

## Quick Start Guide

### Step 1: Setup MQTT Broker on Raspberry Pi

```bash
# Make the setup script executable
chmod +x raspberry_pi/setup_mqtt_broker.sh

# Run the setup script
./raspberry_pi/setup_mqtt_broker.sh
```

### Step 2: Update Flutter App MQTT Configuration

After running the setup script, you'll get your Pi's IP address. Update the Flutter app:

1. Open `lib/core/config/app_config.dart`
2. Replace the MQTT broker IP with your Pi's IP address
3. The setup script will show you the exact IP to use

### Step 3: Start Battery Monitoring

For 9V battery testing:
```bash
cd raspberry_pi
python3 battery_9v_monitor.py
```

For car battery monitoring:
```bash
cd raspberry_pi
python3 battery_monitor.py
```

### Step 4: Test Flutter Connection

1. Start your Flutter emulator
2. Run the app: `flutter run`
3. Go to Dashboard page
4. Check connection status (should show "Connected")
5. Tap "Ping" button to test communication

### Step 5: Verify MQTT Communication

Test from Pi command line:
```bash
# Subscribe to all topics
mosquitto_sub -h localhost -t 'iot_ewaste/+/+'

# Send test message
mosquitto_pub -h localhost -t 'iot_ewaste/car001/test' -m 'Hello from Pi'
```

## Hardware Setup (Current Configuration)

### Components
- Raspberry Pi 3 B+
- ADS1115 16-bit ADC (I2C)
- Voltage sensor module with 5:1 scaling
- 9V battery for testing / 12V car battery for production

### Wiring Connections
```
ADS1115 → Raspberry Pi
VDD → 3.3V (Pin 1)
GND → GND (Pin 6)
SCL → GPIO 3 (Pin 5, I2C Clock)
SDA → GPIO 2 (Pin 3, I2C Data)

Voltage Sensor → Connections
VCC → 5V (Pi Pin 2)
GND → GND (Pi Pin 6)
S (Signal) → ADS1115 A0
```

### Battery Connection
```
9V Battery (Testing):
+ Terminal → Voltage Sensor Input
- Terminal → Common Ground

12V Car Battery (Production):
+ Terminal → Voltage Sensor Input
- Terminal → Common Ground
```

### Hardware Requirements
- Raspberry Pi 3 B+ (or newer)
- MCP3008 10-bit ADC chip
- Voltage divider circuit
- 12V car battery to monitor

### Wiring Diagram (MCP3008)
```
MCP3008 Pinout:
CH0  -> Voltage divider output (Pin 1)
CH1-7-> Not used (Pins 2-8)
DGND -> Pi GND (Pin 9, connect to Pin 6)
CS   -> Pi CE0 (Pin 10, connect to Pin 24/GPIO 8)
DIN  -> Pi MOSI (Pin 11, connect to Pin 19/GPIO 10)
DOUT -> Pi MISO (Pin 12, connect to Pin 21/GPIO 9)
CLK  -> Pi SCLK (Pin 13, connect to Pin 23/GPIO 11)
AGND -> Pi GND (Pin 14, connect to Pin 6)
VREF -> Pi 3.3V (Pin 15, connect to Pin 1)
VDD  -> Pi 3.3V (Pin 16, connect to Pin 1)

Voltage Divider (for 12V battery):
Battery +12V -> 10kΩ resistor -> CH0 -> 1kΩ resistor -> GND
(This gives ~1.1V max to MCP3008 for 12V input)
```

### Installation (MCP3008)
1. **Enable SPI on your Pi:**
   ```bash
   sudo raspi-config
   # Go to: Interface Options > SPI > Enable
   sudo reboot
   ```

2. **Install Python packages:**
   ```bash
   pip3 install spidev paho-mqtt
   ```

3. **Install system packages:**
   ```bash
   sudo apt update
   sudo apt install -y python3-pip python3-dev mosquitto mosquitto-clients
   ```

## Configuration

Choose your script and edit the CONFIG section:

**For ADS1115 (I2C):** Edit `battery_monitor.py`
**For MCP3008 (SPI):** Edit `battery_monitor_spi.py`

```python
CONFIG = {
    "mqtt": {
        "broker": "localhost",  # Change to your MQTT broker IP
        "port": 1883,
    },
    "car": {
        "car_id": "car_1",  # Must match your Flutter app
    },
    "sensors": {
        "voltage_channel": 0,  # ADC channel (0-3 for ADS1115, 0-7 for MCP3008)
        "voltage_divider_ratio": 11.0,  # Adjust for your divider
    }
}
```

## Running the Monitor

1. **Test your hardware first:**
   ```bash
   # For ADS1115:
   python3 test_ads1115.py
   
   # For MCP3008:
   python3 test_mcp3008.py
   ```

2. **Run the main monitor:**
   ```bash
   # For ADS1115:
   python3 battery_monitor.py
   
   # For MCP3008:
   python3 battery_monitor_spi.py
   ```

3. **Run as service (auto-start):**
   ```bash
   # Edit the service file to use the correct script path
   sudo cp battery_monitor.service /etc/systemd/system/
   sudo systemctl enable battery_monitor
   sudo systemctl start battery_monitor
   ```

## Files Included

- `battery_monitor.py` - I2C version using ADS1115 (16-bit, higher precision)
- `battery_monitor_spi.py` - SPI version using MCP3008 (10-bit, no I2C needed)
- `test_ads1115.py` - Test script for ADS1115
- `test_mcp3008.py` - Test script for MCP3008
- `battery_monitor.service` - Systemd service file
- `README.md` - This file

3. **Check logs:**
   ```bash
   tail -f /home/pi/battery_monitor.log
   sudo journalctl -u battery_monitor -f
   ```

## Testing MQTT

**Subscribe to topics:**
```bash
mosquitto_sub -h localhost -t 'car/+/battery/#' -v
mosquitto_sub -h localhost -t 'car/+/sensors/#' -v
```

**Send test ping:**
```bash
mosquitto_pub -h localhost -t 'car/car_1/ping' -m 'ping'
```

## MQTT Topics Published

- `car/car_1/battery/health` - Complete battery health data
- `car/car_1/sensors/voltage` - Individual voltage readings  
- `car/car_1/sensors/battery` - Battery SOC readings
- `car/car_1/pong` - Response to ping requests

## Troubleshooting

**SPI Issues (MCP3008):**
```bash
# Check if SPI is enabled
ls /dev/spi*
# Should show: /dev/spidev0.0  /dev/spidev0.1

# Test SPI connection
python3 test_mcp3008.py
```

**I2C Issues (ADS1115):**
```bash
# Check if I2C is enabled
lsmod | grep i2c
# Scan for devices (should show 0x48 for ADS1115)
sudo i2cdetect -y 1
```

**MQTT Issues:**
```bash
# Check broker status
sudo systemctl status mosquitto
# Test local connection
mosquitto_pub -h localhost -t test -m "hello"
```

**Permission Issues:**
```bash
# Add pi user to i2c group
sudo usermod -a -G i2c pi
```
