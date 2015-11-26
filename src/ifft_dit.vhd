library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fft_twiddle_factors_16.all;
use work.fft_utils.all;


entity ifft_dit is
	generic(
		stages_done:                  integer := 1;
		size_exp:                     integer := 3; --2**size_exp = size (size = number_of_samples)
		bits_per_sample:              integer := 24);
	port(
		input_re:   in   std_logic_vector(2**size_exp * (bits_per_sample + size_exp) - 1 downto 0);
		input_im:   in   std_logic_vector(2**size_exp * (bits_per_sample + size_exp) - 1 downto 0);
		
		output_re:   out std_logic_vector(2**size_exp * (bits_per_sample) - 1 downto 0);
		output_im:   out std_logic_vector(2**size_exp * (bits_per_sample) - 1 downto 0));
end ifft_dit;

architecture ifft_dit_impl of ifft_dit is
	constant size: integer := 2**size_exp;

	signal input_im_neg:           std_logic_vector(size * (bits_per_sample +     size_exp) - 1 downto 0);
	signal output_re_from_fft:     std_logic_vector(size * (bits_per_sample + 2 * size_exp) - 1 downto 0);
	signal output_im_from_fft:     std_logic_vector(size * (bits_per_sample + 2 * size_exp) - 1 downto 0);
	signal output_im_from_fft_neg: std_logic_vector(size * (bits_per_sample + 2 * size_exp) - 1 downto 0);

begin
	
	input_im_neg           <= negate_all(input_im,           size, bits_per_sample + size_exp);
	output_im_from_fft_neg <= negate_all(output_im_from_fft, size, bits_per_sample + 2 * size_exp);

	process (output_re_from_fft, output_im_from_fft_neg)
	begin
		for i in size - 1 downto 0 loop
			output_re((i + 1) * (bits_per_sample) - 1 downto i * (bits_per_sample))
				<= std_logic_vector(resize(signed(output_re_from_fft((i + 1) * (bits_per_sample + 2 * size_exp) - 1 downto i * (bits_per_sample + 2 * size_exp))) / size, bits_per_sample));    -- divide each sample by number of original samples
			output_im((i + 1) * (bits_per_sample) - 1 downto i * (bits_per_sample))
				<= std_logic_vector(resize(signed(output_im_from_fft_neg((i + 1) * (bits_per_sample + 2 * size_exp) - 1 downto i * (bits_per_sample + 2 * size_exp))) / size, bits_per_sample));-- divide each sample by number of original samples
		end loop;
	end process;

	fft: entity work.fft_dif
	generic map (
		size_exp => size_exp,
		bits_per_sample => bits_per_sample + size_exp)
	port map (
		input_re => input_re,
		input_im => input_im_neg,
		
		output_re => output_re_from_fft,
		output_im => output_im_from_fft);

end ifft_dit_impl;