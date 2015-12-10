library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fft_output_serializer is
	generic (
		number_of_samples:          integer := 3;
		bits_per_sample:            integer := 2);
	port (
		reset_n:                     in  std_logic;
		bclk:                        in  std_logic;
		
		get_next_sample:             in  std_logic;
		left_channel_sample_to_dac:  out signed(bits_per_sample - 1 downto 0);
		right_channel_sample_to_dac: out signed(bits_per_sample - 1 downto 0);
		sample_available_to_dac:     out std_logic;
		
		vector_left:                 in  std_logic_vector(number_of_samples * bits_per_sample - 1 downto 0) := (others => '0');
		vector_right:                in  std_logic_vector(number_of_samples * bits_per_sample - 1 downto 0) := (others => '0');
		new_vector:                  in  std_logic := '0');
end fft_output_serializer;

architecture fft_output_serializer_impl of fft_output_serializer is
	signal vector_left_int:       std_logic_vector(number_of_samples * bits_per_sample - 1 downto 0) := (others => '0');
	signal vector_right_int:      std_logic_vector(number_of_samples * bits_per_sample - 1 downto 0) := (others => '0');

	signal vector_left_latched:   std_logic_vector(number_of_samples * bits_per_sample - 1 downto 0) := (others => '0');
	signal vector_right_latched:  std_logic_vector(number_of_samples * bits_per_sample - 1 downto 0) := (others => '0');

	signal started:               std_logic := '0';

	signal trigger_delay:         std_logic := '0';
begin
	process(reset_n, new_vector)
	begin
		if(reset_n = '0') then
			vector_left_latched <= (others => '0');
			vector_right_latched <= (others => '0');
			started <= '0';
		elsif rising_edge(new_vector) then
			vector_left_latched <= vector_left;
			vector_right_latched <= vector_right;
			started <= '1';
		end if;
	end process;

	process(reset_n, get_next_sample, started, vector_left_latched, vector_right_latched)
		variable samples_remaining: integer := number_of_samples;
	begin
		if (reset_n = '0' or started = '0') then
			samples_remaining := number_of_samples;
			vector_left_int <= vector_left_latched;
			vector_right_int <= vector_right_latched;
			left_channel_sample_to_dac <= (others => '0');
			right_channel_sample_to_dac <= (others => '0');
		elsif (rising_edge(get_next_sample)) then 
			if(samples_remaining = number_of_samples) then
				vector_left_int <= vector_left_latched((number_of_samples - 1) * bits_per_sample - 1 downto 0) & (bits_per_sample - 1 downto 0 => '0');
				vector_right_int <= vector_right_latched((number_of_samples - 1) * bits_per_sample - 1 downto 0) & (bits_per_sample - 1 downto 0 => '0');
				left_channel_sample_to_dac <= signed(vector_left_latched(number_of_samples * bits_per_sample - 1 downto (number_of_samples - 1) * bits_per_sample));
				right_channel_sample_to_dac <= signed(vector_right_latched(number_of_samples * bits_per_sample - 1 downto (number_of_samples - 1) * bits_per_sample));
				samples_remaining := samples_remaining - 1;
				trigger_delay <= not trigger_delay;
			else
				if(samples_remaining > 1) then
					samples_remaining := samples_remaining - 1;
				else 
					samples_remaining := number_of_samples;
				end if;
				vector_left_int <= vector_left_int((number_of_samples - 1) * bits_per_sample - 1 downto 0) & (bits_per_sample - 1 downto 0 => '0');
				vector_right_int <= vector_right_int((number_of_samples - 1) * bits_per_sample - 1 downto 0) & (bits_per_sample - 1 downto 0 => '0');
				left_channel_sample_to_dac <= signed(vector_left_int(number_of_samples * bits_per_sample - 1 downto (number_of_samples - 1) * bits_per_sample));
				right_channel_sample_to_dac <= signed(vector_right_int(number_of_samples * bits_per_sample - 1 downto (number_of_samples - 1) * bits_per_sample));
				trigger_delay <= not trigger_delay;
			end if;
		end if;
	end process;

	process (reset_n, bclk, trigger_delay)
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
				sample_available_to_dac <= '1';
				state := 2;
			else
				sample_available_to_dac <= '0';
				state := 0;
			end if;
		end if;
	end process;

end fft_output_serializer_impl;