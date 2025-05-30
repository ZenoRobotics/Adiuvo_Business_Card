------------------------------------------------------------------------
-- This code takes in the decoded waveforms derived by the TSOP57238TT1 
-- from an external IR transmitter and converts the serial data into 
-- data bytes ...
--
-- This infrared communication standard has been defined by the IrDA 
-- industry-based group. Bytes of data are transfered from the IR source
-- to the receiver in a UART protocol format.
------------------------------------------------------------------------

----------------------------------------------------------------------
-- File Downloaded from http://www.nandland.com
----------------------------------------------------------------------
-- This file contains the UART Receiver.  This receiver is able to
-- receive 8 bits of serial data, one start bit, one stop bit,
-- and no parity bit.  When receive is complete o_rx_dv will be
-- driven high for one clock cycle.
-- 
-- Set Generic g_CLKS_PER_BIT as follows:
-- g_CLKS_PER_BIT = (Frequency of i_Clk)/(Frequency of UART)
-- Example: 500 kHz Clock, 2 kHz baud UART
-- (25000000)/(2000) = 500 clks/bit resolution
--
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
 
entity ir_rx_decoder is 
  port (
    i_Clk       : in  std_logic;  -- 500 kHz 
	i_Pulse_Clk : in  std_logic;  -- 2 kHz
    i_RX_Serial : in  std_logic;
    o_RX_DV     : out std_logic;
    o_RX_Byte   : out std_logic_vector(7 downto 0)
    );
end ir_rx_decoder;
 
 
architecture rtl of ir_rx_decoder is
 
  constant g_CLKS_PER_BIT : integer := 250; --g_CLKS_PER_BIT = (Frequency of i_Clk)/(Frequency of UART)
  
  type t_SM_Main is (s_Idle, s_RX_Start_Bit, s_RX_Data_Bits,
                     s_RX_Stop_Bit, s_Cleanup);
  signal s_SM_Main : t_SM_Main := s_Idle;
 
  signal r_RX_Serial   : std_logic := '0';
  signal r_RX_DV       : std_logic := '0';
   
  signal s_Clk_Count : integer range 0 to g_CLKS_PER_BIT-1 := 0;
  signal s_Bit_Index : integer range 0 to 7 := 0;  -- 8 Bits Total
  signal s_RX_Byte   : std_logic_vector(7 downto 0) := (others => '0');
   
begin
 
  -- Purpose: Double-register the incoming data.
  -- This allows it to be used in the UART RX Clock Domain.
  -- (It removes problems caused by metastabiliy)
  p_SAMPLE : process (i_Clk)
  begin
    if rising_edge(i_Clk) then
      r_RX_Serial    <= i_RX_Serial;
    end if; 
  end process p_SAMPLE;
 
  -- Purpose: Control RX state machine
  p_UART_RX : process (i_Clk)
  begin
    if rising_edge(i_Clk) then
      case s_SM_Main is
        when s_Idle =>
          r_RX_DV     <= '0';
          s_Clk_Count <= 0;
          s_Bit_Index <= 0;
 
          if r_RX_Serial = '0' then       -- Start bit detected
            s_SM_Main <= s_RX_Start_Bit;
          else
            s_SM_Main <= s_Idle;
          end if;
 
          -- Check middle of start bit to make sure it's still low
          when s_RX_Start_Bit =>
          if s_Clk_Count = (g_CLKS_PER_BIT-1)/2 then
            if r_RX_Serial = '0' then
              s_Clk_Count <= 0;  -- reset counter since we found the middle
              s_SM_Main   <= s_RX_Data_Bits;
            else
              s_SM_Main   <= s_Idle;
            end if;
          else
            s_Clk_Count <= s_Clk_Count + 1;
            s_SM_Main   <= s_RX_Start_Bit;
          end if;
         
        -- Wait g_CLKS_PER_BIT-1 clock cycles to sample serial data
        when s_RX_Data_Bits =>
          if s_Clk_Count < g_CLKS_PER_BIT-1 then
            s_Clk_Count <= s_Clk_Count + 1;
            s_SM_Main   <= s_RX_Data_Bits;
          else
            s_Clk_Count            <= 0;
            s_RX_Byte(s_Bit_Index) <= r_RX_Serial;
             
            -- Check if we have sent out all bits
            if s_Bit_Index < 7 then
              s_Bit_Index <= s_Bit_Index + 1;
              s_SM_Main   <= s_RX_Data_Bits;
            else
              s_Bit_Index <= 0;
              s_SM_Main   <= s_RX_Stop_Bit;
            end if;
          end if;
           
        -- Receive Stop bit. Stop bit = 1
        when s_RX_Stop_Bit =>
          -- Wait g_CLKS_PER_BIT-1 clock cycles for Stop bit to finish
          if s_Clk_Count < g_CLKS_PER_BIT-1 then
            s_Clk_Count <= s_Clk_Count + 1;
            s_SM_Main   <= s_RX_Stop_Bit;
          else
            r_RX_DV     <= '1';
            s_Clk_Count <= 0;
            s_SM_Main   <= s_Cleanup;
          end if;
            
        -- Stay here 1 clock
        when s_Cleanup =>
          s_SM_Main <= s_Idle;
          r_RX_DV   <= '0'; when others =>
          s_SM_Main <= s_Idle;
 
      end case;
    end if;
  end process p_UART_RX;
 
  o_RX_DV   <= r_RX_DV;
  o_RX_Byte <= s_RX_Byte;
   
end rtl;