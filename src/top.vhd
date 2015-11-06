library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
	generic (
		number_of_samples:           integer := 16;
		bits_per_sample:             integer := 24);
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

		AUD_ADCLRCK:            inout std_logic;    --Audio CODEC ADC LR Clock
		iAUD_ADCDAT:            in    std_logic;    --Audio CODEC ADC Data
		AUD_DACLRCK:            inout std_logic;    --Audio CODEC DAC LR Clock
		oAUD_DACDAT:            out   std_logic;    --Audio CODEC DAC DATA
		AUD_BCLK:               inout std_logic;    --Audio CODEC Bit-Stream Clock      --inout$#@$#@$#@$@#
		oAUD_XCK:               out   std_logic;    --Audio CODEC Chip Clock
		  
		I2C_SDAT:               inout std_logic;    --I2C Data
		oI2C_SCLK:              out   std_logic;    --I2C Clock

		GPIO_1:                 out   std_logic_vector(31 downto 0) := (others => '0')
		);
end top;

architecture top_impl of top is
	signal reset_n_signal:               std_logic;
	signal row_signal:                   integer;
	signal column_signal:                integer;
	signal left_channel_sample_signal:   signed(bits_per_sample - 1 downto 0);
	signal right_channel_sample_signal:  signed(bits_per_sample - 1 downto 0);
	signal sample_available_signal:      std_logic;
	--signal start_operation_signal:       std_logic;
	signal vector_left_signal:           std_logic_vector(number_of_samples * bits_per_sample - 1 downto 0);
	signal vector_right_signal:          std_logic_vector(number_of_samples * bits_per_sample - 1 downto 0);
	signal vector_available_signal:      std_logic;
	signal change_image_signal:          std_logic;

	signal disp_enabled_signal:          std_logic;

	signal i2c_sclk_signal:              std_logic;
	
	signal start_signal:                 std_logic;

	signal test_programming_done_signal: std_logic;


begin
	oI2C_SCLK <= i2c_sclk_signal;
	
	VGA_CONTROLLER1: entity work.vga_controller 
	port map (
		clk_50MHz =>    iCLK_50,
		reset_n =>      reset_n_signal,
		disp_enabled => disp_enabled_signal,
		row =>          row_signal,
		column =>       column_signal,
		sync_n =>       oVGA_SYNC_N,
		blank_n =>      oVGA_BLANK_N,
		h_sync =>       oVGA_HS,
		v_sync =>       oVGA_VS,
		vga_clk =>      oVGA_CLOCK);

	VGA_IMAGE_GENERATOR1: entity work.vga_image_generator 
	generic map (
		number_of_samples =>           number_of_samples,
		bits_per_sample =>             bits_per_sample)
	port map (
		reset_n =>                     reset_n_signal,
		disp_enabled =>                disp_enabled_signal,
		
		row =>                         row_signal,
		column =>                      column_signal,
		
		input_samples =>               vector_left_signal,
		output_re =>                   (others => '0'),
		output_im =>                   (others => '0'),

		input_samples_available =>     vector_available_signal,
		output_re_samples_available => '0',
		output_im_samples_available => '0',
		
		change_image =>                change_image_signal,

		red =>                         oVGA_R,
		green =>                       oVGA_G,
		blue =>                        oVGA_B);

	MW8731_CONTROLLER1: entity work.mw8731_controller
	port map (
		clk_50MHz =>             iCLK_50_2,
		reset_n =>               reset_n_signal,
		
		left_channel_sample =>   left_channel_sample_signal,
		right_channel_sample =>  right_channel_sample_signal,
		sample_available =>      sample_available_signal,
		start_operation =>       start_signal,

		mclk_18MHz =>            oAUD_XCK,
		
		bclk =>                  AUD_BCLK,
		adclrc =>                AUD_ADCLRCK,
		adcdat =>                iAUD_ADCDAT,

		i2c_sdat =>              I2C_SDAT,
		i2c_sclk =>              i2c_sclk_signal,
		
		test_programming_done => test_programming_done_signal);

	FFT_INPUT_VECTOR_FORMER1: entity work.input_vector_former 
	generic map (
		number_of_samples =>    number_of_samples,
		bits_per_sample =>      bits_per_sample)
	port map (	
		reset_n =>              reset_n_signal,
		sample_available =>     sample_available_signal,
		left_channel_sample =>  left_channel_sample_signal,
		right_channel_sample => right_channel_sample_signal,
		
		vector_left =>          vector_left_signal,
		vector_right =>         vector_right_signal,
		vector_available =>     vector_available_signal);

	reset_n_signal <= iKEY(3);
	oLEDR(17) <= iKEY(3);
	
	GPIO_1(0) <= AUD_ADCLRCK;
	GPIO_1(3) <= AUD_BCLK;
	GPIO_1(7) <= iAUD_ADCDAT;
	GPIO_1(15) <= '0';
	GPIO_1(9) <= I2C_SDAT;
	GPIO_1(13) <= i2c_sclk_signal;
	start_signal <= iSW(0);
	GPIO_1(31) <= start_signal;
	oLEDR(0) <= start_signal;
	
	GPIO_1(19) <= test_programming_done_signal;

end top_impl;