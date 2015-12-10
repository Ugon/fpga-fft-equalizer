library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.fft_utils.bit_reverse;

entity top is
	generic (
		fft_size_exp:                 integer := 4;
		bits_per_sample:              integer := 24);
	port (
		iCLK_28:                in    std_logic;    --28.63636MHz
		iCLK_50:                in    std_logic;    --50MHz
		iCLK_50_2:              in    std_logic;    --50MHz

		oLEDG:                  out   std_logic_vector(8  downto 0);
		oLEDR:                  out   std_logic_vector(17 downto 0);

		iKEY:                   in    std_logic_vector(3  downto 0);
		iSW:                    in    std_logic_vector(17 downto 0);

		oVGA_R, oVGA_G, oVGA_B: out   std_logic_vector(9  downto 0);
		oVGA_CLOCK:             out   std_logic;
		oVGA_VS:                out   std_logic;
		oVGA_HS:                out   std_logic;
		oVGA_BLANK_N:           out   std_logic;
		oVGA_SYNC_N:            out   std_logic;

		AUD_BCLK:               in    std_logic;    --Audio CODEC Bit-Stream Clock
		AUD_ADCLRCK:            in    std_logic;    --Audio CODEC ADC LR Clock
		iAUD_ADCDAT:            in    std_logic;    --Audio CODEC ADC Data               
		AUD_DACLRCK:            in    std_logic;    --Audio CODEC DAC LR Clock
		oAUD_DACDAT:            out   std_logic;    --Audio CODEC DAC DATA
		oAUD_XCK:               out   std_logic;    --Audio CODEC Chip Clock
		  
		I2C_SDAT:               out   std_logic;    --I2C Data
		oI2C_SCLK:              out   std_logic;    --I2C Clock

		GPIO_0:                 out   std_logic_vector(31 downto 0) := (others => '0');
		GPIO_1:                 out   std_logic_vector(31 downto 0) := (others => '0'));
end top;

architecture top_impl of top is
	constant number_of_samples:                     integer := 2**fft_size_exp;
	
	signal reset_n_signal:                          std_logic;
	signal start_signal:                            std_logic;

	signal row_signal:                              integer;
	signal column_signal:                           integer;
	signal disp_enabled_signal:                     std_logic;
	signal change_image_signal:                     std_logic;
	
	signal left_channel_sample_from_adc_signal:     signed(bits_per_sample - 1 downto 0);
	signal right_channel_sample_from_adc_signal:    signed(bits_per_sample - 1 downto 0);
	signal sample_available_from_adc_signal:        std_logic;
	
	signal left_channel_sample_to_dac_signal:       signed(bits_per_sample - 1 downto 0);
	signal right_channel_sample_to_dac_signal:      signed(bits_per_sample - 1 downto 0); 
	signal sample_available_to_dac_signal:          std_logic; 

	signal equalized_frequency_sample_left_signal:  std_logic_vector(2**fft_size_exp * bits_per_sample - 1 downto 0);
	signal equalized_frequency_sample_right_signal: std_logic_vector(2**fft_size_exp * bits_per_sample - 1 downto 0);

	signal mask_signal:                             std_logic_vector(6 downto 0);
	signal bin_0_signal:                            std_logic;

	signal scaling_factor_signal:                   unsigned(7 downto 0);
	signal mask_out:                                std_logic_vector(15 downto 0);

	signal start_delay:                             std_logic;

