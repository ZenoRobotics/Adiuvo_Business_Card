library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity epaper_cntrl is generic(
    SIMULATION  : integer := 0 
);
    port(
	    -- clocks
        i_clk       : in std_logic;
		i_ms_dly_clk: in std_logic;  -- 1kHz clock
		-- data
		o_data      : out std_logic_vector(7 downto 0);
		i_rx_data   : in  std_logic_vector(7 downto 0);
		i_rx_data_val : in std_logic;
		o_rx_rd_rqst  : out std_logic := '0';
        -- control interface 
		i_config_n  : in std_logic;
        o_rstn      : out std_logic;
        i_busy      : in std_logic;
		o_epaper_pwr_en : out std_logic := '1';
        o_discharge : out std_logic := '0';
		-- spi control/handshake signals
        i_done      : in std_logic;
        o_load      : out std_logic;
		o_cs_n      : out std_logic  -- active low, sent directly to SPI interface
        -- debug leds
		--o_blu_led   : out std_logic;
		--o_red_led   : out std_logic
		
    );      
end entity;

architecture rtl of epaper_cntrl is 
    -- Constants
    constant c_num_init_commands : integer := 87;  -- 71 + 28
    constant c_indices           : integer := 20;  -- 22 + 7 (powerup + powerdown)
	constant c_pwrup_indx_max    : integer := 13;  -- actual index ends at c_pwrup_indx_max - 1
	constant c_pwrdwn_indx_max   : integer := 20;  -- same as c_indices 
    constant c_dsply_bytes       : integer := 32;  -- 1.44" Display: 128 x 96 pixels  
	constant c_half_row_bytes    : integer := 16;
	constant c_scan_bytes        : integer := 24;
	constant c_num_of_rows       : integer := 96;  -- (y) for 1.44" Display
	constant C_ITERS          : integer := 4; -- changed from 4 to 2 for sim purposes PZ
    constant CS_HOLD_HIGH_CNT : integer := 20;
    constant FRAME_DELAY      : integer := 500;
	
	-- Arrays
    type t_memory   is array (0 to c_num_init_commands-1)   of std_logic_vector(7 downto 0); -- stores control commands
    type t_indx_cnt is array (0 to c_indices-1)             of integer;
	type t_scan_byte_en is array (0 to 3)                   of std_logic_vector(7 downto 0);
    
    type fsm        is (idle, spi_rd_state, spi_rd_end, check_cog_id, check_cog_dcdc,
	                    init_cog_cmd, wait_init_cmd_end, init_cog_data, wait_cog_data_end,  
	                    check_rdbk_st, send_data_cmd_byte, wait_cmd_end, 
					    data_byte_half_row, data_byte_end, scan_byte_send, scan_byte_sent,
					    send_border_byte, border_byte_end, turn_on_oe, oe_cmd_end, delay_state, cs_delay_state,
						pwr_off_cmds, wait_pwr_off_cmd_end, pwr_off_data, wait_pwr_off_data_end, pwr_off_pins_state);
						
	type start_stop_fsm is (wait_state, delay_state, run_state, stop_state);
     
    --------------------------------------------------------------------------------------------------
    -- E-paper display COG driver interface cmd + data storage and use. For 1.44" EPD with G2 COG and
    -- Aurora MD Film
    --
    -- s_cntrl:  an array 8-bit (byte) values hold the headers, commands, and data values for power-up
    --           and powerdown phases.
    --           The data is shown in rows to help visualize their groupings and functionalities. It is also
    --           the basis for the arrays below that hold additional information about these virtual "rows".
    --
    -- s_pwrup_data_qty_array  : holds the number of hdrs, cmd, and data bytes found in each "row" in s_cntrl. 
    --
    -- s_pwrup_dly_times_array : holds the delay in ms required after the tx of the "row" of bytes in s_cntrl.
	--
	-- s_curr_indx:  index which accumulates to point to each element in the two power-up arrays above.
	--
	-- s_total_cmd_cnt: index which accumulates to point to each element in s_cntrl.
    --------------------------------------------------------------------------------------------------
	
    signal s_cntrl : t_memory := (  -- Initialize G2 COG Driver (Powerup): headers, commands, and data sequence
	                                -- *Note: By Passing SPI read of COG ID for now
	                                --Init_PhaseA 
	                                x"70", x"02", x"72", x"40",   --Disable OE
                                    x"70", x"0B", x"72", x"02",   --Power Saving Mode
									--Check_ID
									-- Channel Select for 1.44", Cmd Indx 0x01 = 8 Data Bytes 
									-- pg 25 of E-paper Display COG Driver Interface Timing doc
									--Init_PhaseB
									x"70", x"01", x"72", x"00", x"00", x"00", x"00", x"00", x"0F", x"FF", x"00",   
									x"70", x"07", x"72", x"D1",   --High Power Mode Osc Setting
									x"70", x"08", x"72", x"02",   --Power Setting
									x"70", x"09", x"72", x"C2",   --Set Vcom Level
									x"70", x"04", x"72", x"03",   --Power Setting
									x"70", x"03", x"72", x"01",   --Driver latch on
									x"70", x"03", x"72", x"00",   --Driver latch off
									--Delay_St5
									-- Delay >= 5ms then Chargepump Start
									-- "loop" several times to make sure Charge pump has started. Should verify
									-- with a read to the ePaper ... not included
									--===============
									-- 1st time:
									x"70", x"05", x"72", x"01",   --Start chargepump pos. volt. on VGH & VDH
									-- Delay >= 150ms
									x"70", x"05", x"72", x"03",   --Start chargepump neg. volt. on VGH & VDH
									-- Delay >= 90ms
									x"70", x"05", x"72", x"0F",   --Set chargepump Vcom on
									-- Delay >= 40ms
									--===============
									--Check_RdBk_St
									-- Check (read) 0x0F: Readback == 0x40? If yes, then
									-- End of power init phase with next command
									x"70", x"02", x"72", x"06",   --Output enable to disable
									-------------------------------------
									-- Powerdown headers, commands, and data sequence
									-------------------------------------
									x"70", x"0B", x"72", x"00",
									x"70", x"03", x"72", x"01",
									x"70", x"05", x"72", x"03",
									x"70", x"05", x"72", x"01",
									-- delay 300 ms --
									x"70", x"04", x"72", x"80",
									x"70", x"05", x"72", x"00",
									x"70", x"07", x"72", x"01"
                                    ); 
									
    
	-- number of data bytes in each command instruction row of s_cntrl
	signal s_pwrup_data_qty_array : t_indx_cnt:= (4,4,11,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4);  
	-- delay times are for after the sending of the cmd and data in that index
	--signal s_pwrup_dly_times_array: t_indx_cnt := (0,0,0,0,0,0,0,0,5,160,95,45,0,0,0,0,300,0,0,50); -- non-sim values
	signal s_pwrup_dly_times_array: t_indx_cnt; --:= (0,0,0,0,0,0,0,0,5,5,5,5,0,0,0,0,5,0,0,5);  -- simulation values PZ
	  
	
	signal s_scan_byte_en   : t_scan_byte_en := ( x"03", x"0C", x"30", x"C0" );
    signal s_local_seg_pos  : integer range 0 to 4 := 0; -- determine index for s_scan_byte_en() array 
    signal s_current_state  : fsm := idle;
	signal s_next_state     : fsm := idle;  -- used primarily for using one delay state for variable lengths of time
	signal s_state_after_spi_rd : fsm := idle; 
	signal s_curr_state_slow_clock : fsm := idle;
    signal s_curr_cmd_lnght : integer := 0;
	signal s_curr_indx      : integer := 0;
	signal s_curr_cmd_cnt   : integer := 0;
	signal s_total_cmd_cnt  : integer := 0;
	signal s_delay_ms       : integer := 0;
	signal r_delay_ms       : integer := 0;
	signal s_delay_cnt      : integer := 0;
	signal s_oe_data_sent   : integer := 0;
	signal s_header_sent    : integer := 0;
	signal s_num_bytes_sent : integer := 0;
	
	signal s_start_state    : start_stop_fsm := wait_state;
	
    signal s_data_byte_tx_cnt      : integer := 0; 
	signal s_scan_byte_tx_cnt      : integer := 0;
	signal s_half_byte_state  : integer := 0;   -- Data is compressed in bram, so need to expand half byte into a byte 0=lft nibble, 1=rght nibble
	signal s_row_count      : integer range 0 to 100 := 0;
	signal s_row_vector_cnt : std_logic_vector(7 downto 0):= (others => '0');
	signal s_scan_seg_indx  : integer range 0 to 25 := 0;  --points to current scan segment y is in (row group w/range of 4)
	signal s_scan_seg_cntr  : integer range 0 to 25 := 23;  --counts up during scan, then resets to 1
	signal s_delay_reached  : integer range 0 to  1 := 0;
	signal s_pos_edge_delay_reached : integer := 0;
	signal r_pos_edge_delay_reached : integer := 0;
	signal s_pwr_on_cntr    : integer range 0 to 12 := 0;
	signal s_delay_cs_cnt   : integer range 0 to 1001 := 0; 
	signal s_cs_hold_cnt    : integer range 0 to 1000 := 0; 

 
    signal uns_b_address   : unsigned(10 downto 0);
    signal b_data_byte     : std_logic_vector(7 downto 0);
    signal b_data_byte_neg : std_logic_vector(7 downto 0);
    signal r_config_n      : std_logic := '1';
    signal s_config        : std_logic := '0';
    signal s_start_sm      : std_logic := '0';
	signal r_rstn          : std_logic := '0';
	signal s_cs_n          : std_logic := '1';
	signal s_blank         : std_logic := '0';
	signal s_toggle        : std_logic := '0';
	signal s_pwr_en        : std_logic := '0';
	signal s_discharge     : std_logic := '0';
	signal s_pwrup_st      : integer := 0;
	signal s_loop_cnt      : integer range 0 to 7 := 0;
	signal s_run_again     : integer range 0 to 7 := 0;
	
	signal s_iter_cnt      : integer range 0 to 10 := 0;
	signal s_restart_full_loop  : integer := 0;
	signal s_curr_row_addr_max_indx : integer := 0;
	
	
	signal s_rx_data     : std_logic_vector(7 downto 0) := (others=>'0');
	signal s_rx_data_val : std_logic := '0';
	signal r_rx_data_val : std_logic := '0';
	signal r_rx_data     : std_logic_vector(7 downto 0) := (others=>'0');



