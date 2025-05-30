----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/28/2025 10:21:24 AM
-- Design Name: 
-- Module Name: clk_gen_38kHz - Behavioral
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

entity clk_gen_38kHz is
    Port ( i_clk        : in  STD_LOGIC;
           o_clk_38kHz  : out STD_LOGIC   -- 38 kHz transmit signal
         );
end clk_gen_38kHz;

architecture Behavioral of clk_gen_38kHz is


 constant CLK_CNT_HALF_38kHz : integer := 325;     -- half count (50% duty cycle) for 1kHz clock
  
  signal r_Clock_Count : integer range 0 to CLK_CNT_HALF_38kHz := 0;
  signal r_clk_38khz : STD_LOGIC := '0';
  

begin

  p_slow_clk : process (i_clk) is
  begin
    if rising_edge(i_clk) then

      if r_Clock_Count = CLK_CNT_HALF_38kHz then
        r_clk_38khz <= not r_clk_38khz;
		r_Clock_Count <= 0;
        
      else
        r_Clock_Count <= r_Clock_Count + 1;

      end if;
    end if;
  end process  p_slow_clk;
  
  -- Assign internal register to output 
  o_clk_38kHz <= r_clk_38khz;

end Behavioral;
