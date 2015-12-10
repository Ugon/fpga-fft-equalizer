library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--data should be available on 2nd bclk rising edge after rising daclrc edge (in WM8731 set lrp=1)
--48kHz sampling rate
--18,432MHz MCLK 
--BOSR = 1 (384fs)

entity dsp_slave_writer is
	generic (
		number_of_samples:                 integer := 16;
		bits_per_sample:                   integer := 24);
	port (
		reset_n:                     in    std_logic;
		
		left_channel_sample_to_dac:  in    signed(bits_per_sample - 1 downto 0);
		right_channel_sample_to_dac: in    signed(bits_per_sample - 1 downto 0);
		sample_available_to_dac:     in    std_logic;
		transmission_to_dac_ongoing: out   std_logic := '0';

		bclk:                        in    std_logic;
		daclrc:                      in    std_logic;
		dacdat:                      out   std_logic := '0');
end dsp_slave_writer;

architecture dsp_slave_writer_impl of dsp_slave_writer is
	type fsm is (waiting_for_daclrc, sending_data);
	signal state : fsm;
	
	signal both_samples_to_dac_int:             std_logic_vector(2 * bits_per_sample - 1 downto 0);
	signal both_samples_to_dac_latched:         std_logic_vector(2 * bits_per_sample - 1 downto 0);

	signal bits_remaining:                      unsigned(7 downto 0);

	signal daclrc_occured:                      std_logic := '0';
	signal daclrc_used:                         std_logic := '0';

begin	

	process(reset_n, sample_available_to_dac)
	begin
		if(reset_n = '0') then
			both_samples_to_dac_latched <= (others => '0');
		elsif rising_edge(sample_available_to_dac) then
			both_samples_to_dac_latched <= std_logic_vector(left_channel_sample_to_dac) & std_logic_vector(right_channel_sample_to_dac);
		end if;
	end process;

	process(reset_n, bclk, state)
	begin
		if (reset_n = '0') then
			both_samples_to_dac_int <= (others => '0');
			bits_remaining <= (others => '1');
			state <= waiting_for_daclrc;
			daclrc_occured <= '0';
			daclrc_used <= '0';
			transmission_to_dac_ongoing <= '0';
		elsif (state = waiting_for_daclrc and rising_edge(bclk)) then
			if (daclrc = '1') then
				daclrc_occured <= not daclrc_used;
			end if;
		elsif (falling_edge(bclk)) then 
			case state is
				when waiting_for_daclrc =>
					--TE 2 LINIJKI WCIAGNE DO IF TO NIE DZIALA
					bits_remaining <= to_unsigned(2 * bits_per_sample, bits_remaining'length);
					both_samples_to_dac_int <= both_samples_to_dac_latched(both_samples_to_dac_latched'length - 2 downto 0) & '0';
					--TE 2 LINIJKI WCIAGNE DO IF TO NIE DZIALA
					if (daclrc_used = not daclrc_occured) then
						daclrc_used <= daclrc_occured;
						dacdat <= both_samples_to_dac_latched(2 * bits_per_sample - 1); --first left channel bit

						transmission_to_dac_ongoing <= '1';
						state <= sending_data;
					end if;
				when sending_data =>
					if (bits_remaining > 0) then
						bits_remaining <= bits_remaining - 1;
						both_samples_to_dac_int <= both_samples_to_dac_int(both_samples_to_dac_latched'length - 2 downto 0) & '0';
						dacdat <= both_samples_to_dac_int(both_samples_to_dac_latched'length - 1);
						state <= sending_data;
					else
						dacdat <= '0';
						transmission_to_dac_ongoing <= '0';
						state <= waiting_for_daclrc;
					end if;
				when others => null;
			end case;
		end if;
	end process;
end dsp_slave_writer_impl;