begin 

	--spram_inst : entity work.dist_spram 
	--port map (
	--    clk_i     => i_clk, 
     --   clk_en_i  => '1', 
     --   wr_en_i   => '0', 
     --   wr_data_i => x"00", 
     --   addr_i    => uns_b_address, --b_address, 
     --   rd_data_o => b_data_byte
	--	) ;
		
	image_bram_inst : entity work.image_bram 
	port map (
	    rd_clk_i => i_clk,  
        rd_en_i  => '1', 
        rd_clk_en_i => '1', 
        rd_addr_i => uns_b_address, 
        rd_data_o => b_data_byte
		) ;
	
-- delay times are for after the sending of the cmd and data in that index
s_pwrup_dly_times_array <= (0,0,0,0,0,0,0,0,5,5,5,5,0,0,0,0,5,0,0,5) when SIMULATION = 1 else
                           (0,0,0,0,0,0,0,0,5,160,95,45,0,0,0,0,300,0,0,50); -- non-sim values
 
o_rstn   <= r_rstn; --epaper resetn
o_epaper_pwr_en <= s_pwr_en;
o_cs_n <= s_cs_n;
o_discharge <= s_discharge;

-- power up resetn to epaper
process(i_clk)
begin
    if rising_edge(i_clk) then 
        r_config_n <= i_config_n;  
	    s_pos_edge_delay_reached <= s_delay_reached;
        case s_start_state is 
            when wait_state => 
               if i_config_n = '0' and r_config_n = '1' then --negedge of user input i_config (debounced pb)
                  s_start_sm <= '0';  -- start state_machine
                  s_config   <= '1';
			      s_toggle   <= '0';
                  r_rstn     <= '0';   
			      s_pwr_en   <= '1';
			      r_delay_ms <= 5; -- 5ms delay
			      s_loop_cnt <= 0;
			      s_start_state <= delay_state;
			    else
			      r_rstn     <= '0';   
			      s_pwr_en   <= '0';
			      s_start_sm <= '0';
			      s_start_state <= wait_state;
			    end if;  
            when delay_state =>  
                if (s_delay_reached = 1) and (r_delay_ms > 0) and (s_current_state = idle) then -- rstn delay occurred?
	              r_rstn     <= '1';     -- disable reset
			      s_pwr_en   <= '1';     -- keep power enabled
			      r_delay_ms <= 0;
			      s_start_sm <= '1'; 
                  s_start_state <= run_state;
			    end if;
            when run_state =>
                if s_current_state /= idle then
                   s_start_sm <= '0';
                   r_rstn     <= '1';     
			       s_pwr_en   <= '1';
                   s_start_state <= stop_state;
                end if;
            when stop_state =>
                if s_current_state = pwr_off_pins_state then
                   r_rstn   <= '0';   
			       s_pwr_en <= '0';
			       s_start_state <= wait_state;
			    end if;
			when others => null;
        end case; 
     end if;
