----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/27/2025 07:27:14 PM
-- Design Name: 
-- Module Name: top_IR - Behavioral
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

entity top_IR is generic(
    SIMULATION : integer := 0  -- true = 1, false = 0   Used to shorten delays for simulation
);
    Port ( 
         i_clk   : in STD_LOGIC;
         i_rstn   : in STD_LOGIC;
         -- uart rx to ir diode out channel
         i_uart_rx  : in std_logic;
         o_ir_tx : out STD_LOGIC;  -- connects to IR LED circuit
         -- IR decoder in to uart tx channel
         i_ir_rcvr_serial : in STD_LOGIC;  -- decoder input
         o_uart_tx  : out std_logic;
         -- Debug I/O --
         o_uart_rx_debug : out std_logic;
         o_uart_tx_debug : out std_logic;
         o_ir_tx_fifo_empty_flag : out std_logic;
         o_uart_rx_data_val : out   std_logic;
         i_pulse_btn: in std_logic
        );
end entity;

architecture Behavioral of top_IR is

    signal r_Clock_Count  : integer range 0 to 3 := 0;
    signal r_clk_25MHz    : STD_LOGIC := '0';
    signal s_pb_db        : std_logic;
    signal s_pulse_btn_inv : std_logic;  -- needed for opposite initial condition of button (leo vs BC)
    signal s_pulse_btn_db : std_logic;
    signal s_pb2_o_null   : std_logic;
    signal s_pb3_o_null   : std_logic;
    signal s_clk_1kHz     : std_logic;
    signal s_clk_2kHz     : std_logic;
    signal s_clk_38kHz    : std_logic;
    signal i_rst          : std_logic := '0';
    signal s_clk_500kHz   : std_logic;
    
    signal s_ir_rx_data_byte : std_logic_vector(7 downto 0);
    signal s_ir_byte_to_tx_uart : std_logic_vector(7 downto 0);
    signal s_ir_byte_to_tx_diode : std_logic_vector(7 downto 0);
   
	
	-- For testing only --
	-- UART signals & registers
	constant c_CLKS_PER_BIT : integer := 52;      -- 1 MHz/9600 bits/sec
    constant c_DATA_SIZE 	: integer := 8;	       -- number of bits in a data word
    constant c_ADDR_SPACE_EXP : integer := 4;      -- number of address bits (2^4 = 16 addresses)
    
    signal w_uart_rx_byte : std_logic_vector(c_DATA_SIZE-1 downto 0);		-- Rx byte data bus
    signal w_uart_rx_byte_val   : std_logic;
    signal s_tx_active_null : std_logic;
    signal w_Tx_Done : std_logic;
    signal s_ir_tx_fifo_empty : std_logic := '0';
    signal s_ir_tx_fifo_rd    : std_logic;
    signal s_ir_rx_data_val   : std_logic;
    signal s_ir_rx_fifo_full  : std_logic;
    signal s_tx_full_void : std_logic;
    signal s_ir_tx_data_avial : std_logic;
    signal r_ir_tx_data_avial : std_logic;
    signal rr_ir_tx_data_avial : std_logic;
    signal s_ir_rx_in_fifo_rd  : std_logic;
    signal s_ir_rx_data_empty : std_logic := '1';
    signal s_ir_rx_data_empty_n : std_logic := '0';
    signal r_ir_rx_data_empty_n : std_logic;
    signal s_clk_1MHz           : std_logic;
    signal s_uart_rx_debug      : std_logic;
    signal s_uart_tx            : std_logic;
    
    attribute dont_touch : string;
    attribute dont_touch of o_uart_rx_debug : signal is "true";
    
    
begin 

  s_pulse_btn_inv <= not i_pulse_btn;  -- comment out for Lattice BC board
  i_rst <= not i_rstn;
  -- Debug Signals 
  o_ir_tx_fifo_empty_flag <= s_ir_tx_fifo_empty;
  o_uart_rx_debug <= i_uart_rx;
  o_uart_tx  <= s_uart_tx;
  o_uart_tx_debug <= s_uart_tx;
  o_uart_rx_data_val <= w_uart_rx_byte_val;
  
  -- reduce system clock by /4 to match Lattice brd clk of 25 MHz --
  p_sys_clk_div : process (i_clk) is 
  begin
    if rising_edge(i_clk) then

      if r_Clock_Count = 2 then
        r_clk_25MHz <= not r_clk_25MHz;
		r_Clock_Count <= 1;

      else
        r_Clock_Count <= r_Clock_Count + 1;

      end if;
    end if;
  end process  p_sys_clk_div;
  
  
  pb_debouncer_inst : entity work.pb_debouncer 
  port map(
    i_clk   => s_clk_1kHz,
    i_pb1   => s_pulse_btn_inv,-- remove _inv for Lattice BC board
    o_pb1   => s_pulse_btn_db,
    i_pb2   => '0',
    o_pb2   => s_pb2_o_null,
    i_pb3   => '0',
    o_pb3   => s_pb3_o_null
    );
	
 -- added 2kHz clock signal out for pulse window --	
 clk_gen_1kHz_inst : entity work.clk_gen_1kHz 
 port map(  
    i_clk      => r_clk_25MHz, 
	o_clk_1kHz => s_clk_1kHz,
	o_clk_2kHz => s_clk_2kHz	
 );
 
 -- IR Tx Serial Modulation Frequency
 clk_gen_38kHz_inst : entity work.clk_gen_38kHz 
 port map(  
    i_clk       => r_clk_25MHz, 
	o_clk_38kHz => s_clk_38kHz	
 );
 
 -- Sample clock for IR Rx Serial decoded input
 clk_gen_500kHz_inst : entity work.clk_gen_500kHz 
 port map(  
    i_clk       => r_clk_25MHz, 
	o_clk_500kHz => s_clk_500kHz,
	o_clk_1MHz  => s_clk_1MHz	
 );
 
