esphome:
  name: ventilator-schuur
  on_boot:
      priority: -100 #lowest priority so start last
      then:
       - lambda: id(pwm_output_fan).turn_off(); #turn off the fan at boot time
       
esp32:
  board: esp32dev
  framework:
    type: arduino

# Enable logging
logger:

# Enable Home Assistant API
api:

ota:
  password: "045d73a636ea1c73c152099d59f04bf5"

wifi:
  ssid: !secret wifi_ssid
  password: !secret wifi_password

  # Enable fallback hotspot (captive portal) in case wifi connection fails
  ap:
    ssid: "Ventilator-Schuur"
    password: "hiFyeM0Kb7iU"

captive_portal:
  

#control the PWM fan
#https://esphome.io/components/fan/speed.html
output:
  - platform: ledc
    pin: GPIO25
    frequency: 1000 Hz
    id: pwm_output_fan

fan:
  - platform: speed
    output: pwm_output_fan
    name: "Ventilator-Schuur"


#https://esphome.io/components/sensor/pulse_counter.html
#Get the RPM of one fan
sensor:
  - platform: pulse_counter
    pin: GPIO26
    name: "Ventilator-Schuur-RPM"
    update_interval: 10s
    unit_of_measurement: 'RPM'
    filters:
      - multiply: 0.5 #fan runs according to specs 3500rpm, so need to convert the received pulses as that was max 8000

  - platform: dht
    pin: GPIO27
    temperature:
      name: "TH11_Schuur-Temperature"
      id: th11_temp
    humidity:
      name: "TH11_Schuur-Humidity"
      id: th11_humidity
    model: AM2302
    update_interval: 10s




#https://esphome.io/components/binary_sensor/gpio.html
# Reed contact of the shed door and poort door
binary_sensor:
  - platform: gpio
    pin:
      number: GPIO12
      inverted: true
      mode:
        input: true
        pullup: true
    name: "DS15_Poort"  #ON = closed and OFF = open
    id: ds15_poort
    filters:
      - delayed_on: 10ms

  - platform: gpio
    pin:
      number: GPIO14
      inverted: true
      mode: 
        input: true
        pullup: true
    name: "DS16_Schuur"  #ON = closed and OFF = open
    id: ds16_schuur
    filters:
      - delayed_on: 10ms

#Get value from Helper in Home Assistant
#https://esphome.io/components/binary_sensor/homeassistant.html
  - platform: homeassistant
    id: override_from_home_assistant_helper
    entity_id: input_boolean.schuur_ventilator_override


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
            float temp_measured = static_cast<int>(id(th11_temp).state);
            float humidity_measured = static_cast<int>(id(th11_humidity).state);
            if (id(override_from_home_assistant_helper).state)
              {
                //Do nothing as the override is active which is set in Home Assistant
              }
              else 
              {
                if (!id(ds16_schuur).state) //door is open
                {
                 id(pwm_output_fan).turn_off(); 
                }
                else //Execute when the door is closed
                {
                  if (((temp_measured) >= 30) || ((humidity_measured) >= 85))
                  {
                    id(pwm_output_fan).set_level(1); //set the speed level between 0 and 1 https://esphome.io/components/output/index.html
                  }
                  else
                  {
                    if (((humidity_measured) >=70) && ((humidity_measured) < 79))
                    {
                      id(pwm_output_fan).set_level(0.5); 
                    }
                    else
                    {
                        if ((humidity_measured) <= 65)
                        {
                          id(pwm_output_fan).turn_off();  
                        }
                    } 
                  }
                }
              }




