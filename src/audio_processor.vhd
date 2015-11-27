library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.fft_utils.shuffle;

entity audio_processor is
	generic (
		fft_size_exp:                       integer := 3;
		bits_per_sample:                    integer := 24);
	port (	
		reset_n:                       in   std_logic;
		bclk:                          in   std_logic;

		left_channel_sample_from_adc:  in   signed(bits_per_sample - 1 downto 0) := (others => '0');
		right_channel_sample_from_adc: in   signed(bits_per_sample - 1 downto 0) := (others => '0');
		sample_available_from_adc:     in   std_logic                            := '0';
		
		left_channel_sample_to_dac:    out  signed(bits_per_sample - 1 downto 0);
		right_channel_sample_to_dac:   out  signed(bits_per_sample - 1 downto 0);
		sample_available_to_dac:       out  std_logic);
end audio_processor;

architecture audio_processor_impl of audio_processor is
	constant fft_size:                    integer := 2**fft_size_exp;

	signal new_vector_signal:             std_logic;

	signal pre_fft_left_re_natural:       std_logic_vector(fft_size * bits_per_sample - 1 downto 0);
	signal pre_fft_right_re_natural:      std_logic_vector(fft_size * bits_per_sample - 1 downto 0);
	
	signal post_fft_left_re_shuffled:     std_logic_vector(fft_size * (bits_per_sample + fft_size_exp) - 1 downto 0);
	signal post_fft_left_im_shuffled:     std_logic_vector(fft_size * (bits_per_sample + fft_size_exp) - 1 downto 0);
	signal post_fft_right_re_shuffled:    std_logic_vector(fft_size * (bits_per_sample + fft_size_exp) - 1 downto 0);
	signal post_fft_right_im_shuffled:    std_logic_vector(fft_size * (bits_per_sample + fft_size_exp) - 1 downto 0);

	signal post_fft_left_re_natural:      std_logic_vector(fft_size * (bits_per_sample + fft_size_exp) - 1 downto 0);
	signal post_fft_left_im_natural:      std_logic_vector(fft_size * (bits_per_sample + fft_size_exp) - 1 downto 0);
	signal post_fft_right_re_natural:     std_logic_vector(fft_size * (bits_per_sample + fft_size_exp) - 1 downto 0);
	signal post_fft_right_im_natural:     std_logic_vector(fft_size * (bits_per_sample + fft_size_exp) - 1 downto 0);

	signal post_ifft_left_re_shuffled:    std_logic_vector(fft_size * bits_per_sample - 1 downto 0);
	signal post_ifft_right_re_shuffled:   std_logic_vector(fft_size * bits_per_sample - 1 downto 0);

	signal post_ifft_left_re_natural:     std_logic_vector(fft_size * bits_per_sample - 1 downto 0);
	signal post_ifft_right_re_natural:    std_logic_vector(fft_size * bits_per_sample - 1 downto 0);

begin	

	post_fft_left_re_natural   <= shuffle(post_fft_left_re_shuffled, fft_size_exp, bits_per_sample + fft_size_exp);
	post_fft_left_im_natural   <= shuffle(post_fft_left_im_shuffled, fft_size_exp, bits_per_sample + fft_size_exp);
	post_fft_right_re_natural  <= shuffle(post_fft_right_re_shuffled, fft_size_exp, bits_per_sample + fft_size_exp);
	post_fft_right_im_natural  <= shuffle(post_fft_right_im_shuffled, fft_size_exp, bits_per_sample + fft_size_exp);
	
	post_ifft_left_re_natural  <= shuffle(post_ifft_left_re_shuffled, fft_size_exp, bits_per_sample);
	post_ifft_right_re_natural <= shuffle(post_ifft_right_re_shuffled, fft_size_exp, bits_per_sample);

	FFT_INPUT_FORMER1: entity work.fft_input_former
	generic map (
		number_of_samples => fft_size,
		bits_per_sample => bits_per_sample)
	port map (
		reset_n => reset_n,
		bclk => bclk,
		
		sample_available_from_adc => sample_available_from_adc,
		left_channel_sample_from_adc => left_channel_sample_from_adc,
		right_channel_sample_from_adc => right_channel_sample_from_adc,
		
		vector_left => pre_fft_left_re_natural,
		vector_right => pre_fft_right_re_natural,
		new_vector => new_vector_signal);

	FFT_OUTPUT_FORMER1: entity work.fft_output_former
	generic map (
		number_of_samples => fft_size,
		bits_per_sample => bits_per_sample)
	port map (
		reset_n => reset_n,
		bclk => bclk,
		
		get_next_sample => not sample_available_from_adc,
		left_channel_sample_to_dac => left_channel_sample_to_dac,
		right_channel_sample_to_dac => right_channel_sample_to_dac,
		sample_available_to_dac => sample_available_to_dac,

		vector_left => post_ifft_left_re_natural,
		vector_right => post_ifft_right_re_natural,
		new_vector => new_vector_signal);

	FFT_LEFT: entity work.fft_dif
	generic map (
		fft_size_exp => fft_size_exp,
		bits_per_sample => bits_per_sample)
	port map (
		input_re => pre_fft_left_re_natural,
		input_im => (others => '0'),
		
		output_re => post_fft_left_re_shuffled,
		output_im => post_fft_left_im_shuffled);

	FFT_RIGHT: entity work.fft_dif
	generic map (
		fft_size_exp => fft_size_exp,
		bits_per_sample => bits_per_sample)
	port map (
		input_re => pre_fft_right_re_natural,
		input_im => (others => '0'),
		
		output_re => post_fft_right_re_shuffled,
		output_im => post_fft_right_im_shuffled);

	IFFT_LEFT: entity work.ifft_dit
	generic map (
		fft_size_exp => fft_size_exp,
		bits_per_sample => bits_per_sample)
	port map (
		input_re => post_fft_left_re_natural,
		input_im => post_fft_left_im_natural,
		
		--output_im
		output_re => post_ifft_left_re_shuffled);
	
	IFFT_RIGHT: entity work.ifft_dit
	generic map (
		fft_size_exp => fft_size_exp,
		bits_per_sample => bits_per_sample)
	port map (
		input_re => post_fft_right_re_natural,
		input_im => post_fft_right_im_natural,
		
		--output_im
		output_re => post_ifft_right_re_shuffled);

end audio_processor_impl;