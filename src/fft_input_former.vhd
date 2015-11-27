library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fft_input_former is
	generic (
		number_of_samples:          integer := 3; --for testing 3
		bits_per_sample:            integer := 2); --for testing 2
	port (
		reset_n:              in    std_logic;
		bclk:                 in    std_logic;

		sample_available_from_adc:     in    std_logic;
		left_channel_sample_from_adc:  in    signed(bits_per_sample - 1 downto 0);
		right_channel_sample_from_adc: in    signed(bits_per_sample - 1 downto 0);
		
		vector_left:          out   std_logic_vector(number_of_samples * bits_per_sample - 1 downto 0) := (others => '0');
		vector_right:         out   std_logic_vector(number_of_samples * bits_per_sample - 1 downto 0) := (others => '0');
		new_vector:           out   std_logic := '0');
end fft_input_former;

architecture fft_input_former_impl of fft_input_former is
	type fsm is (idle, receive_data);
	signal state: fsm;

	signal vector_left_int:   std_logic_vector(number_of_samples * bits_per_sample - 1 downto 0) := (others => '0');
	signal vector_right_int:  std_logic_vector(number_of_samples * bits_per_sample - 1 downto 0) := (others => '0');

	signal trigger_delay:     std_logic := '0';

begin

	process(reset_n, sample_available_from_adc)
		variable samples_remaining: integer := number_of_samples;
	begin
		if (reset_n = '0') then
			vector_left <= (others => '0');
			vector_right <= (others => '0');
			vector_left_int <= (others => '0');
			vector_right_int <= (others => '0');
			trigger_delay <= '0';
		elsif (rising_edge(sample_available_from_adc)) then
			--case state is
				--when idle =>
					--new_vector <= '0';
					--vector_left_int <= vector_left_int((number_of_samples - 1) * bits_per_sample - 1 downto 0) & std_logic_vector(left_channel_sample_from_adc);
					--vector_right_int <= vector_right_int((number_of_samples - 1) * bits_per_sample - 1 downto 0) & std_logic_vector(right_channel_sample_from_adc);						
					--samples_remaining := number_of_samples - 1;
					--state <= receive_data;
				--when receive_data =>	
					--new_vector <= '0';
					if (samples_remaining > 1) then
						samples_remaining := samples_remaining - 1;
						vector_left_int <= vector_left_int((number_of_samples - 1) * bits_per_sample - 1 downto 0) & std_logic_vector(left_channel_sample_from_adc);
						vector_right_int <= vector_right_int((number_of_samples - 1) * bits_per_sample - 1 downto 0) & std_logic_vector(right_channel_sample_from_adc);						
					else
						samples_remaining := number_of_samples;
						vector_left <= vector_left_int((number_of_samples - 1) * bits_per_sample - 1 downto 0) & std_logic_vector(left_channel_sample_from_adc);
						vector_right <= vector_right_int((number_of_samples - 1) * bits_per_sample - 1 downto 0) & std_logic_vector(right_channel_sample_from_adc);
						--state <= available_data;
						trigger_delay <= not trigger_delay;
					end if;

				--when available_data =>
					--new_vector <= '1';
					--vector_left_int <= vector_left_int((number_of_samples - 1) * bits_per_sample - 1 downto 0) & std_logic_vector(left_channel_sample_from_adc);
					--vector_right_int <= vector_right_int((number_of_samples - 1) * bits_per_sample - 1 downto 0) & std_logic_vector(right_channel_sample_from_adc);						
					--samples_remaining := number_of_samples - 1;
					--state <= receive_data;
			--end case;
		end if;
	end process;

	process (reset_n, bclk)
		variable state: integer := 0;
		variable last_trigger_delay: std_logic := trigger_delay;
	begin
		if(reset_n = '0') then
			state := 0;
			last_trigger_delay := trigger_delay;
		elsif (rising_edge(bclk)) then
			if (state = 0 and trigger_delay = not last_trigger_delay) then
				last_trigger_delay := trigger_delay;
				state := 1;
			elsif (state = 1) then
				new_vector <= '1';
				state := 2;
			else
				new_vector <= '0';
				state := 0;
			end if;
		end if;
	end process;

end fft_input_former_impl;