begin

	reset_n_signal <= iKEY(0);
	start_signal <= start_delay;
	oLEDG(0) <= reset_n_signal;
	oLEDG(7) <= start_signal;
	oLEDR(17 downto 10) <= iSW(17 downto 10);
	oLEDR(9) <= '0';
	oLEDR(8) <= '0';
	oLEDR(7 downto 0) <= iSW(7 downto 0);

	scaling_factor_signal <= unsigned(iSW(7 downto 0));
	bin_0_signal <= iSW(17);
	mask_signal <= bit_reverse(iSW(16 downto 10));

	process(iCLK_50)
		variable cnt: integer := 10;
		variable lim: integer := 50000000;
	begin
		if rising_edge(iCLK_50) then
			if(cnt < lim) then
				cnt := cnt + 1;
				start_delay <= '0';
			else 
				start_delay <= '1';
			end if;
		end if;
	end process;

	AUDIO_PROCESSOR: entity work.audio_processor
	generic map (
		fft_size_exp =>                     fft_size_exp,
		bits_per_sample =>                  bits_per_sample)
	port map (
		reset_n =>                          reset_n_signal,
		bclk =>                             AUD_BCLK,
		
		left_channel_sample_from_adc =>     left_channel_sample_from_adc_signal,
		right_channel_sample_from_adc =>    right_channel_sample_from_adc_signal,
		sample_available_from_adc =>        sample_available_from_adc_signal,
		
		left_channel_sample_to_dac =>       left_channel_sample_to_dac_signal,
		right_channel_sample_to_dac =>      right_channel_sample_to_dac_signal,
		sample_available_to_dac =>          sample_available_to_dac_signal,

		equalized_frequency_sample_left =>  equalized_frequency_sample_left_signal,
		equalized_frequency_sample_right => equalized_frequency_sample_right_signal,

		bin_0 =>                            bin_0_signal,
		mask =>                             mask_signal);

	MW8731_CONTROLLER1: entity work.mw8731_controller
	generic map (
		number_of_samples =>             number_of_samples,
		bits_per_sample =>               bits_per_sample)
	port map (
		clk_50MHz =>                     iCLK_50_2,
		reset_n =>                       reset_n_signal,
		
		start_operation =>               start_signal,

		left_channel_sample_from_adc =>  left_channel_sample_from_adc_signal,
		right_channel_sample_from_adc => right_channel_sample_from_adc_signal,
		sample_available_from_adc =>     sample_available_from_adc_signal,

		left_channel_sample_to_dac =>    left_channel_sample_to_dac_signal,
		right_channel_sample_to_dac =>   right_channel_sample_to_dac_signal,
		sample_available_to_dac =>       sample_available_to_dac_signal,

		mclk_18MHz =>                    oAUD_XCK,
		
		bclk =>                          AUD_BCLK,
		adclrc =>                        AUD_ADCLRCK,
		adcdat =>                        iAUD_ADCDAT,
		daclrc =>                        AUD_DACLRCK,
		dacdat =>                        oAUD_DACDAT,

		i2c_sdat =>                      I2C_SDAT,
		i2c_sclk =>                      oI2C_SCLK);

	VGA_CONTROLLER1: entity work.vga_controller 
	port map (
		clk_50MHz =>    iCLK_50,
		reset_n =>      reset_n_signal,
		disp_enabled => disp_enabled_signal,
		sync_n =>       oVGA_SYNC_N,
		blank_n =>      oVGA_BLANK_N,
		h_sync =>       oVGA_HS,
		v_sync =>       oVGA_VS,
		vga_clk =>      oVGA_CLOCK,

		row =>          row_signal,
		column =>       column_signal,
		change_image => change_image_signal);

	VGA_IMAGE_GENERATOR1: entity work.vga_image_generator 
	generic map (
		number_of_samples =>                number_of_samples,
		bits_per_sample =>                  bits_per_sample)
	port map (
		reset_n =>                          reset_n_signal,
		clk_50MHz =>                        iCLK_50,

		disp_enabled =>                     disp_enabled_signal,
		change_image =>                     change_image_signal,
		
		row =>                              row_signal,
		column =>                           column_signal,
     
		equalized_frequency_sample_left =>  equalized_frequency_sample_left_signal,
		equalized_frequency_sample_right => equalized_frequency_sample_right_signal,

		scaling_factor =>                   scaling_factor_signal,

		red =>                              oVGA_R,
		green =>                            oVGA_G,
		blue =>                             oVGA_B);
	
end top_impl;