end process;


-- ms delay procedure --
process(i_ms_dly_clk)
begin
   if rising_edge(i_ms_dly_clk) then 
      if s_delay_ms > 0 and s_delay_reached = 0 then	  
          if s_delay_cnt = s_delay_ms then
			  s_delay_reached <= 1;
		  else
		      s_delay_cnt <= s_delay_cnt + 1;
	      end if; 
	  elsif r_delay_ms > 0 and s_delay_reached = 0 then	  
          if s_delay_cnt = r_delay_ms then
			  s_delay_reached <= 1;
		  else
		      s_delay_cnt <= s_delay_cnt + 1;
	      end if; 
      else
	      s_delay_reached <= 0;	 
          s_delay_cnt <= 0;		  
      end if;
    end if;
end process;


process(i_clk)
begin
    if rising_edge(i_clk) then 
        o_load  <= '0';
		s_rx_data <= i_rx_data;
		s_rx_data_val <= i_rx_data_val;
        case s_current_state is 
            when idle =>
			    s_cs_n <= '1';
			    s_blank  <= '1'; -- clear screen first
				o_data <= x"00";
                if s_start_sm = '1' then
				   --o_blu_led <= '0';
				   -- delay between resetn going high and startup
                   s_current_state <= delay_state;  
				   s_next_state    <= spi_rd_state;  --get_cog_id;
				   s_state_after_spi_rd <= check_cog_id;
				   s_delay_ms <= 10;
                   --b_address <= (others => '0');
				   uns_b_address <= (others => '0');
				   ----
				   s_curr_cmd_lnght <= s_pwrup_data_qty_array(0);  
				   s_curr_indx     <= 1;
				   s_curr_cmd_cnt  <= 0;
				   s_total_cmd_cnt <= 0;
				   s_row_count <= 0;
				   s_half_byte_state <= 0;
				   s_curr_row_addr_max_indx <= 15;
				   s_iter_cnt <= 0;
                end if;
				
		    --- Start of CoG Initialization ---
			--- Get and Check CoG ID ---
			when spi_rd_state =>
			    s_run_again <= 0; --reset count for now
			    o_rx_rd_rqst <= '0';
			    if i_busy = '0' or r_rx_data_val = '1' then
			       if s_num_bytes_sent = 0 then
					   o_data <= x"70";
					   s_cs_n <= '0';
					   o_load <= '1';
					   s_current_state <= spi_rd_end;
				   elsif s_num_bytes_sent = 1 then  
				       o_data <= x"0f"; --cmd
					   s_cs_n <= '0';
					   o_load <= '1';
					   s_current_state <= spi_rd_end;
				   elsif s_num_bytes_sent = 2 and s_cs_n = '0' then
				       s_cs_n <= '1'; 
					   o_load <= '0';
					   s_current_state <= cs_delay_state;
					   s_next_state <= spi_rd_state;
					   s_cs_hold_cnt <= CS_HOLD_HIGH_CNT;
				   elsif s_num_bytes_sent = 2 then
				      if s_state_after_spi_rd = check_cog_id then
				         o_data <= x"73"; -- spi_r
				      else 
				         o_data <= x"71"; -- spi_rid
				      end if;
					  s_cs_n <= '0';
					  o_load <= '1';
					  s_current_state <= spi_rd_end;
				   elsif s_num_bytes_sent = 3 then
				      o_data <= x"00"; --data
					  s_cs_n <= '0';
					  o_load <= '1';
					  s_current_state <= spi_rd_end;
					  o_rx_rd_rqst <= '1';
				   elsif r_rx_data_val = '1' then -- acquire SPI MISO data then go to next state and check id     
					  s_num_bytes_sent <= 0;
					  s_cs_n <= '1'; 
					  o_load <= '0';
					  r_rx_data_val <= '1';
					  s_rx_data_val <= '0';
					  s_current_state <= cs_delay_state;
					  s_next_state <= s_state_after_spi_rd;
					  s_cs_hold_cnt <= CS_HOLD_HIGH_CNT;
					else
					  s_current_state <= spi_rd_state;
				   end if;
	
				end if;
				
			when spi_rd_end =>
				o_load  <= '0';
				o_rx_rd_rqst <= '0';
                if i_done = '1' then 
                    s_current_state <= spi_rd_state;
					s_num_bytes_sent <= s_num_bytes_sent + 1;
					r_rx_data_val <= s_rx_data_val;
					r_rx_data <= i_rx_data;
				end if;
				
			when check_cog_id =>   --will stay in loop forever if no data is received (valid)
			    if r_rx_data_val = '1' then
			       r_rx_data_val <= '0';
				   if r_rx_data = x"12" then
				     --turn on led blue
				   else
				     --turn on led red
				   end if;
				   s_current_state <= init_cog_cmd;
				end if;
			    
			-- s_cntrl(hdrc, cmd, hdrd, data, ...)  
			--------------------------------
            --- Power on state/substates ---
			--------------------------------
            when init_cog_cmd =>
			    -- first check to see if all cmds+data have been sent
                if s_curr_indx = c_pwrup_indx_max then  -- full set of powerup cmds and data have been sent				
				    s_current_state <= spi_rd_state;    -- go to send frame data loop
				    s_next_state <= spi_rd_state;
				    s_state_after_spi_rd <= check_cog_dcdc;
					s_curr_cmd_lnght <= s_pwrup_data_qty_array(s_curr_indx);
				    s_row_count <= 0;		
					--s_curr_indx <= 0;
					s_curr_cmd_cnt <= 0;
					--s_total_cmd_cnt <= 0;
                	s_cs_n <= '1';		
                -- send out cmd header and cmd bytes
                elsif i_busy = '0' then 
				    if s_curr_cmd_cnt = 2 then  -- header and command have been sent. Hold CS_n high for CS_HOLD_HIGH_CNT
					    s_cs_n <= '1';
						s_current_state <= cs_delay_state;
						s_cs_hold_cnt <= CS_HOLD_HIGH_CNT;
					    s_next_state <= init_cog_data;
						--s_curr_cmd_cnt <= 0;
				    else
                        o_load <= '1';
					    s_cs_n <= '0';
                        o_data  <= s_cntrl(s_total_cmd_cnt); 
                        s_current_state <= wait_init_cmd_end;
					end if;
                end if;
				
            when wait_init_cmd_end =>
			    o_load  <= '0';
                if i_done = '1' then 
                    s_curr_cmd_cnt <= s_curr_cmd_cnt + 1;
					s_total_cmd_cnt <= s_total_cmd_cnt + 1;
                    s_current_state <= init_cog_cmd;
                end if;
				
	---------------------
			
			-- Will need to add check_id_st here ---
			-- s_pwrup_data_qty_array( , , ... , )    s_pwrup_dly_times_array( , , ... , )
			when init_cog_data =>
                if s_curr_cmd_cnt = s_curr_cmd_lnght then 
				    -- check for delay in s_pwrup_dly_times_array( , , ... , )
					-- make decision to go to ms delay if > 0 or cs_delay_state
					s_cs_n <= '1';
					s_curr_cmd_lnght <= s_pwrup_data_qty_array(s_curr_indx);
					s_curr_indx <= s_curr_indx + 1;
					s_curr_cmd_cnt <= 0;
					s_next_state <= init_cog_cmd;
					if s_pwrup_dly_times_array(s_curr_indx) > 0 then
					    s_current_state <= delay_state;
					    s_delay_ms  <= s_pwrup_dly_times_array(s_curr_indx);
				    else
					    s_current_state <= cs_delay_state;
					    s_cs_hold_cnt <= CS_HOLD_HIGH_CNT;    
					end if;	
                elsif i_busy = '0' then 
                        o_load <= '1';
					    s_cs_n <= '0';
                        o_data  <= s_cntrl(s_total_cmd_cnt); 
                        s_current_state <= wait_cog_data_end;
                end if;

				
            when wait_cog_data_end =>
			    o_load  <= '0';
                if i_done = '1' then 
                    s_curr_cmd_cnt <= s_curr_cmd_cnt + 1;
					s_total_cmd_cnt <= s_total_cmd_cnt + 1;
                    s_current_state <= init_cog_data;
                end if;
			
			--- End of CoG Initialization/Powerup ---
			
			when check_cog_dcdc =>   
			    if r_rx_data_val = '1' then
			       r_rx_data_val <= '0';
				   if r_rx_data = x"12" then
				     --turn on led blue
				   else
				     --turn on led red
				   end if;
				   s_current_state <= send_data_cmd_byte;
				   s_next_state <= send_data_cmd_byte;
				end if;
				
			---- Start of Data Transfer Loop -----
            --c_half_row_bytes  = 16
	        --c_scan_bytes = 24
	        --s_data_byte_tx_cnt starts at 0      
	        --s_scan_byte_tx_cnt starts at 0
			--c_num_of_rows = 96
			--s_row_count starts at 0, increment at end of 2nd half row tx
			
			when send_data_cmd_byte =>
			    if s_row_count = c_num_of_rows then  -- full frame + scan and border has been loaded and displayed
                   --o_blu_led <= '1';				
				   s_current_state <= pwr_off_cmds;  -- go to pwrdwn_state
				   s_iter_cnt <= s_iter_cnt + 1;
				   --b_address <= (others => '0');
				   uns_b_address <= (others => '0');
				   s_curr_row_addr_max_indx <= 15;
				elsif i_busy = '0' then 
				   if s_header_sent = 0 then
				      o_data  <= x"70";  --Command header
				      --b_address <= std_logic_vector(to_unsigned(s_curr_row_addr_max_indx, b_address'length)); --update bram addr to max for row data 
					  uns_b_address <= to_unsigned(s_curr_row_addr_max_indx, uns_b_address'length);
				   else
				      o_data  <= x"0A";  --Sending Data Command
				   end if;
			       s_current_state <= wait_cmd_end;
				   o_load <= '1';
				   s_cs_n <= '0';
				end if;
				
            when wait_cmd_end =>
			    o_load  <= '0';
                if i_done = '1' then
                   if s_header_sent = 0 then
                       s_header_sent <= 1;
                       s_current_state <= send_data_cmd_byte;
                   else			
                       s_header_sent <= 0;				   
                       s_current_state <= cs_delay_state;
					   s_cs_hold_cnt <= CS_HOLD_HIGH_CNT;
					   s_next_state <= data_byte_half_row;
					   s_cs_n <= '1';
				   end if;
                end if;			
				
			-- Send Data --
            when data_byte_half_row =>
                if s_data_byte_tx_cnt = c_half_row_bytes and s_next_state /= send_border_byte then  -- go to scan byte 
                    s_current_state <= scan_byte_send; 
                    s_data_byte_tx_cnt <= 0;
					s_next_state <= data_byte_half_row; -- to stop return to this state from entering this option again (s_data_byte_tx_cnt = 16)
					s_half_byte_state <= 1;
					uns_b_address <= to_unsigned(s_curr_row_addr_max_indx - 15, uns_b_address'length); -- make sure we are starting at the bottom of the address range
		        elsif s_data_byte_tx_cnt = (c_half_row_bytes * 2) then  -- go to send border data
		            s_curr_row_addr_max_indx <= s_curr_row_addr_max_indx + 16;
				    s_current_state <= send_border_byte;
					s_data_byte_tx_cnt <= 0;
					s_half_byte_state <= 0;
					s_row_count <= s_row_count + 1; --increment y
					s_row_vector_cnt <= std_logic_vector(to_unsigned(to_integer(unsigned( s_row_vector_cnt )) + 1, 8));
                elsif i_busy = '0' then       -- header then load pattern based on odd/even data bytes range
				    if s_header_sent = 0 then
					    o_data <= x"72";
				    elsif s_blank = '1' then
					    o_data  <= x"aa";
						--o_data  <=  x"00"; --x"00"; -- no change or nothing
					--elsif s_iter_cnt >= C_ITERS - 4 then
					--    o_data  <= x"aa";
					else 
					   if s_half_byte_state = 0 then --first half of row scan: 127 -> 1 or relative to indices 126->0
					      o_data  <= '1' & b_data_byte(1) & '1' & b_data_byte(3) &  '1' & b_data_byte(5) & '1' & b_data_byte(7);
					   else   -- second half of row scan: 2-> 128 or relative to indices 1->127
					      o_data  <= '1' & b_data_byte(6) & '1' & b_data_byte(4) &  '1' & b_data_byte(2) & '1' & b_data_byte(0);
					   end if;
					end if;
					--else
					    --if s_toggle = '0' then
					    --    o_data  <=  x"aa"; -- white for even pixels
						--else
						--    o_data  <=  x"ff"; -- white for even pixels 
                    o_load <= '1';
					s_cs_n <= '0';
				    s_current_state <= data_byte_end;
                end if;
                
            when data_byte_end =>
                o_load  <= '0';
                if i_done = '1' then 
				   if s_header_sent = 0 then
                       s_header_sent <= 1;
                   elsif s_half_byte_state = 0  then
                       --b_address   <= std_logic_vector( unsigned(b_address) - 1 );
					   uns_b_address   <= uns_b_address - 1;
                       s_data_byte_tx_cnt <= s_data_byte_tx_cnt + 1;
                   else
                       --b_address   <= std_logic_vector( unsigned(b_address) + 1 );
					   uns_b_address   <= uns_b_address + 1;
                       s_data_byte_tx_cnt <= s_data_byte_tx_cnt + 1;
                   end if;
				   s_current_state <= data_byte_half_row;
                end if;
				
			 --For programming reference--	
			 --s_scan_byte_tx_cnt : integer := 0;
	         --s_row_count      : integer := 0;
	         --s_scan_seg_indx  : integer range 0 to 23 := 0;  --points to current scan segment y is in (row group w/range of 4) counts down
	         --s_scan_seg_cntr  : integer range 0 to 23 := 23;  --counts up during scan, then resets to 1
		     when scan_byte_send =>
			    s_cs_n <= '0';
                if s_scan_byte_tx_cnt = c_scan_bytes then
				   s_current_state <= data_byte_half_row;
				   s_next_state <= send_border_byte;   -- important to have here correct decision making in return to data_byte_half_row
				   s_scan_byte_tx_cnt <= 0;
				   s_scan_seg_cntr <= 23;
				   --if TO_INTEGER(signed(s_row_vector_cnt(1 downto 0))) = 3 then
				   if s_row_vector_cnt(1) = '1' and s_row_vector_cnt(0) = '1' then
				       s_scan_seg_indx <= s_scan_seg_indx + 1;
				   end if;
				elsif i_busy = '0' then  
				   s_current_state <= scan_byte_sent;
				   if s_scan_seg_cntr = s_scan_seg_indx then
				        o_data <= s_scan_byte_en(TO_INTEGER(unsigned(s_row_vector_cnt(1 downto 0))));
				   else
				        o_data <= x"00";
				   end if;
				   
                   o_load <= '1';				  
				end if;
				   
             when scan_byte_sent =>
                o_load  <= '0';
                if i_done = '1' then 
                    s_current_state <= scan_byte_send;
                    s_scan_byte_tx_cnt <= s_scan_byte_tx_cnt + 1;
					s_scan_seg_cntr <= s_scan_seg_cntr - 1;
			    end if;
				
			 when send_border_byte =>
			    if i_busy = '0' then 
				    s_current_state <= border_byte_end;
				    if s_blank = '0' then
			           o_data <= x"00";
			        else
			           o_data <= x"AA";
			        end if;
                    o_load <= '1';
				end if;
			   
             when border_byte_end => 
			    o_load  <= '0';
                if i_done = '1' then 
                    s_current_state <= cs_delay_state;
					s_cs_hold_cnt <= CS_HOLD_HIGH_CNT;
					s_next_state <= turn_on_oe;
					s_header_sent <= 0;
					s_cs_n <= '1';
				end if;
				
			 when turn_on_oe => 
			    if s_oe_data_sent = 4 then
			       s_current_state <= cs_delay_state;
				   s_next_state <= send_data_cmd_byte;
				   s_oe_data_sent <= 0;
				   s_cs_n <= '1';
				   s_cs_hold_cnt <= CS_HOLD_HIGH_CNT;
				elsif i_busy = '0' then
				   if s_oe_data_sent = 0 then
					   o_data <= x"70";
					   s_cs_n <= '0';
					   o_load <= '1';
					   s_current_state <= oe_cmd_end;
				   elsif s_oe_data_sent = 1 then  
				       o_data <= x"02"; --cmd
					   s_cs_n <= '0';
					   o_load <= '1';
					   s_current_state <= oe_cmd_end;
				   elsif s_oe_data_sent = 2 and s_cs_n = '0' then
				       s_cs_n <= '1'; 
					   o_load <= '0';
					   s_current_state <= cs_delay_state;
					   s_next_state <= turn_on_oe;
					   s_cs_hold_cnt <= CS_HOLD_HIGH_CNT;
				   elsif s_oe_data_sent = 2 then
				      o_data <= x"72";
					  s_cs_n <= '0';
					  o_load <= '1';
					  s_current_state <= oe_cmd_end;
				   else
				      o_data <= x"07"; --data
					  s_cs_n <= '0';
					  o_load <= '1';
					  s_current_state <= oe_cmd_end;
				   end if;
				   				   
				end if;
				
			 when oe_cmd_end => 			 
                o_load  <= '0';
                if i_done = '1' then 
                    s_current_state <= turn_on_oe;
					s_oe_data_sent <= s_oe_data_sent + 1;
				end if;
				
				---- End of Data Transfer Loop -----
				
			 when delay_state =>
			    if s_delay_reached = 1 and s_delay_cnt = s_delay_ms then
			       s_current_state <= s_next_state;
				   s_delay_ms  <= 0;
                end if;
				
			 when cs_delay_state =>
			    if s_delay_cs_cnt = s_cs_hold_cnt then
				   s_current_state <= s_next_state;
				   s_delay_cs_cnt <= 0;
				   s_cs_hold_cnt  <= 0;
				else
				   s_delay_cs_cnt <= s_delay_cs_cnt + 1;
				end if;
				   
			 ----------------------------------
			 --- Powerdown Sequence States ---
			 ----------------------------------
			 when pwr_off_cmds =>
			    if s_iter_cnt < C_ITERS then  -- go through x iterations after initial blank out.
                       -- Adding frameRepeat Delay could be a function of Temp
					   s_current_state <= delay_state;    -- go to send frame data loop
					   s_next_state <= send_data_cmd_byte;
					   if SIMULATION = 1 then
			               s_delay_ms <= 5;
			           else 
			               s_delay_ms <= FRAME_DELAY; -- Frame Delay
			           end if;
					   s_blank    <= '0';
                       s_row_count <= 0;		
					   s_curr_cmd_cnt <= 0;
                	   s_cs_n <= '1';	
					   s_row_vector_cnt <= (others => '0');
					   s_scan_seg_indx <= 0;
					   s_header_sent <= 0;
					   s_data_byte_tx_cnt <= 0;
			    -- first check to see if all cmds+data have been sent
                elsif s_curr_indx = c_indices then  -- full set of powerdown cmds and data have been sent
				       s_current_state <= delay_state;    -- go to send frame data loop
					   s_next_state <= pwr_off_pins_state;
					   s_delay_ms  <= 10;
					   s_row_count <= 0;		
					   s_curr_indx <= 0;
					   s_curr_cmd_cnt <= 0;
					   s_total_cmd_cnt <= 0;
                	   s_cs_n <= '1';	
                	   s_row_vector_cnt <= (others => '0');
					   s_scan_seg_indx <= 0;
					   s_header_sent <= 0;	   
					--end if;
                -- send out cmd header and cmd bytes
                elsif i_busy = '0' then 
				    if s_curr_cmd_cnt = 2 then  -- header and command have been sent. Hold CS_n high for CS_HOLD_HIGH_CNT
					    s_cs_n <= '1';
						s_current_state <= cs_delay_state;
						s_cs_hold_cnt <= CS_HOLD_HIGH_CNT;
					    s_next_state <= pwr_off_data;
						--s_curr_cmd_cnt <= 0;
				    else
                        o_load <= '1';
					    s_cs_n <= '0';
                        o_data  <= s_cntrl(s_total_cmd_cnt); 
                        s_current_state <= wait_pwr_off_cmd_end;
					end if;
                end if;
				
            when wait_pwr_off_cmd_end =>
			    o_load  <= '0';
                if i_done = '1' then 
                    s_curr_cmd_cnt <= s_curr_cmd_cnt + 1;
					s_total_cmd_cnt <= s_total_cmd_cnt + 1;
                    s_current_state <= pwr_off_cmds;
                end if;
						
			when pwr_off_data =>
                if s_curr_cmd_cnt = s_curr_cmd_lnght then 
				    -- check for delay in s_pwrup_dly_times_array( , , ... , )
					-- make decision to go to ms delay if > 0 or cs_delay_state
					s_cs_n <= '1';
					s_curr_cmd_lnght <= s_pwrup_data_qty_array(s_curr_indx);
					s_curr_indx <= s_curr_indx + 1;
					s_curr_cmd_cnt <= 0;
					s_next_state <= pwr_off_cmds;
					if s_pwrup_dly_times_array(s_curr_indx) > 0 then
					    s_current_state <= delay_state;
					    s_delay_ms  <= s_pwrup_dly_times_array(s_curr_indx);
				    else
					    s_current_state <= cs_delay_state;
					    s_cs_hold_cnt <= CS_HOLD_HIGH_CNT;    
					end if;	
                elsif i_busy = '0' then 
                        o_load <= '1';
					    s_cs_n <= '0';
                        o_data  <= s_cntrl(s_total_cmd_cnt); 
                        s_current_state <= wait_pwr_off_data_end;
                end if;

				
            when wait_pwr_off_data_end =>
			    o_load  <= '0';
                if i_done = '1' then 
                    s_curr_cmd_cnt <= s_curr_cmd_cnt + 1;
					s_total_cmd_cnt <= s_total_cmd_cnt + 1;
                    s_current_state <= pwr_off_data;
                end if;
				
			when pwr_off_pins_state =>
			    if  s_cs_n = '1' then
			        s_current_state <= delay_state;    
					s_next_state <= pwr_off_pins_state;
                	s_cs_n <= '0';
                	if SIMULATION = 1 then
			            s_delay_ms <= 5;
			        else 
			            s_delay_ms <= 150; 
			        end if;		
			        s_discharge <= '1';
				else
				    s_current_state <= idle;
					s_next_state <= idle;
				    s_discharge <= '0';
				    s_run_again <= s_run_again + 1;
				end if;
			--- End of CoG Powerdown ---
			
             when others => null;
        end case; 

    end if;


end process;

end rtl;