library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity testing_top is
	generic (
		number_of_samples:            integer := 8;
		bits_per_sample:              integer := 24);
	port (
		AUD_ADCLRCK:            in    std_logic;    --Audio CODEC ADC LR Clock
		iAUD_ADCDAT:            in    std_logic;    --Audio CODEC ADC Data
		AUD_DACLRCK:            in    std_logic;    --Audio CODEC DAC LR Clock
		oAUD_DACDAT:            out   std_logic;    --Audio CODEC DAC DATA
		AUD_BCLK:               in    std_logic     --Audio CODEC Bit-Stream Clock      --inout$#@$#@$#@$@#
		);
end testing_top;

architecture testing_top_impl of testing_top is

	signal dacdatout:                             std_logic;
	signal reset_n_signal:                        std_logic;

	signal left_channel_sample_from_adc_signal:   signed(bits_per_sample - 1 downto 0);
	signal right_channel_sample_from_adc_signal:  signed(bits_per_sample - 1 downto 0);
	signal sample_available_from_adc_signal:      std_logic;

	signal left_channel_sample_to_dac_signal:     signed(bits_per_sample - 1 downto 0);
	signal right_channel_sample_to_dac_signal:    signed(bits_per_sample - 1 downto 0); 
	signal sample_available_to_dac_signal:        std_logic; 
	signal transmission_to_dac_ongoing_signal:    std_logic;

begin
	reset_n_signal <= '1';
	oAUD_DACDAT <= dacdatout;
	
	REDIRECTOR: entity work.redirector
	generic map (
		number_of_samples =>           number_of_samples,
		bits_per_sample =>             bits_per_sample)
	port map (
		reset_n =>                     reset_n_signal,
		
		bclk => AUD_BCLK,
				
		left_channel_sample_from_adc => left_channel_sample_from_adc_signal,
		right_channel_sample_from_adc => right_channel_sample_from_adc_signal,
		sample_available_from_adc => sample_available_from_adc_signal,
		
		left_channel_sample_to_dac => left_channel_sample_to_dac_signal,
		right_channel_sample_to_dac => right_channel_sample_to_dac_signal,
		sample_available_to_dac => sample_available_to_dac_signal);

	DSP_SLAVE_READER: entity work.dsp_slave_reader
	generic map (
		number_of_samples =>           number_of_samples,
		bits_per_sample =>             bits_per_sample)
	port map(
		reset_n => reset_n_signal,
		
		left_channel_sample_from_adc => left_channel_sample_from_adc_signal,
		right_channel_sample_from_adc => right_channel_sample_from_adc_signal,
		sample_available_from_adc => sample_available_from_adc_signal,
		
		bclk => AUD_BCLK,
		adclrc => AUD_ADCLRCK,
		adcdat => iAUD_ADCDAT);

	DSP_SLAVE_WRITER: entity work.dsp_slave_writer
	generic map (
		number_of_samples =>           number_of_samples,
		bits_per_sample =>             bits_per_sample)
	port map (
		reset_n => reset_n_signal,
		
		left_channel_sample_to_dac => left_channel_sample_to_dac_signal,
		right_channel_sample_to_dac => right_channel_sample_to_dac_signal,
		sample_available_to_dac => sample_available_to_dac_signal,
		transmission_to_dac_ongoing => transmission_to_dac_ongoing_signal,
		
		bclk => AUD_BCLK,
		daclrc => AUD_DACLRCK,
		dacdat => dacdatout);
	
end testing_top_impl;