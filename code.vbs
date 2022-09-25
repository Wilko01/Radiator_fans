esphome:
  name: radiator-huiskamer-voor
  on_boot:
    priority: -100 #lowest priority so start last
    then:
      - lambda: id(dac_output_fans).turn_off(); #turn off the fan at boot time
esp32:
  board: esp32doit-devkit-v1
  framework:
    type: arduino

# Enable logging
logger:

# Enable Home Assistant API
api:

ota:
  password: "c659c88218892afdcfbbf393b0457bd9"

wifi:
  ssid: !secret wifi_ssid
  password: !secret wifi_password

  # Enable fallback hotspot (captive portal) in case wifi connection fails
  ap:
    ssid: "Radiator-Huiskamer-Voor"
    password: "NnoehsEWvBp8"

captive_portal:

#Use the DAC to control the fan via DAC GPIO25 or DAC GPIO26
#https://esphome.io/components/output/esp32_dac.html?highlight=dac
output:
  - platform: esp32_dac
    pin: GPIO25
    id: dac_output_fans
  
  - platform: ledc
    pin: GPIO26
    frequency: 1000 Hz
    id: pwm_output_leds

fan:
  - platform: speed
    output: dac_output_fans
    id: fan01
    name: "Radiator huiskamer voor - Ventilator"

#https://esphome.io/components/sensor/dallas.html?highlight=dallas
#Get the temperature via the Dallas temp sensor
dallas:
  - pin: GPIO32

#https://esphome.io/components/sensor/pulse_counter.html
#Get the RPM of one fan
sensor:
  - platform: pulse_counter
    pin: GPIO27
    name: "Radiator huiskamer voor rechts - RPM"
    update_interval: 10s
    unit_of_measurement: 'RPM'
    filters:
      - multiply: 0.5 #fan runs according to specs 3500rpm, so need to convert the received pulses as that was max 8000

  - platform: pulse_counter
    pin: GPIO14
    name: "Radiator huiskamer voor links - RPM"
    update_interval: 10s
    unit_of_measurement: 'RPM'
    filters:
      - multiply: 0.5 #fan runs according to specs 3500rpm, so need to convert the received pulses as that was max 8000
   
  - platform: dallas
    address: 0x980317331815ff28 #at first boot disable this code to retrieve the address and adjust it
    name: "Radiator huiskamer voor - Temperatuur"
    
light:
  - platform: monochromatic
    output: pwm_output_leds
    name: "Radiator huiskamer LEDs"


