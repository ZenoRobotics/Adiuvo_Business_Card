----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/18/2025 07:27:14 PM
-- Design Name: 
-- Module Name: top_ir_pass - Behavioral
-- Project Name: Test logic for the IR decoder and IR TX LED
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

entity top_ir_pass is
     port ( 
	       i_clk    : in std_logic;        -- 25 MHz
		   i_ir_rcvr_data : in std_logic;  -- ir decoder input
		   o_ir_tx  : out STD_LOGIC       -- connects to IR LED circuit
		   --o_led2_red : out STD_LOGIC
		  );      
end entity;


architecture Behavioral of top_ir_pass is

   -- signals & constants
  signal s_clk_1kHz  : std_logic;
  signal s_clk_2kHz  : std_logic;
  signal s_clk_38kHz : std_logic;
  signal s_clk_500kHz: std_logic;
  signal s_clk_1MHz  : std_logic;
  
  signal s_ir_rx_data_avail : std_logic;
  signal s_ir_rx_data_byte : std_logic_vector(7 downto 0);
  signal s_ir_tx_fifo_rd : std_logic ;
  
  signal r_Clock_Count : integer := 0;
  signal r_clk_100hz : std_logic := '0';
  signal r_pulse_on_off : std_logic := '0';
  
  signal delay : integer := 0;
  signal r_ir_rcvr_data : std_logic;
  
begin
  -- processes, instantiations, and assignments
 
 --o_led2_red <=  s_clk_38kHz; -- test to find port for
 
 o_ir_tx <= r_ir_rcvr_data and s_clk_38kHz;  --r_pulse_on_off and s_clk_38kHz;
  
 buf_ir_dec_in : process (i_clk) is
  begin
    if rising_edge(i_clk) then
      r_ir_rcvr_data <= not i_ir_rcvr_data;
    end if;
  end process  buf_ir_dec_in;
 
  -------------------------------------------------------------- 
  -- Clock gens
  --------------------------------------------------------------
  
  -- added 2kHz clock signal out for pulse window --	
 clk_gen_1kHz_inst : entity work.clk_gen_1kHz 
 port map(  
    i_clk      => i_clk,         -- 25 MHz system clk
	o_clk_1kHz => s_clk_1kHz,
	o_clk_2kHz => s_clk_2kHz	
 );
 
 -- IR Tx Serial Modulation Frequency
  clk_gen_38kHz_inst : entity work.clk_gen_38kHz 
  port map(  
    i_clk       => i_clk,         -- 25 MHz system clk
	o_clk_38kHz => s_clk_38kHz	  -- IR modulator freq
   );
 
 
 p_slow_clk : process (s_clk_2kHz) is
  begin
    if rising_edge(s_clk_2kHz) then
      if delay < 100 then 
	     r_pulse_on_off <= '0';
		 delay <= delay + 1;
	  elsif delay < 108 then 
         r_pulse_on_off <= not r_pulse_on_off;
	     delay <= delay + 1;
	  else
	     delay <= 0;
      end if;
    end if;
  end process  p_slow_clk;
  

 

end Behavioral;