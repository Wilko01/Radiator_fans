esphome:
  name: radiator-gang
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
  password: "9996f479bd3ef966ec8f5c424b7aef74"

wifi:
  ssid: !secret wifi_ssid
  password: !secret wifi_password

  # Enable fallback hotspot (captive portal) in case wifi connection fails
  ap:
    ssid: "Radiator-Gang Fallback Hotspot"
    password: "BwiUiI7PaqYk"

captive_portal:
    

#Use the DAC to control the fan via DAC GPIO25 or DAC GPIO26
#https://esphome.io/components/output/esp32_dac.html?highlight=dac
output:
  - platform: esp32_dac
    pin: GPIO25
    id: dac_output_fans


#https://esphome.io/components/fan/speed.html
  - platform: ledc
    pin: GPIO26
    frequency: 1000 Hz
    id: pwm_output_leds

fan:
  - platform: speed
    output: dac_output_fans
    name: "Radiator gang - Fan"

#https://esphome.io/components/sensor/dallas.html?highlight=dallas
#Get the temperature via the Dallas temp sensor
dallas:
  - pin: GPIO32

#https://esphome.io/components/sensor/pulse_counter.html
#Get the RPM of one fan
sensor:
  - platform: pulse_counter
    pin: GPIO27
    name: "Radiator gang - RPM"
    id: rpm
    update_interval: 10s
    unit_of_measurement: 'RPM'
    filters:
      - multiply: 0.5 #fan runs according to specs 3500rpm, so need to convert the received pulses as that was max 8000

   
  - platform: dallas
    address: 0x4c0000001e394c28 #at first boot disable this code to retrieve the address and adjust it
    name: "Radiator gang - Temperature"
    id: th12_temp
    
light:
  - platform: monochromatic
    output: pwm_output_leds
    name: "Radiator gang LEDs"


#Get value from Helper in Home Assistant
#https://esphome.io/components/binary_sensor/homeassistant.html
binary_sensor:
  - platform: homeassistant
    id: override_from_home_assistant_helper
    entity_id: input_boolean.radiator_gang_override


#logic:
time:
  - platform: homeassistant
    id: homeassistant_time

    on_time:
      - seconds: /10  # needs to be set, otherwise every second this is triggered!
        minutes: '*'  # Trigger every 0.5 minute
        then:
          lambda: !lambda |-
            auto time = id(homeassistant_time).now();
            int t_now = parse_number<int>(id(homeassistant_time).now().strftime("%H%M")).value();
            float temp_measured = static_cast<int>(id(th12_temp).state);
            if (id(override_from_home_assistant_helper).state)
              {
                //Do nothing as the override is active which is set in Home Assistant
              }
              else 
              {
                if ((temp_measured) >= 28)
                {
                 id(dac_output_fans).set_level(0.27); //set the speed level between 0 and 1 https://esphome.io/components/output/index.html
                }
                else
                {
                  if (((temp_measured) >=25) && ((temp_measured) < 27))
                  {
                    id(dac_output_fans).set_level(0.25);
                  }
                  else
                  {
                    if  ((temp_measured) <= 24)
                    {
                      id(dac_output_fans).turn_off();
                      //id(dac_output_fans).publish_state(0);
                    }
                  }
                }
              }




