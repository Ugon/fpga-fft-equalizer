library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--data should be available on 2nd bclk rising edge after rising daclrc edge (in WM8731 set lrp=1)
--48kHz sampling rate
--18,432MHz MCLK 
--BOSR = 1 (384fs)

entity dsp_slave_reader is
	generic (
		number_of_samples:                   integer := 16;
		bits_per_sample:                     integer := 24);
	port (
		reset_n:                       in    std_logic;
		
		left_channel_sample_from_adc:  out   signed(bits_per_sample - 1 downto 0) := (others => '0');
		right_channel_sample_from_adc: out   signed(bits_per_sample - 1 downto 0) := (others => '0');
		sample_available_from_adc:     out   std_logic                            := '0';
		
		bclk:                          in    std_logic;
		adclrc:                        in    std_logic;
		adcdat:                        in    std_logic);
end dsp_slave_reader;

architecture dsp_slave_reader_impl of dsp_slave_reader is
	type fsm is (idle, receive_data, available_data);
	signal state: fsm;
	
	signal received_data_int:                std_logic_vector(2 * bits_per_sample - 1 downto 0);
	signal left_channel_sample_from_adc_int: signed(bits_per_sample - 1 downto 0);
	signal right_channel_sample_from_adc_int:signed(bits_per_sample - 1 downto 0);

	signal bits_remaining:                   unsigned(7 downto 0);

begin
	left_channel_sample_from_adc <= left_channel_sample_from_adc_int;
	right_channel_sample_from_adc <= right_channel_sample_from_adc_int;

	process(reset_n, bclk) begin
		if (reset_n = '0') then
			received_data_int <= (others => '0');
			left_channel_sample_from_adc_int <= (others => '0');
			right_channel_sample_from_adc_int <= (others => '0');
			sample_available_from_adc <= '0';
			state <= idle;
			bits_remaining <= (others => '1');
		elsif (rising_edge(bclk)) then
			case state is
				when idle =>
					sample_available_from_adc <= '0';
					bits_remaining <= to_unsigned(2 * bits_per_sample, bits_remaining'length);
					if (adclrc = '1') then
						state <= receive_data;
					end if;

				when receive_data =>
					if (bits_remaining < bits_per_sample) then
						sample_available_from_adc <= '0';
					end if;
					
					if (bits_remaining > 1) then
						bits_remaining <= bits_remaining - 1;
						received_data_int <= received_data_int(2 * bits_per_sample - 2 downto 0) & adcdat;
					else
						left_channel_sample_from_adc_int <= signed(received_data_int(2 * bits_per_sample - 2 downto bits_per_sample - 1));
						right_channel_sample_from_adc_int <= signed(received_data_int(bits_per_sample - 2 downto 0) & adcdat);
						state <= available_data;
					end if;

				when available_data =>
					sample_available_from_adc <= '1';
					bits_remaining <= to_unsigned(2 * bits_per_sample, bits_remaining'length);
					if(adclrc = '1') then
						state <= receive_data;
					end if;
					
			end case;
		end if;
	end process;
end dsp_slave_reader_impl;