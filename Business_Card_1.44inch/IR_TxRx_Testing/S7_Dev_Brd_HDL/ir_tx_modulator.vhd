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
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ir_tx_modulator is
  Port ( 
        i_clk        : in std_logic := '0';    -- 500 kHz module/fifo read clock
        i_clk_38kHz  : in std_logic;           -- IR modulation frequency
        i_rstn       : in std_logic;
        i_clk_2kHz   : in std_logic := '0';    -- bit tx width = 1/2 kHz = 500 us
        i_data_available : in std_logic;       
        i_ir_byte_to_tx  : in std_logic_vector(7 downto 0);
        o_ir_tx_fifo_rd  : out std_logic;
        o_ir_tx_pulse    : out std_logic
  );
end ir_tx_modulator;

architecture Behavioral of ir_tx_modulator is

    constant CLKS_PER_BIT : integer := 250; -- 500k/2k
    
    -- States
    type fsm  is (IDLE, TX_START_BIT, TX_DATA_BITS, TX_STOP_BIT, CLEANUP);
   
    -- signal definitions --
    signal s_Clock_Count : integer range 0 to 1024 := 0;
    signal s_Bit_Index   : integer range 0 to 16 := 0;
    signal s_Tx_Data     : std_logic_vector(7 downto 0);
    signal s_ir_tx_serial : std_logic := '0';
     -- State Reg
    signal s_SM_Main  : fsm := IDLE;
    
begin

     
  ir_byte_to_uart_format : process (i_clk) is 
  begin
      if i_rstn = '0' then
          s_ir_tx_serial <= '0'; 
          o_ir_tx_fifo_rd <= '0';        
          s_Clock_Count <= 0;
          s_Bit_Index   <= 0;
          s_Tx_Data     <= x"00";
          s_SM_Main <= IDLE;
      elsif rising_edge(i_clk) then
         case s_SM_Main is
           when IDLE =>
               s_ir_tx_serial <= '0'; 
               o_ir_tx_fifo_rd <= '0';    
               s_Clock_Count <= 0;
               s_Bit_Index   <= 0;  -- Tx lsb to msb
               if i_data_available = '1'  then
                   s_Tx_Data   <= i_ir_byte_to_tx;  -- capture input byte from fifo
                   s_SM_Main   <= TX_START_BIT;
                   -- perform a read for the next available data 
                   o_ir_tx_fifo_rd <= '1';
               else
                   s_SM_Main <= IDLE;
               end if;
         
        -- Send out Start Bit. Start bit = 0
        when TX_START_BIT =>

            o_ir_tx_fifo_rd <= '0'; 
            s_ir_tx_serial  <= '1';  -- start bit is logic zero, but need to tx pulse to see that at rcvr
            -- Wait CLKS_PER_BIT-1 clock cycles for start bit to finish
            if s_Clock_Count < CLKS_PER_BIT-1 then
                s_Clock_Count <= s_Clock_Count + 1;
                s_SM_Main     <= TX_START_BIT;
            else
                s_Clock_Count <= 0;
                s_SM_Main     <= TX_DATA_BITS;
            end if;
         
         
        -- Wait CLKS_PER_BIT-1 clock cycles for data bits to finish         
        when TX_DATA_BITS =>
            s_ir_tx_serial <= not s_Tx_Data(s_Bit_Index);
             
            if s_Clock_Count < CLKS_PER_BIT-1 then
                s_Clock_Count <= s_Clock_Count + 1;
                s_SM_Main     <= TX_DATA_BITS;
            else
                s_Clock_Count <= 0;
                 
                -- Check if we have sent out all bits
                if (s_Bit_Index < 7) then
                    s_Bit_Index <= s_Bit_Index + 1;
                    s_SM_Main   <= TX_DATA_BITS;
                else
                    s_Bit_Index <= 0;
                    s_SM_Main   <= TX_STOP_BIT;
                end if;
            end if;
         
        -- Send out Stop bit.  Stop bit = 1
        when TX_STOP_BIT =>
            s_ir_tx_serial <= '0';  -- turns out to be logic 1 at receiver
             
            -- Wait CLKS_PER_BIT-1 clock cycles for Stop bit to finish
            if s_Clock_Count < CLKS_PER_BIT-1 then
                s_Clock_Count <= s_Clock_Count + 1;
                s_SM_Main     <= TX_STOP_BIT;
            else
                s_Clock_Count <= 0;
                s_SM_Main     <= CLEANUP;
            end if;
         
         
        -- Stay here 1 clock
        when CLEANUP =>
            s_SM_Main <= IDLE;
         
        when others => 
            s_SM_Main <= IDLE;
         
        end case;
     end if;
  end process;
  
  o_ir_tx_pulse <= i_clk_38kHz and s_ir_tx_serial;
  
end Behavioral;