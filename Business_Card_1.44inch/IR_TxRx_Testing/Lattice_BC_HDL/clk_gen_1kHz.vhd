----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/19/2025 04:57:58 PM
-- Design Name: 
-- Module Name: clk_gen_1kHz - Behavioral
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

entity clk_gen_1kHz is
    Port ( i_clk  : in  STD_LOGIC;
           o_clk_1kHz  : out STD_LOGIC;
           o_clk_2kHz  : out STD_LOGIC   -- used for 500 us pulse width for 38 kHz transmit signal
         );
end  clk_gen_1kHz;

architecture Behavioral of clk_gen_1kHz is

  constant CLK_CNT_HALF_1kHz : integer := 12500;     -- half count (50% duty cycle) for 1kHz clock
  constant CLK_CNT_HALF_2kHz : integer := 6250;  -- half count (50% duty cycle) for 2kHz clock
  
  signal r_Clock_Count : integer range 0 to CLK_CNT_HALF_1kHz := 0;
  signal r_clk_1khz : STD_LOGIC := '0';
  signal r_clk_2khz : STD_LOGIC := '0';

begin

  p_slow_clk : process (i_clk) is
  begin
    if rising_edge(i_clk) then

      if r_Clock_Count = CLK_CNT_HALF_1kHz then
        r_clk_1khz <= not r_clk_1khz;
        r_clk_2khz <= not r_clk_2khz;
		r_Clock_Count <= 0;

      elsif r_Clock_Count = CLK_CNT_HALF_2kHz then
        r_clk_2khz <= not r_clk_2khz;
        r_Clock_Count <= r_Clock_Count + 1;
      else
        r_Clock_Count <= r_Clock_Count + 1;

      end if;
    end if;
  end process  p_slow_clk;
  
  -- Assign internal register to output 
  o_clk_1kHz <= r_clk_1khz;
  o_clk_2kHz <= r_clk_2khz;

end Behavioral;