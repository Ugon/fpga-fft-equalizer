library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.fft_twiddle_factors_16.all;

package fft_utils is

	procedure complex_mult_16(
		twiddle:in  integer;
		in_re:  in  signed;
		in_im:  in  signed;
		out_re: out signed;
		out_im: out signed);

	function bit_reverse(number: unsigned) return unsigned;

	function negate_all(samples: std_logic_vector; number_of_samples: integer; bits_per_sample: integer) return std_logic_vector;

	function shuffle(samples: std_logic_vector; number_of_samples_exp: integer; bits_per_sample: integer) return std_logic_vector;

end;

package body fft_utils is

	procedure complex_mult_16(
		twiddle:in  integer;
		in_re:  in  signed;
		in_im:  in  signed;
		out_re: out signed;
		out_im: out signed) is
		constant tw_re: signed(tw_size - 1 downto 0) := re_16(twiddle * 2); -- * 2 forfft 8
		constant tw_im: signed(tw_size - 1 downto 0) := im_16(twiddle * 2); -- * 2 forfft 8

		--variable in_re_ext:         signed(in_re'length         downto 0);
		--variable in_im_ext:         signed(in_re'length         downto 0);

		variable multed1:           signed(in_re'length + tw_re'length - 1 downto 0);
		variable multed2:           signed(in_im'length + tw_im'length - 1 downto 0);
		variable multed3:           signed(in_re'length + tw_im'length - 1 downto 0);
		variable multed4:           signed(in_im'length + tw_re'length - 1 downto 0);

		--variable multed1_trunc_ext: signed(in_re'length downto 0);
		--variable multed2_trunc_ext: signed(in_im'length downto 0);
		--variable multed3_trunc_ext: signed(in_re'length downto 0);
		--variable multed4_trunc_ext: signed(in_im'length downto 0);

		variable multed1_trunc: signed(in_re'length - 1 downto 0);
		variable multed2_trunc: signed(in_im'length - 1 downto 0);
		variable multed3_trunc: signed(in_re'length - 1 downto 0);
		variable multed4_trunc: signed(in_im'length - 1 downto 0);

	begin
		--in_re_ext := in_re(in_re'length - 1) & in_re;
		--in_im_ext := in_im(in_im'length - 1) & in_im;

		if twiddle = 0 then
			out_re := in_re;  
			out_im := in_im;  
		elsif twiddle = 4 then
			out_re := - in_im;  
			out_im :=   in_re;
		else
			multed1 := in_re * tw_re;
			multed2 := in_im * tw_im;
			multed3 := in_re * tw_im;
			multed4 := in_im * tw_re;

			multed1_trunc := multed1(multed1'length - 2 downto tw_size - 1); -- * 2 ????
			multed2_trunc := multed2(multed2'length - 2 downto tw_size - 1); -- * 2 ????
			multed3_trunc := multed3(multed3'length - 2 downto tw_size - 1); -- * 2 ????
			multed4_trunc := multed4(multed4'length - 2 downto tw_size - 1); -- * 2 ????

			--multed1_trunc := multed1(in_re'length - 1 downto 0);
			--multed2_trunc := multed2(in_im'length - 1 downto 0);
			--multed3_trunc := multed3(in_re'length - 1 downto 0);
			--multed4_trunc := multed4(in_im'length - 1 downto 0);

			out_re := multed1_trunc - multed2_trunc;
			out_im := multed3_trunc + multed4_trunc;
		end if;

	end complex_mult_16;

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

	function shuffle(samples: std_logic_vector; number_of_samples_exp: integer; bits_per_sample: integer) return std_logic_vector is
		variable shuffled:  std_logic_vector(samples'length - 1 downto 0);
		variable reversed_i: integer;
	begin
		for i in 2**number_of_samples_exp - 1 downto 0 loop
			reversed_i := to_integer(bit_reverse(to_unsigned(i, number_of_samples_exp)));
			shuffled((reversed_i + 1) * bits_per_sample - 1 downto reversed_i * bits_per_sample) := std_logic_vector(signed(samples((i + 1) * bits_per_sample - 1 downto i * bits_per_sample)));
		end loop;
		return shuffled;
	end function;

end package body;