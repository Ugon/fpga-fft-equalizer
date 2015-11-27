library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.fft_utils.all;

entity testing_fft is
	generic (
		number_of_samples:            integer := 8;
		fft_size_exp:                 integer := 3;
		bits_per_sample:              integer := 24);
	port (
		in_im0:            in    std_logic_vector(bits_per_sample - 1 downto 0);
		in_re0:            in    std_logic_vector(bits_per_sample - 1 downto 0);
		in_im1:            in    std_logic_vector(bits_per_sample - 1 downto 0);
		in_re1:            in    std_logic_vector(bits_per_sample - 1 downto 0);
		in_im2:            in    std_logic_vector(bits_per_sample - 1 downto 0);
		in_re2:            in    std_logic_vector(bits_per_sample - 1 downto 0);
		in_im3:            in    std_logic_vector(bits_per_sample - 1 downto 0);
		in_re3:            in    std_logic_vector(bits_per_sample - 1 downto 0);
		in_im4:            in    std_logic_vector(bits_per_sample - 1 downto 0);
		in_re4:            in    std_logic_vector(bits_per_sample - 1 downto 0);
		in_im5:            in    std_logic_vector(bits_per_sample - 1 downto 0);
		in_re5:            in    std_logic_vector(bits_per_sample - 1 downto 0);
		in_im6:            in    std_logic_vector(bits_per_sample - 1 downto 0);
		in_re6:            in    std_logic_vector(bits_per_sample - 1 downto 0);
		in_im7:            in    std_logic_vector(bits_per_sample - 1 downto 0);
		in_re7:            in    std_logic_vector(bits_per_sample - 1 downto 0);
		out_im0:           out   std_logic_vector(bits_per_sample - 1 downto 0);
		out_re0:           out   std_logic_vector(bits_per_sample - 1 downto 0);
		out_im1:           out   std_logic_vector(bits_per_sample - 1 downto 0);
		out_re1:           out   std_logic_vector(bits_per_sample - 1 downto 0);
		out_im2:           out   std_logic_vector(bits_per_sample - 1 downto 0);
		out_re2:           out   std_logic_vector(bits_per_sample - 1 downto 0);
		out_im3:           out   std_logic_vector(bits_per_sample - 1 downto 0);
		out_re3:           out   std_logic_vector(bits_per_sample - 1 downto 0);
		out_im4:           out   std_logic_vector(bits_per_sample - 1 downto 0);
		out_re4:           out   std_logic_vector(bits_per_sample - 1 downto 0);
		out_im5:           out   std_logic_vector(bits_per_sample - 1 downto 0);
		out_re5:           out   std_logic_vector(bits_per_sample - 1 downto 0);
		out_im6:           out   std_logic_vector(bits_per_sample - 1 downto 0);
		out_re6:           out   std_logic_vector(bits_per_sample - 1 downto 0);
		out_im7:           out   std_logic_vector(bits_per_sample - 1 downto 0);
		out_re7:           out   std_logic_vector(bits_per_sample - 1 downto 0));
end testing_fft;

architecture testing_fft_impl of testing_fft is

	signal in_re:                    std_logic_vector(number_of_samples * bits_per_sample - 1 downto 0);
	signal in_im:                    std_logic_vector(number_of_samples * bits_per_sample - 1 downto 0);

	signal mid_re_shuffled:          std_logic_vector(number_of_samples * (bits_per_sample + fft_size_exp) - 1 downto 0);
	signal mid_im_shuffled:          std_logic_vector(number_of_samples * (bits_per_sample + fft_size_exp) - 1 downto 0);

	signal mid_re_natural:           std_logic_vector(number_of_samples * (bits_per_sample + fft_size_exp) - 1 downto 0);
	signal mid_im_natural:           std_logic_vector(number_of_samples * (bits_per_sample + fft_size_exp) - 1 downto 0);

	signal out_re_shuffled:          std_logic_vector(number_of_samples * bits_per_sample - 1 downto 0);
	signal out_im_shuffled:          std_logic_vector(number_of_samples * bits_per_sample - 1 downto 0);

	signal out_re:                   std_logic_vector(number_of_samples * bits_per_sample - 1 downto 0);
	signal out_im:                   std_logic_vector(number_of_samples * bits_per_sample - 1 downto 0);
	
begin

	in_re <=  in_re7  & in_re6  & in_re5  & in_re4  & in_re3  & in_re2  & in_re1  & in_re0;
	in_im <=  in_im7  & in_im6  & in_im5  & in_im4  & in_im3  & in_im2  & in_im1  & in_im0;
	
	mid_re_natural <= shuffle(mid_re_shuffled, fft_size_exp, bits_per_sample + fft_size_exp);
	mid_im_natural <= shuffle(mid_im_shuffled, fft_size_exp, bits_per_sample + fft_size_exp);

	out_re <= shuffle(out_re_shuffled, fft_size_exp, bits_per_sample);
	out_im <= shuffle(out_im_shuffled, fft_size_exp, bits_per_sample);

	out_re7 <= out_re(8 * bits_per_sample - 1 downto 7 * bits_per_sample);
	out_re6 <= out_re(7 * bits_per_sample - 1 downto 6 * bits_per_sample);
	out_re5 <= out_re(6 * bits_per_sample - 1 downto 5 * bits_per_sample);
	out_re4 <= out_re(5 * bits_per_sample - 1 downto 4 * bits_per_sample);
	out_re3 <= out_re(4 * bits_per_sample - 1 downto 3 * bits_per_sample);
	out_re2 <= out_re(3 * bits_per_sample - 1 downto 2 * bits_per_sample);
	out_re1 <= out_re(2 * bits_per_sample - 1 downto 1 * bits_per_sample);
	out_re0 <= out_re(1 * bits_per_sample - 1 downto 0 * bits_per_sample);

	out_im7 <= out_im(8 * bits_per_sample - 1 downto 7 * bits_per_sample);
	out_im6 <= out_im(7 * bits_per_sample - 1 downto 6 * bits_per_sample);
	out_im5 <= out_im(6 * bits_per_sample - 1 downto 5 * bits_per_sample);
	out_im4 <= out_im(5 * bits_per_sample - 1 downto 4 * bits_per_sample);
	out_im3 <= out_im(4 * bits_per_sample - 1 downto 3 * bits_per_sample);
	out_im2 <= out_im(3 * bits_per_sample - 1 downto 2 * bits_per_sample);
	out_im1 <= out_im(2 * bits_per_sample - 1 downto 1 * bits_per_sample);
	out_im0 <= out_im(1 * bits_per_sample - 1 downto 0 * bits_per_sample);

	fft: entity work.fft_dif
	generic map (
		fft_size_exp => fft_size_exp,
		bits_per_sample => bits_per_sample)
	port map (
		input_re => in_re,
		input_im => in_im,
		
		output_re => mid_re_shuffled,
		output_im => mid_im_shuffled);
	
	ifft: entity work.ifft_dit
	generic map (
		fft_size_exp => fft_size_exp,
		bits_per_sample => bits_per_sample)
	port map (
		input_re => mid_re_natural,
		input_im => mid_im_natural,
		
		output_re => out_re_shuffled,
		output_im => out_im_shuffled);

end testing_fft_impl;