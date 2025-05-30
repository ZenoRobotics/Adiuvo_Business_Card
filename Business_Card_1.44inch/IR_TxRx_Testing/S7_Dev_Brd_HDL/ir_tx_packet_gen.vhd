----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/28/2025 10:38:25 AM
-- Design Name: 
-- Module Name: ir_tx_packet_gen - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ir_tx_packet_gen is
  Port ( 
        i_clk        : in std_logic := '0';
        i_clk_38kHz  : in std_logic; 
        i_rstn       : in std_logic;
        i_clk_2kHz   : in std_logic := '0';
        i_send_pulse : in std_logic;
        o_ir_tx_data : out std_logic := '0'
  );
end ir_tx_packet_gen;

architecture Behavioral of ir_tx_packet_gen is

    -- signal definitions --
    signal i_send_init : std_logic := '0';
    signal r_send_init : std_logic := '0';
    signal r_prev_clk_val : std_logic := '0';
    signal s_curr_clk_val : std_logic := '0';
    signal s_start_sm   : std_logic := '0';
    signal c_pause      : integer := 10;
    
	signal num_bits_to_send : integer := 8;
    signal bit_sent_counter : integer := 0;
    type   t_data_bit_array is array (0 to 7) of std_logic;
    signal r_data_tx_bit_array : t_data_bit_array := ('1', '0', '1', '0','0', '1', '1', '0'); -- will change later. For testing purposes for now.
    signal s_data_array_index : integer := 0;
    signal s_const_loop : std_logic := '0';
    signal s_ir_tx_data : std_logic := '0';
    
begin

  sm_start_capture : process (i_clk) is
  begin
    if rising_edge(i_clk) then
      r_send_init <= i_send_pulse;
      if i_send_pulse = '1' and r_send_init = '0' then  --posedge of user input i_config (debounced pb)
         s_start_sm <= '1';
      end if;
    end if;
  end process  sm_start_capture;
  
  data_send_cntlr : process (i_clk) is
  begin
    if rising_edge(i_clk) then
       -- wait PB negedge to initiate data send --
       if s_start_sm = '1' then
          if r_prev_clk_val = '0' and i_clk_2kHz = '1' then -- posedge of clock
             if bit_sent_counter < num_bits_to_send then
                s_ir_tx_data <= r_data_tx_bit_array(bit_sent_counter);
                bit_sent_counter <= bit_sent_counter + 1;
             elsif bit_sent_counter = num_bits_to_send then
                s_ir_tx_data <= '0';
                bit_sent_counter <= bit_sent_counter + 1;
             elsif bit_sent_counter < c_pause then
                bit_sent_counter <= bit_sent_counter + 1;
             else
                bit_sent_counter <= 0; 
             end if;
          end if;
       end if;
     end if;    
   end process; 
   
   o_ir_tx_data <= i_clk_38kHz and s_ir_tx_data;

end Behavioral;