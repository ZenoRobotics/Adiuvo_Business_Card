#SYS_CLK External Gen  100MHz Schematic pg. 8/7
set_property PACKAGE_PIN G11 [get_ports i_clk]
set_property IOSTANDARD LVCMOS33 [get_ports i_clk]

set_property PACKAGE_PIN G4 [get_ports i_rstn]
set_property IOSTANDARD LVCMOS33 [get_ports i_rstn]

#leds 0 thru 3
#set_property PACKAGE_PIN E11 [get_ports {led[0]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]
#set_property PACKAGE_PIN M10 [get_ports {led[1]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]
#set_property PACKAGE_PIN A10 [get_ports {led[2]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]
#set_property PACKAGE_PIN D12 [get_ports {led[3]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]

#Push Buttons 0 thru 3
set_property PACKAGE_PIN M5 [get_ports i_pulse_btn]
set_property IOSTANDARD LVCMOS33 [get_ports i_pulse_btn]
#set_property PACKAGE_PIN L5 [get_ports {btn[1]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {btn[1]}]
#set_property PACKAGE_PIN N4 [get_ports {btn[2]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {btn[2]}]
#set_property PACKAGE_PIN P5 [get_ports {btn[3]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {btn[3]}]

#Switches 0 thru 3
#set_property PACKAGE_PIN A12 [get_ports {sw[0]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {sw[0]}]
#set_property PACKAGE_PIN A13 [get_ports {sw[1]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {sw[1]}]
#set_property PACKAGE_PIN B13 [get_ports {sw[2]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {sw[2]}]
#set_property PACKAGE_PIN B14 [get_ports {sw[3]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {sw[3]}]

#RP2040 Interface
#RP Port: GPIO0   SPI0 RX    UART0 TX    I2C0 SDA    PWM0 A
set_property PACKAGE_PIN E13 [get_ports i_uart_rx]
set_property IOSTANDARD LVCMOS33 [get_ports i_uart_rx]
#RP Port: GPIO1   SPI0 CSn   UART0 RX    I2C0 SCL    PWM0 B
set_property PACKAGE_PIN C14 [get_ports o_uart_tx]
set_property IOSTANDARD LVCMOS33 [get_ports o_uart_tx]
#RP Port: GPIO2   SPI0 SCK   UART0 CTS   I2C1 SDA    PWM1 A
#set_property PACKAGE_PIN F11 [get_ports {rp_ack_n}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rp_ack_n}]


#PMOD1
#Pin 1
set_property PACKAGE_PIN L13 [get_ports o_ir_tx]
set_property IOSTANDARD LVCMOS33 [get_ports o_ir_tx]
#Pin 2
#set_property PACKAGE_PIN L12 [get_ports i_ir_rcvr_serial]
#set_property IOSTANDARD LVCMOS33 [get_ports i_ir_rcvr_serial]
#Pin 3
set_property PACKAGE_PIN L14 [get_ports o_uart_rx_debug]
set_property IOSTANDARD LVCMOS33 [get_ports o_uart_rx_debug]
#Pin 4
set_property PACKAGE_PIN M13 [get_ports o_ir_tx_fifo_empty_flag]
set_property IOSTANDARD LVCMOS33 [get_ports o_ir_tx_fifo_empty_flag]
#Pin 7
set_property PACKAGE_PIN K12 [get_ports o_uart_rx_data_val]
set_property IOSTANDARD LVCMOS33 [get_ports o_uart_rx_data_val]
#Pin 8
set_property PACKAGE_PIN K11 [get_ports {o_uart_tx_debug}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_uart_tx_debug}]
#Pin 9
#set_property PACKAGE_PIN M12 [get_ports {o_clk_2kHz_debug}]
#set_property IOSTANDARD LVCMOS33 [get_ports {o_clk_2kHz_debug}]
#Pin 10
set_property PACKAGE_PIN M11 [get_ports {i_ir_rcvr_serial}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_ir_rcvr_serial}]
#set_property PACKAGE_PIN M11 [get_ports {vga_out_b[0]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {vga_out_b[0]}]

#PMOD2
#Pin 1
#set_property PACKAGE_PIN M14 [get_ports {vga_out_b[1]}]          
#set_property IOSTANDARD LVCMOS33 [get_ports {vga_out_b[1]}]
#Pin 2
#set_property PACKAGE_PIN N14 [get_ports {vga_out_b[2]}]          
#set_property IOSTANDARD LVCMOS33 [get_ports {vga_out_b[2]}]
#Pin 3
#set_property PACKAGE_PIN P13 [get_ports {vga_out_g[0]}]          
#set_property IOSTANDARD LVCMOS33 [get_ports {vga_out_g[0]}]
#Pin 4
#set_property PACKAGE_PIN P12 [get_ports {vga_out_g[1]}]          
#set_property IOSTANDARD LVCMOS33 [get_ports {vga_out_g[1]}]
#Pin 7
#set_property PACKAGE_PIN N11 [get_ports {vga_out_g[2]}]          
#set_property IOSTANDARD LVCMOS33 [get_ports {vga_out_g[2]}]
#Pin 8
#set_property PACKAGE_PIN N10 [get_ports {vga_out_r[0]}]          
#set_property IOSTANDARD LVCMOS33 [get_ports {vga_out_r[0]}]
#Pin 9
#set_property PACKAGE_PIN P11 [get_ports {vga_out_r[1]}]          
#set_property IOSTANDARD LVCMOS33 [get_ports {vga_out_r[1]}]
#Pin 10
#set_property PACKAGE_PIN P10 [get_ports {vga_out_r[2]}]          
#set_property IOSTANDARD LVCMOS33 [get_ports {vga_out_r[2]}]
