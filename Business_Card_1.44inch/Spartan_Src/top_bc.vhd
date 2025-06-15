library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Leo Board Configuration (assumes 100 MHz clock source - non-sim
entity top_bc is generic(
    SIMULATION : integer := 0  -- true = 1, false = 0   Used to shorten delays for simulation
);
    port(
        i_clk         : in std_logic;  -- 100 MHz
		-- user interface
		i_config_btn_n: in std_logic;
		-- control interface 
		--o_pwm_clk_vgl : out std_logic := '0';
        o_rstn : out std_logic := '1';
        i_busy : in  std_logic;
		o_epaper_pwr_en    : out std_logic;
		o_epaper_discharge : out std_logic;
		 -- spi output interface 
		o_sclk : out std_logic;
        o_csn  : out std_logic;
        o_mosi : out std_logic;
		i_miso : in  std_logic;
		-- debug
		o_led_config_n : out std_logic;
		o_led_config_n_db : out std_logic;
		o_uart_tx : out std_logic
       
    );      
end entity;

architecture rtl of top_bc is

    constant g_clk_freq : integer := 25000000;
    constant g_spi_clk : integer  := 1000000;
    -- Set Parameter CLKS_PER_BIT as follows:
    -- CLKS_PER_BIT = (Frequency of i_Clock)/(Frequency of UART)
    -- Example: 10 MHz Clock, 115200 baud UART
    --(10000000)/(115200) = 868
    constant c_CLKS_PER_BIT : integer := 217;  -- 25 MHz

    signal s_load     : std_logic;
    signal s_data     : std_logic_vector(7 downto 0);
    signal s_rx_data  : std_logic_vector(7 downto 0);
    signal s_rx_rd_rqst  : std_logic;
	signal s_rx_data_val : std_logic;
    signal s_busy        : std_logic;
    signal s_done        : std_logic;
    signal s_tx_active   : std_logic;
    signal s_tx_done     : std_logic;
	--signal s_cs_n      : std_logic;
    signal s_pb_db       : std_logic;
    signal s_config_btn_n_db: std_logic;
    signal s_config_btn_n   : std_logic;
	signal s_pb2_o_null     : std_logic;
	signal s_pb3_o_null     : std_logic;
	signal s_clk_1kHz       : std_logic;
    signal s_led0_blue      : std_logic;
    
        -- signals to convert 100 MHz input clock to 25 MHz system clock as found on Lattice BC board
    signal r_Clock_Count : integer range 0 to 3 := 0;
    signal r_clk_25MHz   : STD_LOGIC := '0';
    signal r_clk_200khz  : STD_LOGIC := '0';
	signal r_pwm_clk_cnt : integer range 0 to 200 := 0;

begin

    --o_web <= (others =>'0');
    --o_data<= (others =>'0');
    --o_clk <= i_clk;
    --o_led1_red   <= '1';
	--o_ir_led     <= s_led0_blue;
	--o_led0_blue  <= s_led0_blue;
	--o_pwm_clk_vgl <= r_clk_200khz;
	s_config_btn_n <= not i_config_btn_n;
	o_led_config_n <= not i_config_btn_n;
	o_led_config_n_db <= s_config_btn_n_db;
	
spi_op_inst : entity work.spi_op
    generic map (
      g_clk_freq => g_clk_freq,
      g_spi_clk => g_spi_clk
    )
    port map (
      i_clk     => r_clk_25MHz,
      -- serial to parallel data in (to tx)
      i_data    => s_data,     -- parallel data in
	  o_rx_data => s_rx_data,
      -- control signals
	  i_rx_rd_rqst  => s_rx_rd_rqst,
	  o_rx_data_val => s_rx_data_val,
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
    i_clk        => r_clk_25MHz,
	i_ms_dly_clk => s_clk_1kHz,
	-- data signals/busses
	o_data       => s_data,
	i_rx_data    => s_rx_data,
	i_rx_data_val => s_rx_data_val,
	o_rx_rd_rqst => s_rx_rd_rqst,
	-- control signals
	i_config_n   => s_config_btn_n_db,
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
    i_pb1   => s_config_btn_n,
    o_pb1   => s_config_btn_n_db,
    i_pb2   => '0',
    o_pb2   => s_pb2_o_null,
    i_pb3   => '0',
    o_pb3   => s_pb3_o_null
    );
	
 clk_gen_1kHz_inst : entity work.clk_gen_1kHz port map(
    i_clk   => r_clk_25MHz, 
	o_clk_1kHz => s_clk_1kHz	
 );
 
 -- reduce system clock by /4 --
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
  
  -- PWM Square Wave Gen 
  p_sys_pwm_vgl : process (r_clk_25MHz) is
  begin
    if rising_edge(r_clk_25MHz) then

      if r_pwm_clk_cnt = 25 then
        r_clk_200khz <= not r_clk_200khz;
		r_pwm_clk_cnt <= 1;

      else
        r_pwm_clk_cnt <= r_pwm_clk_cnt + 1;

      end if;
    end if;
  end process  p_sys_pwm_vgl;
  
  ---------------------
  -- UARTs for Debug --
  ---------------------
  
uart_tx_inst : entity work.uart_tx 
generic map(
      CLKS_PER_BIT => c_CLKS_PER_BIT) 
port map (
     i_Clock => r_clk_25MHz,
     i_Rst => '0',
     i_Tx_DV => s_rx_data_val,
     i_Tx_Byte => s_rx_data,
     o_Tx_Active => s_tx_active,
     o_Tx_Serial=> o_uart_tx,
     o_Tx_Done => s_tx_done
     );

end architecture; 