----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/28/2025 10:21:24 AM
-- Design Name: 
-- Module Name: clk_gen_500kHz - Behavioral
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

entity clk_gen_500kHz is
    Port ( i_clk        : in  STD_LOGIC;
           o_clk_500kHz  : out STD_LOGIC;   -- 500 kHz transmit signal;
           o_clk_1MHz   : out STD_LOGIC
         );
end clk_gen_500kHz;

architecture Behavioral of clk_gen_500kHz is


 constant CLK_CNT_HALF_500kHz : integer := 25;     -- half count (50% duty cycle) for 500kHz clock
 constant CLK_CNT_HALF_1MHz   : integer := 12;     -- half count (approx 50% duty cycle) for 1MHz clock
  
  signal r_Clock_Count : integer range 0 to CLK_CNT_HALF_500kHz := 0;
  signal r_clk_500khz : STD_LOGIC := '0';
  signal r_clk_1MHz   : STD_LOGIC := '0';
  

begin

  p_clk_div : process (i_clk) is
  begin
    if rising_edge(i_clk) then

      if r_Clock_Count = CLK_CNT_HALF_500kHz then
        r_clk_500khz <= not r_clk_500khz;
        r_clk_1MHz   <= not r_clk_1MHz;
		r_Clock_Count <= 1;
      elsif r_Clock_Count = CLK_CNT_HALF_1MHz then
        r_clk_1MHz   <= not r_clk_1MHz;
        r_Clock_Count <= r_Clock_Count + 1;
      else 
        r_Clock_Count <= r_Clock_Count + 1;

      end if;
    end if;
  end process  p_clk_div;
  
  -- Assign internal register to output 
  o_clk_500kHz <= r_clk_500khz;
  o_clk_1MHz   <= r_clk_1MHz;
end Behavioral;
