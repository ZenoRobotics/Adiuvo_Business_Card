library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity spi_op is generic(
    g_clk_freq : integer := 25000000;
    g_done_delay : integer := 75;
    g_cs_delay : integer := 40;
    g_kill_sck : integer := 5;
    g_spi_clk  : integer := 1000000
);
    port(
        i_clk  : in std_logic; 
		-- serial to parallel data in (to tx) 
		i_data : in std_logic_vector(7 downto 0);
		o_rx_data : out std_logic_vector(7 downto 0):= (others=>'0');
		-- control signals
		i_rx_rd_rqst : in std_logic;
		o_rx_data_val : out std_logic := '0';
        i_load : in std_logic;
		o_done : out std_logic;
        o_busy : out std_logic;
        -- SPI external interface specific signals
        o_sclk : out std_logic;
		--o_csn  : out std_logic;
		o_mosi : out std_logic;
		i_miso : in std_logic
		
);
end entity;

architecture rtl of spi_op is 

    function vector_size(clk_freq, spi_clk : real) return integer is
        variable div                             : real;
        variable res                             : real;
        begin
        div := (clk_freq/spi_clk);
        res := CEIL(LOG(div)/LOG(2.0));
        return integer(res - 1.0);
    end;

    type fsm is (idle, sclk_del, load, complete,cs_del);

    constant c_fe_det : std_logic_vector(1 downto 0):= "10";
	constant C_SCLK_DEL         : integer := 55; -- 100 x 40ns = 4 us

    signal s_baud_counter       : unsigned(vector_size(real(g_clk_freq), real(g_spi_clk)) downto 0) := (others => '0'); 
    signal s_baud_enb           : std_logic:='0';
    signal s_data_reg           : std_logic_vector(7 downto 0):=(others =>'0');
	signal s_rx_data_reg        : std_logic_vector(7 downto 0):=(others =>'0');
	signal s_rx_rd_rqst_reg     : std_logic := '0';
	signal s_rx_data_rdy        : std_logic := '0';
    signal s_current_state      : fsm :=idle;
    signal s_load               : std_logic:='0';
    signal s_payload            : std_logic_vector(7 downto 0):=(others =>'0');
    signal s_sck                : std_logic:='0';  
    signal s_sck_fe             : std_logic:='0'; 
    signal s_tmr                : std_logic_vector(7 downto 0) := (others =>'0');
    signal s_fe_det             : std_logic_vector(1 downto 0);
    signal s_busy               : std_logic :='0';
    --signal s_csn                : std_logic :='1';
    signal s_bytes              : unsigned(12 downto 0):=(others=>'0');
    signal s_byte_cnt           : unsigned(12 downto 0):=(others=>'0');
    signal s_sclk_del_cnt       : unsigned(9 downto 0):=(others=>'0');
    signal s_done               : std_logic;
    signal s_kill_sck           : std_logic := '1';
    signal s_delay_cs           : integer range 0 to 16383 := 0;
    
	
	
  

begin 

fsm_cntrl: process(i_clk)
begin
    if rising_edge(i_clk) then 
        s_load <= '0';
        s_done <= '0';
        case s_current_state is 
            when idle =>                
                s_rx_rd_rqst_reg <= i_rx_rd_rqst;  
                s_rx_data_rdy <= '0';     
                if i_load = '1' or i_rx_rd_rqst = '1' then           -- write data to peripheral
                    --s_csn      <= '0';
                    s_busy <= '1';
                    s_current_state <= sclk_del;
                end if;
            when sclk_del => 
                if s_sclk_del_cnt = C_SCLK_DEL then
                    s_current_state <= load;
                    s_load <= '1';      -- reset sclk counters
                    s_sclk_del_cnt  <= (others=>'0');
                    s_kill_sck <= '0';  -- enable output of sclk
                else
                    s_sclk_del_cnt  <= s_sclk_del_cnt  + x"01";
                end if;
                
            when load => 
                s_current_state <= complete;
                s_load <= '1';
                
            when complete =>
                if s_tmr = (s_tmr'range =>'0') then   --have all 8 bits been shifted out (all 1's initialized to s_tmr are gone)?
                    s_current_state <= cs_del;
                    s_delay_cs <= 0;
                end if;
                
            when cs_del =>
                if s_delay_cs = (g_done_delay) then
                    s_current_state <= idle;
                    s_busy <= '0';
                    s_done <= '1';
                    --s_csn  <= '1';
                    s_delay_cs <= 0;
                    s_rx_data_rdy <= '0';
                elsif s_delay_cs = (g_cs_delay) then
                    s_delay_cs <= s_delay_cs + 1;
                    s_rx_data_rdy <= '1';
                    --s_csn  <= '1';
                elsif s_delay_cs = g_kill_sck then
                    s_kill_sck <= '1';
                    s_delay_cs <= s_delay_cs + 1;
                else
                    s_delay_cs <= s_delay_cs + 1;
                    --s_csn  <= '0';
                end if;
        end case;
    end if;
end process;

sck_gen : process(i_clk)
begin
    if rising_edge(i_clk) then 
        if s_load = '1' or s_kill_sck = '1' then 
            s_sck <= '0';
            s_baud_counter <= (others=>'0');
        elsif s_baud_counter = ((g_clk_freq/g_spi_clk)/2)-1 then --toggle at 50:50 duty cycle 
            s_sck <= not(s_sck);
            s_baud_counter <= (others=>'0');
        else
            s_baud_counter <= s_baud_counter + 1;
        end if;
    end if;        
end process;

edge_det : process(i_clk)
begin
    if rising_edge(i_clk) then 
        s_fe_det <= s_fe_det(s_fe_det'high-1 downto s_fe_det'low) & s_sck;
    end if;
end process;


op_uart : process (i_clk)
begin
  if rising_edge(i_clk) then
    if s_load = '1' then
        s_data_reg  <= i_data ;
		s_rx_data_reg <= (others=>'0');
        s_tmr <= (others => '1');
    elsif s_fe_det = c_fe_det then 
        s_data_reg  <= s_data_reg(s_data_reg'high-1 downto s_data_reg'low) & '0';
        s_tmr <= s_tmr(s_tmr'high - 1 downto s_tmr'low) & '0';
		s_rx_data_reg <= s_rx_data_reg(s_rx_data_reg'high-1 downto s_rx_data_reg'low) & i_miso;
    end if;
  end if;
end process;

o_done    <= s_done;
o_busy    <= s_busy or i_load; 
o_mosi    <= s_data_reg(s_data_reg'high);
o_sclk    <= s_sck when s_kill_sck = '0' else '0';  -- using the cs# signal to enable the output sck
--o_csn   <= s_csn;
o_rx_data <= s_rx_data_reg when s_rx_rd_rqst_reg = '1' else x"00";
o_rx_data_val <= s_rx_rd_rqst_reg and s_rx_data_rdy;

end architecture;