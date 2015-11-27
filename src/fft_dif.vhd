library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fft_utils.all;


entity fft_dif is
	generic(
		stages_done:                  integer := 1;
		fft_size_exp:                 integer := 3; --2**fft_size_exp = size (size = number_of_samples)
		bits_per_sample:              integer := 24);
	port(
		input_re:   in  std_logic_vector(2**fft_size_exp * bits_per_sample - 1 downto 0);
		input_im:   in  std_logic_vector(2**fft_size_exp * bits_per_sample - 1 downto 0);
		
		output_re:   out std_logic_vector(2**fft_size_exp * (bits_per_sample + fft_size_exp) - 1 downto 0);
		output_im:   out std_logic_vector(2**fft_size_exp * (bits_per_sample + fft_size_exp) - 1 downto 0));
end fft_dif;

architecture fft_dif_impl of fft_dif is
	constant size: integer := 2**fft_size_exp;

	type input_array         is array(0 to 2**fft_size_exp - 1) of signed(bits_per_sample                    - 1 downto 0);
	type summed_array        is array(0 to 2**fft_size_exp - 1) of signed(bits_per_sample                + 1 - 1 downto 0);
	type multed_array        is array(0 to 2**fft_size_exp - 1) of signed(bits_per_sample + tw_size      + 1 - 1 downto 0);
	type truncted_array      is array(0 to 2**fft_size_exp - 1) of signed(bits_per_sample                + 1 - 1 downto 0);
	
	signal stage_done_re:    std_logic_vector(size * (bits_per_sample + 1) - 1 downto 0);
	signal stage_done_im:    std_logic_vector(size * (bits_per_sample + 1) - 1 downto 0);

	signal input_re1:        std_logic_vector(size   * (bits_per_sample + 1) - 1 downto size/2 * (bits_per_sample + 1));
	signal input_im1:        std_logic_vector(size   * (bits_per_sample + 1) - 1 downto size/2 * (bits_per_sample + 1));
	signal input_re0:        std_logic_vector(size/2 * (bits_per_sample + 1) - 1 downto 0);
	signal input_im0:        std_logic_vector(size/2 * (bits_per_sample + 1) - 1 downto 0);

	signal output_re1:       std_logic_vector(size   * (bits_per_sample + fft_size_exp) - 1 downto size/2 * (bits_per_sample + fft_size_exp));
	signal output_im1:       std_logic_vector(size   * (bits_per_sample + fft_size_exp) - 1 downto size/2 * (bits_per_sample + fft_size_exp));
	signal output_re0:       std_logic_vector(size/2 * (bits_per_sample + fft_size_exp) - 1 downto 0);
	signal output_im0:       std_logic_vector(size/2 * (bits_per_sample + fft_size_exp) - 1 downto 0);

begin
	edge_case: if fft_size_exp = 0 generate
	
		output_re <= input_re;
		output_im <= input_im;
	
	end generate edge_case;

	general: if fft_size_exp > 0 generate

		process(input_re, input_im)
			variable input_array_re:    input_array;
			variable input_array_im:    input_array;
			variable summed_array_re:   summed_array;	
			variable summed_array_im:   summed_array;	
			variable multed_array_re:   summed_array;
			variable multed_array_im:   summed_array;
			variable truncted_array_re: truncted_array;
			variable truncted_array_im: truncted_array;
		begin
			for i in size - 1 downto 0 loop
				input_array_re(i) := signed(input_re(bits_per_sample * (i + 1) - 1 downto bits_per_sample * i));
				input_array_im(i) := signed(input_im(bits_per_sample * (i + 1) - 1 downto bits_per_sample * i));
			end loop;
	
			for i in size/2 - 1 downto 0 loop
				summed_array_re(i)          := resize(input_array_re(i), input_array_re(i)'length + 1) + resize(input_array_re(i + size/2), input_array_re(i + size/2)'length + 1);
				summed_array_im(i)          := resize(input_array_im(i), input_array_im(i)'length + 1) + resize(input_array_im(i + size/2), input_array_im(i + size/2)'length + 1);
				summed_array_re(i + size/2) := resize(input_array_re(i), input_array_re(i)'length + 1) - resize(input_array_re(i + size/2), input_array_re(i + size/2)'length + 1);
				summed_array_im(i + size/2) := resize(input_array_im(i), input_array_im(i)'length + 1) - resize(input_array_im(i + size/2), input_array_im(i + size/2)'length + 1);
	
				multed_array_re(i)          := summed_array_re(i);
				multed_array_im(i)          := summed_array_im(i);
				
				complex_twiddle_mult(
					i,
					fft_size_exp,
					summed_array_re(i + size/2), 
					summed_array_im(i + size/2), 
					multed_array_re(i + size/2), 
					multed_array_im(i + size/2));
			end loop;
	
			for i in size - 1 downto 0 loop
				stage_done_re((bits_per_sample + 1) * (i + 1) - 1 downto (bits_per_sample + 1) * i) <= std_logic_vector(multed_array_re(i));
				stage_done_im((bits_per_sample + 1) * (i + 1) - 1 downto (bits_per_sample + 1) * i) <= std_logic_vector(multed_array_im(i));
			end loop;		
	
		end process;
	
		input_re1 <= stage_done_re(size * (bits_per_sample + 1) - 1 downto size/2 * (bits_per_sample + 1));
		input_im1 <= stage_done_im(size * (bits_per_sample + 1) - 1 downto size/2 * (bits_per_sample + 1));
	
		input_re0 <= stage_done_re(size/2 * (bits_per_sample + 1) - 1 downto 0);
		input_im0 <= stage_done_im(size/2 * (bits_per_sample + 1) - 1 downto 0);
	
		output_re <= output_re1 & output_re0;
		output_im <= output_im1 & output_im0;
	
		fft1: entity work.fft_dif
		generic map (
			stages_done => stages_done + 1,
			fft_size_exp => fft_size_exp - 1,
			bits_per_sample => bits_per_sample + 1)
		port map (
			input_re => input_re1,
			input_im => input_im1,
			
			output_re => output_re1,
			output_im => output_im1);
	
		fft0: entity work.fft_dif
		generic map (
			stages_done => stages_done + 1,
			fft_size_exp => fft_size_exp - 1,
			bits_per_sample => bits_per_sample + 1)
		port map (
			input_re => input_re0,
			input_im => input_im0,
			
			output_re => output_re0,
			output_im => output_im0);
	
	end generate general;	

end fft_dif_impl;