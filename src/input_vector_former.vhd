library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity input_vector_former is
	generic (
		number_of_samples:          integer := 16; --for testing 3
		bits_per_sample:            integer := 24); --for testing 2
	port (	
		reset_n:              in    std_logic;
		sample_available:     in    std_logic;
		left_channel_sample:  in    signed(bits_per_sample - 1 downto 0);
		right_channel_sample: in    signed(bits_per_sample - 1 downto 0);
		
		vector_left:          out   std_logic_vector(number_of_samples * bits_per_sample - 1 downto 0) := (others => '0');
		vector_right:         out   std_logic_vector(number_of_samples * bits_per_sample - 1 downto 0) := (others => '0');
		vector_available:     out   std_logic := '0');
end input_vector_former;

architecture input_vector_former_impl of input_vector_former is

	signal samples_remaining: integer                                                            := number_of_samples;
	signal vector_left_int:   std_logic_vector(number_of_samples * bits_per_sample - 1 downto 0) := (others => '0');
	signal vector_right_int:  std_logic_vector(number_of_samples * bits_per_sample - 1 downto 0) := (others => '0');
	signal first_vector_done: boolean                                                            := false;

begin
	process (reset_n, sample_available) 
	begin
		if(reset_n = '0') then
			vector_left <= (others => '0');
			vector_right <= (others => '0');
			vector_left_int <= (others => '0');
			vector_right_int <= (others => '0');
			vector_available <= '0';
			samples_remaining <= number_of_samples;
		elsif (rising_edge(sample_available)) then
			if(samples_remaining <= 2) then
				vector_available <= '0';
			end if;

			if(samples_remaining = number_of_samples and first_vector_done) then
				vector_available <= '1';
			end if;
			
			if(samples_remaining > 1) then
				samples_remaining <= samples_remaining - 1;
				vector_left_int <= vector_left_int((number_of_samples - 1) * bits_per_sample - 1 downto 0) & std_logic_vector(left_channel_sample);
				vector_right_int <= vector_right_int((number_of_samples - 1) * bits_per_sample - 1 downto 0) & std_logic_vector(right_channel_sample);
			else 
				samples_remaining <= number_of_samples;
				vector_left <= vector_left_int((number_of_samples - 1) * bits_per_sample - 1 downto 0) & std_logic_vector(left_channel_sample);
				vector_right <= vector_right_int((number_of_samples - 1) * bits_per_sample - 1 downto 0) & std_logic_vector(right_channel_sample);
				vector_left_int <= (others => '0');
				vector_right_int <= (others => '0');
				vector_left_int(bits_per_sample - 1 downto 0) <= std_logic_vector(left_channel_sample);
				vector_right_int(bits_per_sample - 1 downto 0) <= std_logic_vector(right_channel_sample);
				first_vector_done <= true;
			end if;
		end if;
	end process;
end input_vector_former_impl;