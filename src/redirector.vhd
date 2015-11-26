library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity redirector is
	generic (
		number_of_samples:          integer := 16; 
		bits_per_sample:            integer := 24);
	port (	
		reset_n:                       in    std_logic;
		
		bclk:                          in    std_logic;

		left_channel_sample_from_adc:  in   signed(bits_per_sample - 1 downto 0) := (others => '0');
		right_channel_sample_from_adc: in   signed(bits_per_sample - 1 downto 0) := (others => '0');
		sample_available_from_adc:     in   std_logic                            := '0';
		
		left_channel_sample_to_dac:    out  signed(bits_per_sample - 1 downto 0);
		right_channel_sample_to_dac:   out  signed(bits_per_sample - 1 downto 0);
		sample_available_to_dac:       out  std_logic);
end redirector;

architecture redirector_impl of redirector is
	type fsm is (waiting_for_sample, redirecting1, redirecting2);
	signal state: fsm;

begin	
	process (reset_n, bclk) 
		variable counter: integer := 0;
	begin
		if(reset_n = '0') then 
			left_channel_sample_to_dac <= (others => '0');
			right_channel_sample_to_dac <= (others => '0');
			sample_available_to_dac <= '0';
			counter := 0;
		elsif(rising_edge(bclk)) then
			case state is
				when waiting_for_sample =>
					if (sample_available_from_adc = '1') then
						left_channel_sample_to_dac <= left_channel_sample_from_adc;
						right_channel_sample_to_dac <= right_channel_sample_from_adc;
						counter := bits_per_sample / 4;
						state <= redirecting1;
					end if;
				when redirecting1 =>
					if (counter > 0) then
						sample_available_to_dac <= '1';
						counter := counter - 1;
					else 
						state <= redirecting2;
					end if;
				when redirecting2 =>
					sample_available_to_dac <= '0';
					if (sample_available_from_adc = '0') then
						state <= waiting_for_sample;
					end if;
			end case;
		end if;
	end process;
end redirector_impl;