library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
	generic (
		number_of_samples:            integer := 16;
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

		AUD_BCLK:               in    std_logic;    --Audio CODEC Bit-Stream Clock      --inout$#@$#@$#@$@#
		AUD_ADCLRCK:            in    std_logic;    --Audio CODEC ADC LR Clock          --inout$#@$#@$#@$@#
		iAUD_ADCDAT:            in    std_logic;    --Audio CODEC ADC Data               
		AUD_DACLRCK:            in    std_logic;    --Audio CODEC DAC LR Clock          --inout$#@$#@$#@$@#
		oAUD_DACDAT:            out   std_logic;    --Audio CODEC DAC DATA
		oAUD_XCK:               out   std_logic;    --Audio CODEC Chip Clock
		  
		I2C_SDAT:               out   std_logic;    --I2C Data                          --inout$#@$#@$#@$@#
		oI2C_SCLK:              out   std_logic;    --I2C Clock

		GPIO_0:                 out   std_logic_vector(31 downto 0) := (others => '0');
		GPIO_1:                 out   std_logic_vector(31 downto 0) := (others => '0'));
end top;

architecture top_impl of top is
	signal reset_n_signal:                        std_logic;
	signal i2c_sclk_signal:                       std_logic;
	signal dacdatout:                             std_logic;
	signal start_signal:                          std_logic;

	signal row_signal:                            integer;
	signal column_signal:                         integer;
	signal disp_enabled_signal:                   std_logic;
	
	signal left_channel_sample_from_adc_signal:   signed(bits_per_sample - 1 downto 0);
	signal right_channel_sample_from_adc_signal:  signed(bits_per_sample - 1 downto 0);
	signal sample_available_from_adc_signal:      std_logic;
	
	signal left_channel_sample_to_dac_signal:     signed(bits_per_sample - 1 downto 0);
	signal right_channel_sample_to_dac_signal:    signed(bits_per_sample - 1 downto 0); 
	signal sample_available_to_dac_signal:        std_logic; 
	signal transmission_to_dac_ongoing_signal:    std_logic;

	signal vector_left_signal:                    std_logic_vector(number_of_samples * bits_per_sample - 1 downto 0);
	signal vector_right_signal:                   std_logic_vector(number_of_samples * bits_per_sample - 1 downto 0);
	signal vector_available_signal:               std_logic;
	signal change_image_signal:                   std_logic;


signal record_signal: std_logic := '0';
----test signals
--signal dbg_bclk_signal: std_logic := '0';
--signal dbg_adclrc_signal: std_logic := '0';
--signal dbg_adcdat_signal: std_logic := '0';
--signal dbg_daclrc_signal: std_logic := '0';
--signal dbg_dacdat_signal: std_logic := '0';
--signal dbg_iclk_signal: std_logic := '0';
--signal dbg_1khzclk_signal: std_logic := '0';

--signal clk_1kHz: std_logic := '0';
--signal test: std_logic := '0';
--signal programming_done_signal: std_logic := '0';

begin
	oI2C_SCLK <= i2c_sclk_signal;
	oAUD_DACDAT <= dacdatout;
	reset_n_signal <= iSW(17);
	start_signal <= iSW(0);
	record_signal <= iSW(1);
	oLEDR(17) <= reset_n_signal;
	oLEDR(0) <= start_signal;
	oLEDR(1) <= record_signal;


----test processes
--oLEDR(2) <= dacdatout;

--oLEDG(8) <= dbg_bclk_signal;
--oLEDG(3) <= dbg_bclk_signal;

--oLEDG(7) <= dbg_adclrc_signal;
--oLEDG(6) <= dbg_adcdat_signal;
--oLEDG(5) <= dbg_daclrc_signal;
--oLEDG(4) <= dbg_dacdat_signal;
--oLEDG(1) <= dbg_1khzclk_signal;
--oLEDG(0) <= dbg_iclk_signal;

--GPIO_0(0) <= '0';
--GPIO_0(3) <= programming_done_signal;
--GPIO_0(7) <= record_signal;

--GPIO_1(0) <= AUD_BCLK;
--GPIO_1(3) <= AUD_ADCLRCK;
--GPIO_1(7) <= iAUD_ADCDAT;
--GPIO_1(9) <= AUD_DACLRCK;
--GPIO_1(13) <= dacdatout;
--GPIO_1(15) <= test;

----1khz clock
--process (iCLK_50)
--	constant iclk_counter_max: integer := 25000;
--	variable iclk_counter: integer := 0;
--begin
--	if(rising_edge(iCLK_50)) then
--		if(iclk_counter < iclk_counter_max) then
--			iclk_counter := iclk_counter + 1;
--		else 
--			iclk_counter := 0;
--			clk_1kHz <= not clk_1kHz;
--		end if;
--	end if;
--end process;

--process (AUD_BCLK)
--	constant bclk_counter_max: integer := 3000000;
--	variable bclk_counter: integer := 0;
--begin
--	if(rising_edge(AUD_BCLK)) then
--		if(bclk_counter < bclk_counter_max) then
--			bclk_counter := bclk_counter + 1;
--		else 
--			bclk_counter := 0;
--			dbg_bclk_signal <= not dbg_bclk_signal;
--		end if;
--	end if;
--end process;

--process (AUD_ADCLRCK)
--	constant adclrc_counter_max: integer := 48000;
--	variable adclrc_counter: integer := 0;
--begin
--	if(rising_edge(AUD_ADCLRCK)) then
--		if(adclrc_counter < adclrc_counter_max) then
--			adclrc_counter := adclrc_counter + 1;
--		else 
--			adclrc_counter := 0;
--			dbg_adclrc_signal <= not dbg_adclrc_signal;
--		end if;
--	end if;
--end process;

