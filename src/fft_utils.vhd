library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.fft_twiddle_factors_256.all;

package fft_utils is
	constant tw_size: integer := tw_size;

	procedure complex_twiddle_mult(
		twiddle_num:  in  integer;
		fft_size_exp: in  integer;
		in_re:  	  in  signed;
		in_im:  	  in  signed;
		out_re: 	  out signed;
		out_im: 	  out signed);

	function bit_reverse(number: unsigned) return unsigned;

	function negate_all(samples: std_logic_vector; number_of_samples: integer; bits_per_sample: integer) return std_logic_vector;

	function shuffle(samples: std_logic_vector; fft_size_exp: integer; bits_per_sample: integer) return std_logic_vector;

end;

package body fft_utils is

	procedure complex_twiddle_mult(
		twiddle_num:  in  integer;
		fft_size_exp: in  integer;
		in_re:        in  signed;
		in_im:        in  signed;
		out_re:       out signed;
		out_im:       out signed)
	is
		constant tw_re:         signed(tw_size - 1 downto 0) := re_256(twiddle_num * 2**(tw_array_size_exp - fft_size_exp));
		constant tw_im:         signed(tw_size - 1 downto 0) := im_256(twiddle_num * 2**(tw_array_size_exp - fft_size_exp));

		variable multed1:       signed(in_re'length + tw_re'length - 1 downto 0);
		variable multed2:       signed(in_im'length + tw_im'length - 1 downto 0);
		variable multed3:       signed(in_re'length + tw_im'length - 1 downto 0);
		variable multed4:       signed(in_im'length + tw_re'length - 1 downto 0);

		variable multed1_trunc: signed(in_re'length - 1 downto 0);
		variable multed2_trunc: signed(in_im'length - 1 downto 0);
		variable multed3_trunc: signed(in_re'length - 1 downto 0);
		variable multed4_trunc: signed(in_im'length - 1 downto 0);

	begin
		if twiddle_num = 0 then
			out_re := in_re;  
			out_im := in_im;  
		elsif twiddle_num * 2**(8 - fft_size_exp) = 64 then
			out_re := - in_im;  
			out_im :=   in_re;
		else
			multed1 := in_re * tw_re;
			multed2 := in_im * tw_im;
			multed3 := in_re * tw_im;
			multed4 := in_im * tw_re;

			multed1_trunc := multed1(multed1'length - 2 downto tw_size - 1);
			multed2_trunc := multed2(multed2'length - 2 downto tw_size - 1);
			multed3_trunc := multed3(multed3'length - 2 downto tw_size - 1);
			multed4_trunc := multed4(multed4'length - 2 downto tw_size - 1);

			out_re := multed1_trunc - multed2_trunc;
			out_im := multed3_trunc + multed4_trunc;
		end if;

	end complex_twiddle_mult;

	function bit_reverse(number: unsigned) return unsigned is
		variable reversed: unsigned(number'range);
		alias number_alias: unsigned(number'reverse_range) is number;
	begin
		for i in number_alias'range loop
			reversed(i) := number_alias(i);
		end loop;
		return reversed;
	end function;

	function negate_all(samples: std_logic_vector; number_of_samples: integer; bits_per_sample: integer) return std_logic_vector is
		variable negated: std_logic_vector(samples'length - 1 downto 0);
	begin
		for i in number_of_samples - 1 downto 0 loop
			negated((i + 1) * bits_per_sample - 1 downto i * bits_per_sample) := std_logic_vector(- signed(samples((i + 1) * bits_per_sample - 1 downto i * bits_per_sample)));
		end loop;
		return negated;
	end function;

	function shuffle(samples: std_logic_vector; fft_size_exp: integer; bits_per_sample: integer) return std_logic_vector is
		variable shuffled:  std_logic_vector(samples'length - 1 downto 0);
		variable reversed_i: integer;
	begin
		for i in 2**fft_size_exp - 1 downto 0 loop
			reversed_i := to_integer(bit_reverse(to_unsigned(i, fft_size_exp)));
			shuffled((reversed_i + 1) * bits_per_sample - 1 downto reversed_i * bits_per_sample) := std_logic_vector(signed(samples((i + 1) * bits_per_sample - 1 downto i * bits_per_sample)));
		end loop;
		return shuffled;
	end function;

end package body;