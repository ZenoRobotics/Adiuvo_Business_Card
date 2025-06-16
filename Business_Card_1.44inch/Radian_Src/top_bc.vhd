library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_bc is generic(
    SIMULATION : integer := 0  -- true = 1, false = 0   Used to shorten delays for simulation
); 
    port(
        i_clk  : in std_logic;  --25 MHz
		-- user interface
		i_config_btn_n : in std_logic;
		-- control interface 
        o_rstn : out std_logic := '1';
        i_busy : in  std_logic;
		o_epaper_pwr_en    : out std_logic;
		o_epaper_discharge : out std_logic;
		 -- spi output interface 
		o_sclk : out std_logic;
        o_csn  : out std_logic;
        o_mosi : out std_logic;
		i_miso : in  std_logic;
        -- IR Data Capture
		i_ir_rcvr_data : in std_logic
		-- debug I/O
        --o_led0_blue: out std_logic;
        --o_led0_grn : out std_logic;
        --o_led0_red : out std_logic;
        --o_led1_red : out std_logic;
		--o_ir_led   : out std_logic
    );      
end entity;

architecture rtl of top_bc is

    constant g_clk_freq : integer := 25000000;
    constant g_spi_clk : integer  := 1000000;

    signal s_load : std_logic;
    signal s_data : std_logic_vector(7 downto 0);
    signal s_spi_rx_data     : std_logic_vector(7 downto 0);
	signal s_spi_rx_rd_rqst  : std_logic;
	signal s_spi_rx_data_val : std_logic;
    signal s_busy     : std_logic;
    signal s_done     : std_logic;
	
    signal s_config_btn_n_db : std_logic;
	signal s_pb2_o_null      : std_logic;
	signal s_pb3_o_null      : std_logic;
	signal s_clk_1kHz  : std_logic;
	signal s_clk_2kHz  : std_logic;
    signal s_led0_blue : std_logic;
	
	signal s_ir_rx_data_val  : std_logic;
	signal s_ir_rx_data_byte : std_logic_vector(7 downto 0);

begin

    --o_web <= (others =>'0');
    --o_data<= (others =>'0');
    --o_clk <= i_clk;
    --o_led1_red   <= '1';
	--o_ir_led     <= s_led0_blue;
	--o_led0_blue  <= s_led0_blue;
	
spi_op_inst : entity work.spi_op
    generic map (
      g_clk_freq => g_clk_freq,
      g_spi_clk => g_spi_clk
    )
    port map (
      i_clk     => i_clk,
      -- serial to parallel data in (to tx)
      i_data    => s_data,     -- parallel data in
	  o_rx_data => s_spi_rx_data,
      -- control signals
	  i_rx_rd_rqst  => s_spi_rx_rd_rqst,
	  o_rx_data_val => s_spi_rx_data_val,
	  i_load        => s_load,
	  o_done        => s_done,
	  --i_cs_n      => s_cs_n,
	  o_busy      => s_busy,
	  -- SPI external interface specific
	  o_sclk    => o_sclk,
      --o_csn     => o_csn,
      o_mosi    => o_mosi,
	  i_miso    => i_miso
    );
        

 epaper_cntrl_inst : entity work.epaper_cntrl 
 generic map(
    SIMULATION => SIMULATION
 )
 port map(
    -- clocks
    i_clk        => i_clk,
	i_ms_dly_clk => s_clk_1kHz,
	-- data signals/busses
	o_data       => s_data,
	i_rx_data    => s_spi_rx_data,
	i_rx_data_val => s_spi_rx_data_val,
	o_rx_rd_rqst => s_spi_rx_rd_rqst,
	-- control signals
	i_config_n   => i_config_btn_n, --s_config_btn_n_db,
	o_rstn       => o_rstn,
    i_busy       => i_busy,
	o_epaper_pwr_en => o_epaper_pwr_en,
	o_discharge  => o_epaper_discharge,
	-- spi control/handshake signals
    i_done       => s_done,
    o_load       => s_load,
	o_cs_n       => o_csn     -- active low, sent directly to SPI interface
	-- debug
	--o_blu_led    => s_led0_blue,
	--o_red_led    => o_led0_red
    );
    
 pb_debouncer_inst : entity work.pb_debouncer port map(
    i_clk   => s_clk_1kHz,
    i_pb1   => i_config_btn_n,
    o_pb1   => s_config_btn_n_db,
    i_pb2   => '1',
    o_pb2   => s_pb2_o_null,
    i_pb3   => '1',
    o_pb3   => s_pb3_o_null
    );
	
 ir_rx_decoder_inst : entity work.ir_rx_decoder port map(
    i_Clk       => i_clk,
	i_Pulse_Clk => s_clk_2kHz,
    i_RX_Serial => i_ir_rcvr_data,
    o_RX_DV     => s_ir_rx_data_val,
    o_RX_Byte   => s_ir_rx_data_byte
    );
	
 clk_gen_1kHz_inst : entity work.clk_gen_1kHz port map(
    i_clk   => i_clk,
	o_clk_1kHz => s_clk_1kHz,
	o_clk_2kHz => s_clk_2kHz
 );

end architecture; 