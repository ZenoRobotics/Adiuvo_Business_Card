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
  signal i_clk        : std_logic:='1';
  signal o_rstn       : std_logic:='1';
  signal i_pulse_btn  : std_logic:='0';
  signal o_data       : std_logic;


  --type mem_array is array (0 to 8191) of std_logic_vector(7 downto 0);
  --signal ram : mem_array:=(x"00", x"01", x"03", others => x"ff");

begin

  top_ir_inst : entity work.top_IR
  generic map (
      SIMULATION => 1
  )
  port map (
    i_clk => i_clk,
    i_rstn => o_rstn,
    o_ir_tx  =>  o_data,
    i_pulse_btn  => i_pulse_btn
  );
  
  
  i_clk <= not i_clk after clk_period/2;


process 
begin
    i_pulse_btn <= '0';
    wait until rising_edge(i_clk);
    wait for 1000 ns;
    wait until rising_edge(i_clk);
    wait for 100 ns;
    i_pulse_btn <= '1';
    wait for 20000000 ns;
    wait until rising_edge(i_clk);
    i_pulse_btn <= '0';
    wait for 1000 ns;
    wait until rising_edge(i_clk);
    --report "simulation complete" severity failure;
    wait for 1000000000 ns;

end process;

end;