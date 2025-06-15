#SYS_CLK External Gen  100MHz Schematic pg. 8/7
set_property PACKAGE_PIN G11 [get_ports i_clk]
set_property IOSTANDARD LVCMOS33 [get_ports i_clk]

#set_property PACKAGE_PIN G4 [get_ports rst_n]
#set_property IOSTANDARD LVCMOS33 [get_ports rst_n]

#leds 0 thru 3
set_property PACKAGE_PIN E11 [get_ports {o_led_config_n}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_led_config_n}]
set_property PACKAGE_PIN M10 [get_ports {o_led_config_n_db}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_led_config_n_db}]
#set_property PACKAGE_PIN A10 [get_ports {led[2]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]
#set_property PACKAGE_PIN D12 [get_ports {led[3]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]

#PMOD2
#Pin 1
set_property PACKAGE_PIN M14 [get_ports {o_rstn}]          
set_property IOSTANDARD LVCMOS33 [get_ports {o_rstn}]
#Pin 2
set_property PACKAGE_PIN N14 [get_ports {i_busy}]          
set_property IOSTANDARD LVCMOS33 [get_ports {i_busy}]
#Pin 3
set_property PACKAGE_PIN P13 [get_ports {o_csn}]          
set_property IOSTANDARD LVCMOS33 [get_ports {o_csn}]
#Pin 4
set_property PACKAGE_PIN P12 [get_ports {o_mosi}]          
set_property IOSTANDARD LVCMOS33 [get_ports {o_mosi}]
#Pin 7
#set_property PACKAGE_PIN N11 [get_ports {o_pwm_clk_vgl}]          
#set_property IOSTANDARD LVCMOS33 [get_ports {o_pwm_clk_vgl}]
set_property PACKAGE_PIN N11 [get_ports {i_miso}]          
set_property IOSTANDARD LVCMOS33 [get_ports {i_miso}]
#Pin 8
set_property PACKAGE_PIN N10 [get_ports {o_epaper_pwr_en}]          
set_property IOSTANDARD LVCMOS33 [get_ports {o_epaper_pwr_en}]
#Pin 9
set_property PACKAGE_PIN P11 [get_ports {o_epaper_discharge}]          
set_property IOSTANDARD LVCMOS33 [get_ports {o_epaper_discharge}]
#Pin 10
set_property PACKAGE_PIN P10 [get_ports {o_sclk}]          
set_property IOSTANDARD LVCMOS33 [get_ports {o_sclk}]

#Push Buttons 0 thru 3
set_property PACKAGE_PIN M5 [get_ports {i_config_btn_n}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_config_btn_n}]
#set_property PACKAGE_PIN L5 [get_ports {i_config_btn}]
#set_property IOSTANDARD LVCMOS33 [get_ports {i_config_btn}]
#set_property PACKAGE_PIN N4 [get_ports {i_clr_display}]
#set_property IOSTANDARD LVCMOS33 [get_ports {i_clr_display}]


#RP2040 Interface     1st 4 Functions:
#RP Port: GPIO0   SPI0 RX    UART0 TX    I2C0 SDA    PWM0 A
#set_property PACKAGE_PIN E13 [get_ports uart_rx]
#set_property IOSTANDARD LVCMOS33 [get_ports uart_rx]
#RP Port: GPIO1   SPI0 CSn   UART0 RX    I2C0 SCL    PWM0 B
set_property PACKAGE_PIN C14 [get_ports o_uart_tx]
set_property IOSTANDARD LVCMOS33 [get_ports o_uart_tx]