--process (iAUD_ADCDAT)
--	constant adcdat_counter_max: integer := 768000;
--	variable adcdat_counter: integer := 0;
--begin
--	if(rising_edge(iAUD_ADCDAT)) then
--		if(adcdat_counter < adcdat_counter_max) then
--			adcdat_counter := adcdat_counter + 1;
--		else 
--			adcdat_counter := 0;
--			dbg_adcdat_signal <= not dbg_adcdat_signal;
--		end if;
--	end if;
--end process;

--process (AUD_DACLRCK)
--	constant daclrc_counter_max: integer := 48000;
--	variable daclrc_counter: integer := 0;
--begin
--	if(rising_edge(AUD_DACLRCK)) then
--		if(daclrc_counter < daclrc_counter_max) then
--			daclrc_counter := daclrc_counter + 1;
--		else 
--			daclrc_counter := 0;
--			dbg_daclrc_signal <= not dbg_daclrc_signal;
--		end if;
--	end if;
--end process;

--process (dacdatout)
--	constant dacdat_counter_max: integer := 768000;
--	variable dacdat_counter: integer := 0;
--begin
--	if(rising_edge(dacdatout)) then
--		if(dacdat_counter < dacdat_counter_max) then
--			dacdat_counter := dacdat_counter + 1;
--		else 
--			dacdat_counter := 0;
--			dbg_dacdat_signal <= not dbg_dacdat_signal;
--		end if;
--	end if;
--end process;

--process (iCLK_50)
--	constant iclk_counter_max: integer := 50000000;
--	variable iclk_counter: integer := 0;
--begin
--	if(rising_edge(iCLK_50)) then
--		if(iclk_counter < iclk_counter_max) then
--			iclk_counter := iclk_counter + 1;
--		else 
--			iclk_counter := 0;
--			dbg_iclk_signal <= not dbg_iclk_signal;
--		end if;
--	end if;
--end process;

--process (clk_1kHz)
--	constant clk1khz_counter_max: integer := 1000;
--	variable clk1khz_counter: integer := 0;
--begin
--	if(rising_edge(clk_1kHz)) then
--		if(clk1khz_counter < clk1khz_counter_max) then
--			clk1khz_counter := clk1khz_counter + 1;
--		else 
--			clk1khz_counter := 0;
--			dbg_1khzclk_signal <= not dbg_1khzclk_signal;
--		end if;
--	end if;
--end process;




	
	--VGA_CONTROLLER1: entity work.vga_controller 
	--port map (
		--clk_50MHz =>    iCLK_50,
		--reset_n =>      reset_n_signal,
		--disp_enabled => disp_enabled_signal,
		--row =>          row_signal,
		--column =>       column_signal,
		--sync_n =>       oVGA_SYNC_N,
		--blank_n =>      oVGA_BLANK_N,
		--h_sync =>       oVGA_HS,
		--v_sync =>       oVGA_VS,
		--vga_clk =>      oVGA_CLOCK);
--
	--VGA_IMAGE_GENERATOR1: entity work.vga_image_generator 
	--generic map (
		--number_of_samples =>           number_of_samples,
		--bits_per_sample =>             bits_per_sample)
	--port map (
		--reset_n =>                     reset_n_signal,
		--disp_enabled =>                disp_enabled_signal,
		--
		--row =>                         row_signal,
		--column =>                      column_signal,
		--
		--input_samples =>               vector_left_signal,
		--output_re =>                   (others => '0'),
		--output_im =>                   (others => '0'),
--
		--input_samples_available =>     vector_available_signal,
		--output_re_samples_available => '0',
		--output_im_samples_available => '0',
		--
		--change_image =>                change_image_signal,
--
		--red =>                         oVGA_R,
		--green =>                       oVGA_G,
		--blue =>                        oVGA_B);
	REDIRECTOR: entity work.redirector
	generic map (
		number_of_samples =>             number_of_samples,
		bits_per_sample =>               bits_per_sample)
	port map (
		reset_n =>                       reset_n_signal,
		
		bclk => AUD_BCLK,
		
		left_channel_sample_from_adc =>  left_channel_sample_from_adc_signal,
		right_channel_sample_from_adc => right_channel_sample_from_adc_signal,
		sample_available_from_adc =>     sample_available_from_adc_signal,
		
		left_channel_sample_to_dac =>    left_channel_sample_to_dac_signal,
		right_channel_sample_to_dac =>   right_channel_sample_to_dac_signal,
		sample_available_to_dac =>       sample_available_to_dac_signal);

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
		transmission_to_dac_ongoing =>   transmission_to_dac_ongoing_signal,

		mclk_18MHz =>                    oAUD_XCK,
		
		bclk =>                          AUD_BCLK,
		adclrc =>                        AUD_ADCLRCK,
		adcdat =>                        iAUD_ADCDAT,
		daclrc =>                        AUD_DACLRCK,
		dacdat =>                        dacdatout,

		i2c_sdat =>                      I2C_SDAT,
		i2c_sclk =>                      i2c_sclk_signal);

	FFT_INPUT_VECTOR_FORMER1: entity work.fft_input_former 
	generic map (
		number_of_samples =>             number_of_samples,
		bits_per_sample =>               bits_per_sample)
	port map (	
		reset_n =>                       reset_n_signal,
		sample_available_from_adc =>     sample_available_from_adc_signal,
		left_channel_sample_from_adc =>  left_channel_sample_from_adc_signal,
		right_channel_sample_from_adc => right_channel_sample_from_adc_signal,
		
		vector_left =>                   vector_left_signal,
		vector_right =>                  vector_right_signal,
		new_vector =>                    vector_available_signal);
	
end top_impl;