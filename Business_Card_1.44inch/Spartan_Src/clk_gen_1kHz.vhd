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
           o_clk_1kHz  : out STD_LOGIC
         );
end  clk_gen_1kHz;

architecture Behavioral of clk_gen_1kHz is

  constant CLK_CNT_LIMIT : integer := 12500;
  
  signal r_Clock_Count : integer range 0 to CLK_CNT_LIMIT := 0;
  signal r_slow_clk : STD_LOGIC := '0';

begin

  p_slow_clk : process (i_clk) is
  begin
    if rising_edge(i_clk) then

      if r_Clock_Count = CLK_CNT_LIMIT then
        r_slow_clk <= not r_slow_clk;
		r_Clock_Count <= 0;

      else
        r_Clock_Count <= r_Clock_Count + 1;

      end if;
    end if;
  end process  p_slow_clk;
  
  -- Assign internal register to output 
  o_clk_1kHz <= r_slow_clk;

end Behavioral;