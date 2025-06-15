----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/19/2025 04:57:58 PM
-- Design Name: 
-- Module Name: pb_debouncer - Behavioral
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

entity pb_debouncer is
    Port ( i_clk  : in  STD_LOGIC;
           i_pb1  : in  STD_LOGIC;
           o_pb1  : out STD_LOGIC;
           i_pb2  : in  STD_LOGIC;
           o_pb2  : out STD_LOGIC;
           i_pb3  : in  STD_LOGIC;
           o_pb3  : out STD_LOGIC
         );
end pb_debouncer;

architecture Behavioral of pb_debouncer is

  constant DEBOUNCE_LIMIT : integer := 8;
  
  signal r_Debounce_Count : integer range 0 to DEBOUNCE_LIMIT := 0;

  signal r_PB1_State : std_logic := '1';
  signal r_PB2_State : std_logic := '1';
  signal r_PB3_State : std_logic := '1';

begin

  p_Debounce : process (i_clk) is
  begin
    if rising_edge(i_clk) then

      -- Catching steady positive value of Pushbutton input 
      -- Increase the counter until it is stable for 10 ms.
      if ((i_pb1 = '0' or i_pb2 = '0' or i_pb3 = '0') and 
           r_Debounce_Count < DEBOUNCE_LIMIT) then
        r_Debounce_Count <= r_Debounce_Count + 1;

      -- End of counter reached, switch input is stable, register it.
      elsif r_Debounce_Count = DEBOUNCE_LIMIT then
        r_PB1_State <= i_pb1;
        r_PB2_State <= i_pb2;
        r_PB3_State <= i_pb3;
		r_Debounce_Count <= 0;
        
      -- Switches are the same state, reset the counter
      else
        r_Debounce_Count <= 0;
        r_PB1_State <= '1';
        r_PB2_State <= '1';
        r_PB3_State <= '1';

      end if;
    end if;
  end process p_Debounce;


  -- Assign internal register to output (debounced!)
  o_pb1 <= r_PB1_State;
  o_pb2 <= r_PB2_State;
  o_pb3 <= r_PB3_State;

end Behavioral;
