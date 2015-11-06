library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--data should be available on 2nd bclk rising edge after rising daclrc edge (in WM8731 set lrp=1)
--48kHz sampling rate
--18,432MHz MCLK 
--BOSR = 1 (384fs)

entity dsp_slave_reader is
	port (
		reset_n:              in    std_logic;
		
		left_channel_sample:  out   signed(23 downto 0) := (others => '0');
		right_channel_sample: out   signed(23 downto 0) := (others => '0');
		sample_available:     out   std_logic           := '0';
		transmit:             in    std_logic; --starts transmission at rising edge
		
		bclk:                 in    std_logic;
		adclrc:               in    std_logic;
		adcdat:               in    std_logic);
end dsp_slave_reader;

architecture dsp_slave_reader_impl of dsp_slave_reader is
	type fsm is (idle, receive_data, available_data);
	signal state : fsm;
	
	signal received_data_int:       std_logic_vector(47 downto 0);
	signal left_channel_sample_int: signed(23 downto 0);
	signal right_channel_sample_int:signed(23 downto 0);

	signal bits_remaining:          unsigned(5 downto 0);

begin
	left_channel_sample <= left_channel_sample_int;
	right_channel_sample <= right_channel_sample_int;

	process(reset_n, bclk, transmit) begin
		if (reset_n = '0' or transmit = '0') then
			received_data_int <= (others => '0');
			left_channel_sample_int <= (others => '0');
			right_channel_sample_int <= (others => '0');
			sample_available <= '0';
			state <= idle;
			bits_remaining <= (others => '1');
		elsif (rising_edge(bclk)) then
			case state is
				when idle =>
					sample_available <= '0';
					if (adclrc = '1') then
						bits_remaining <= to_unsigned(48, bits_remaining'length);
						state <= receive_data;
					end if;

				when receive_data =>
					if (bits_remaining < 24) then
						sample_available <= '0';
					end if;
					
					if (bits_remaining > 1) then
						bits_remaining <= bits_remaining - 1;
						received_data_int <= received_data_int(46 downto 0) & adcdat;
					else
						left_channel_sample_int <= signed(received_data_int(46 downto 23));
						right_channel_sample_int <= signed(received_data_int(22 downto 0) & adcdat);
						state <= available_data;
					end if;

				when available_data =>
					sample_available <= '1';
					if(adclrc = '1') then
						bits_remaining <= to_unsigned(48, bits_remaining'length);
						state <= receive_data;
					end if;
					
			end case;
		end if;
	end process;
end dsp_slave_reader_impl;