--------------------------------------------------------------
--  IR Demodulated Bit Stream From Decoder HW => FIFO => UART
--------------------------------------------------------------

-- *** Need to add PW checker and filter for consecutive bits ***
ir_rx_decoder_inst : entity work.ir_rx_decoder 
  port map (
    i_Clk       => s_clk_500kHz,  -- 1 MHz sample clock rate 
	i_Pulse_Clk => s_clk_2kHz,  -- 2 kHz pulse width clock
    i_RX_Serial => i_ir_rcvr_serial,
    o_RX_DV     => s_ir_rx_data_val,
    o_RX_Byte   => s_ir_rx_data_byte
    ); 
    
 ir_rx_in_fifo : entity work.fifo_16D_byteW 
  port map(
    rst    =>  i_rst,
    wr_clk =>  s_clk_500kHz,
    rd_clk =>  s_clk_500kHz,
    din    =>  s_ir_rx_data_byte,         --(7 DOWNTO 0);
    wr_en  =>  s_ir_rx_data_val, 
    rd_en  =>  s_ir_rx_in_fifo_rd, 
    dout   =>  s_ir_byte_to_tx_uart,         --(7 DOWNTO 0);
    full   =>  s_ir_rx_fifo_full,
    empty  =>  s_ir_rx_data_empty
  ); 
 
 -- need to add gated read logic
 
UART_TX_INST : entity work.uart_tx 
  generic map (
      CLKS_PER_BIT => c_CLKS_PER_BIT
  )
  port map( 
    i_Clock     => s_clk_500kHz,
    i_Rst       => i_rst,
    i_Tx_DV     => r_ir_rx_data_empty_n,
    i_Tx_Byte   => s_ir_byte_to_tx_uart,
    o_fifo_rd   => s_ir_rx_in_fifo_rd,
    o_Tx_Active => s_tx_active_null,
    o_Tx_Serial => s_uart_tx,
    o_Tx_Done   => w_Tx_Done 
  );

----------------------------------------------------
-- UART Data In from RP2040 To Send Out IR Diode
---------------------------------------------------

   UART_RX_INST : entity work.uart_rx 
    generic map (
         CLKS_PER_BIT => c_CLKS_PER_BIT
     )
     port map( 
         i_Clock     => s_clk_500kHz,        -- in
         i_Rst       => i_rst,               -- in
         i_Rx_Serial => i_uart_rx,           -- in
         o_Rx_DV     => w_uart_rx_byte_val,  -- out
         o_Rx_Byte   => w_uart_rx_byte       -- out
     );
   
-- Buffered data to be sent out IR Tx
-- ** Currently sourced by UART RX for testing Purposes **
ir_tx_out_fifo : entity work.fifo_16D_byteW 
 port map(
    rst    =>  i_rst,
    wr_clk =>  s_clk_500kHz,
    rd_clk =>  s_clk_500kHz,
    din    =>  w_uart_rx_byte,       -- Name will change in real appl where there is no UART
    wr_en  =>  w_uart_rx_byte_val,   -- Name will change in real appl where there is no UART
    rd_en  =>  s_ir_tx_fifo_rd, 
    dout   =>  s_ir_byte_to_tx_diode,      --(7 DOWNTO 0);
    full   =>  s_tx_full_void,
    empty  =>  s_ir_tx_fifo_empty
  );

 reg_data : process (s_clk_500kHz) is 
  begin
    if rising_edge(s_clk_500kHz) then
       r_ir_tx_data_avial <= not s_ir_tx_fifo_empty;
       rr_ir_tx_data_avial <= r_ir_tx_data_avial;
    end if;
  end process  reg_data;
  
  reg_data_25MHz : process (r_clk_25MHz) is 
  begin
    if rising_edge(r_clk_25MHz) then
       s_ir_rx_data_empty_n <= not s_ir_rx_data_empty;
       r_ir_rx_data_empty_n <= s_ir_rx_data_empty_n;
    end if;
  end process  reg_data_25MHz;


ir_tx_modulator_inst : entity work.ir_tx_modulator -- IR data stream out
  port map(  
    i_clk        => s_clk_500kHz, 
    i_clk_38kHz  => s_clk_38kHz,
    i_rstn       => i_rstn,
    i_clk_2kHz   => s_clk_2kHz,
    i_data_available => rr_ir_tx_data_avial,
    i_ir_byte_to_tx  => s_ir_byte_to_tx_diode,
    o_ir_tx_fifo_rd  => s_ir_tx_fifo_rd,
	o_ir_tx_pulse => o_ir_tx	  -- serial modulated bits out in UART packet format
 );
	

end Behavioral;
