library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fft_utils.all;

entity ifft_dit is
	generic(
		fft_size_exp:                 integer := 3;
		bits_per_sample:              integer := 24;
		output_natural_order:         boolean := false);
	port(
		input_re:   in   std_logic_vector(2**fft_size_exp * (bits_per_sample + fft_size_exp) - 1 downto 0);
		input_im:   in   std_logic_vector(2**fft_size_exp * (bits_per_sample + fft_size_exp) - 1 downto 0);
		
		output_re:   out std_logic_vector(2**fft_size_exp * (bits_per_sample) - 1 downto 0);
		output_im:   out std_logic_vector(2**fft_size_exp * (bits_per_sample) - 1 downto 0));
end ifft_dit;

architecture ifft_dit_impl of ifft_dit is
	constant fft_size: integer := 2**fft_size_exp;

	signal input_im_neg:           std_logic_vector(fft_size * (bits_per_sample +     fft_size_exp) - 1 downto 0);
	signal output_re_from_fft:     std_logic_vector(fft_size * (bits_per_sample + 2 * fft_size_exp) - 1 downto 0);
	signal output_im_from_fft:     std_logic_vector(fft_size * (bits_per_sample + 2 * fft_size_exp) - 1 downto 0);
	signal output_im_from_fft_neg: std_logic_vector(fft_size * (bits_per_sample + 2 * fft_size_exp) - 1 downto 0);

begin
	
	input_im_neg           <= negate_all(input_im,           fft_size, bits_per_sample + fft_size_exp);
	output_im_from_fft_neg <= negate_all(output_im_from_fft, fft_size, bits_per_sample + 2 * fft_size_exp);

	output_re <= divide_and_resize_all(output_re_from_fft,     fft_size, bits_per_sample + 2 * fft_size_exp, fft_size, bits_per_sample);
	output_im <= divide_and_resize_all(output_im_from_fft_neg, fft_size, bits_per_sample + 2 * fft_size_exp, fft_size, bits_per_sample);

	fft: entity work.fft_dif
	generic map (
		fft_size_exp => fft_size_exp,
		bits_per_sample => bits_per_sample + fft_size_exp,
		output_natural_order => output_natural_order)
	port map (
		input_re => input_re,
		input_im => input_im_neg,
		
		output_re => output_re_from_fft,
		output_im => output_im_from_fft);

end ifft_dit_impl;