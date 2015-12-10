library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2c_master_writer is
	port (
		clk:                  in    std_logic;
		reset_n:              in    std_logic;
		
		address:              in    std_logic_vector(6 downto 0);
		byte1:                in    std_logic_vector(7 downto 0);
		byte2:                in    std_logic_vector(7 downto 0);
		
		transmission_start:   in    std_logic;
		transmission_ongoing: out   std_logic := '0';

		i2c_sdat:             out   std_logic := 'Z';
		i2c_sclk:             out   std_logic := 'Z');
end i2c_master_writer;

architecture i2c_master_writer_impl of i2c_master_writer is
	type fsm is (idle, start_signal, send_address, send_write_bit, ack_address, send_byte1, ack_byte1, send_byte2, ack_byte2, stop_signal);
	signal state:                   fsm;
	
	signal address_int:             std_logic_vector(6 downto 0);
	signal byte1_int:               std_logic_vector(7 downto 0);
	signal byte2_int:               std_logic_vector(7 downto 0);

	signal trans_clk_enabled_int:   std_logic;
	signal transmission_ongoing_int:std_logic;

	signal bits_remaining:          unsigned(3 downto 0);

begin
	transmission_ongoing <= transmission_ongoing_int or transmission_start;
	i2c_sclk <= clk or not trans_clk_enabled_int;

	process(reset_n, clk) begin
		if (reset_n = '0') then
			transmission_ongoing_int <= '0';
			trans_clk_enabled_int <= '0';	
			i2c_sdat <= '1';
			state <= idle;
		elsif (falling_edge(clk)) then
			case state is
				when idle =>
					if (transmission_start = '1') then
						address_int <= address;                 --on rising egde save transmission parameters
						byte1_int <= byte1;     
						byte2_int <= byte2;

						transmission_ongoing_int <= '1';
						
						i2c_sdat <= '0';                        --send start signal
						state <= start_signal;
					else 
						transmission_ongoing_int <= '0';

						i2c_sdat <= '1';
						state <= idle;
					end if;
				when start_signal =>					
					bits_remaining <= to_unsigned(6, bits_remaining'length);
					i2c_sdat <= address_int(6);                 --send first bit
					address_int <= address_int(5 downto 0) & '0';
					state <= send_address;
				when send_address =>
					if (bits_remaining > 0) then
						bits_remaining <= bits_remaining - 1;
						i2c_sdat <= address_int(6);             --send remaining bits
						address_int <= address_int(5 downto 0) & '0';
						state <= send_address;
					else
						i2c_sdat <= '0';                        --send write bit
						state <= send_write_bit;
					end if;
				when send_write_bit =>
					i2c_sdat <= 'Z';                            --await ack
					state <= ack_address;
				when ack_address =>                             --get ack
					bits_remaining <= to_unsigned(7, bits_remaining'length);
					i2c_sdat <= byte1_int(7);                   --send first bit
					byte1_int <= byte1_int(6 downto 0) & '0';                 
					state <= send_byte1;    
				when send_byte1 =>
					if (bits_remaining > 0) then
						bits_remaining <= bits_remaining - 1;
						i2c_sdat <= byte1_int(7);               --send remaining bits
						byte1_int <= byte1_int(6 downto 0) & '0';
						state <= send_byte1;
					else
						i2c_sdat <= 'Z';                        --await ack
						state <= ack_byte1;
					end if;
				when ack_byte1 =>                               --get ack
					bits_remaining <= to_unsigned(7, bits_remaining'length);
					i2c_sdat <= byte2_int(7);                   --send first bit
					byte2_int <= byte2_int(6 downto 0) & '0';   
					state <= send_byte2; 
				when send_byte2 =>
					if (bits_remaining > 0) then
						bits_remaining <= bits_remaining - 1;
						i2c_sdat <= byte2_int(7);               --send remaining bits
						byte2_int <= byte2_int(6 downto 0) & '0';
						state <= send_byte2;
					else
						i2c_sdat <= 'Z';                        --await ack
						state <= ack_byte2;
					end if;
				when ack_byte2 =>                               --get ack
					i2c_sdat <= '0';			                --get sdat low for stop signal
					state <= stop_signal;
				when stop_signal =>
					i2c_sdat <= '1';                            --send stop signal
					state <= idle;
			end case;
		elsif(rising_edge(clk)) then
			case state is
				when idle => trans_clk_enabled_int <= '0';
				when start_signal => trans_clk_enabled_int <= '1';
				when stop_signal => trans_clk_enabled_int <= '0';
				when others => null;
			end case;
		end if;
	end process;
end i2c_master_writer_impl;