library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_top is
end;

architecture bench of tb_top is
  -- Clock period
  constant clk_period : time := 10 ns; -- feeding with 100 MHz clock, same as Leo Board.
  -- Generics
  -- Ports
  signal i_clk          : std_logic:='0';
  signal o_rstn         : std_logic:='1';
  signal i_config_btn_n : std_logic;
  signal o_csn          : std_logic;
  signal o_done         : std_logic;
  signal o_mosi         : std_logic;
  signal i_miso         : std_logic;
  signal o_sclk         : std_logic;
  
  signal o_data             : std_logic_vector(7 downto 0);
  signal o_epaper_pwr_en    : std_logic;
  signal o_epaper_discharge : std_logic;
  signal s_uart_tx          : std_logic;


  --type mem_array is array (0 to 8191) of std_logic_vector(7 downto 0);
  --signal ram : mem_array:=(x"00", x"01", x"03", others => x"ff");

begin

  top_bc_inst : entity work.top_bc
  generic map (
      SIMULATION => 1
  )
  port map (
    i_clk => i_clk,
    i_config_btn_n => i_config_btn_n,
    o_rstn => o_rstn,
    i_busy =>'0',
    o_epaper_pwr_en => o_epaper_pwr_en,
    o_epaper_discharge => o_epaper_discharge,
    o_csn => o_csn,
    o_mosi => o_mosi,
	i_miso => '1',
    o_sclk => o_sclk,
    -- debug
    o_uart_tx => s_uart_tx
  );
  
  
i_clk <= not i_clk after clk_period/2;


--process(o_clk)
--begin
--  if rising_edge(o_clk) then
--    if o_rd_en = '1' then 
--      i_data <= ram(to_integer(unsigned(o_addr)));
--    end if;

--  end if;

--end process;

process 
begin
    i_config_btn_n <= '1';
	wait until rising_edge(i_clk);
    wait for 1000000 ns;
    wait until rising_edge(i_clk);
    --simulate bounce
    i_config_btn_n <= '0';
    wait for 100000 ns;
    i_config_btn_n <= '1';
    wait for 100000 ns;
    i_config_btn_n <= '0';
    wait for 500000 ns;
    i_config_btn_n <= '1';
    wait for 300000 ns;
    -- end of bounce
    i_config_btn_n <= '0';
    wait for 10000000 ns;
    wait until rising_edge(i_clk);
    i_config_btn_n <= '1';
    wait until rising_edge(o_done);
    report "simulation complete" severity failure;


end process;

end;