library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package vga_utils is	

	function brick_is_on(sample_number: integer; level: integer; number_of_samples: integer; bits_per_sample: integer; equalized_frequency_sample_left: std_logic_vector; equalized_frequency_sample_right: std_logic_vector; scaling_factor: unsigned) return boolean;

end;

package body vga_utils is

	function brick_is_on(sample_number: integer; level: integer; number_of_samples: integer; bits_per_sample: integer; equalized_frequency_sample_left: std_logic_vector; equalized_frequency_sample_right: std_logic_vector; scaling_factor: unsigned) return boolean is
		type arr is array (0 to 9) of integer;
		constant thresholds: arr := (
			9 =>  38400,

			8 =>  32000,
			7 =>  25600,
			
			6 =>  22400,
			5 =>  19200,
			4 =>  16000,
			3 =>  12800,
			2 =>  9600,
			1 =>  6400,
			0 =>  3200);

		variable avg:                     unsigned(bits_per_sample - 1 downto 0);
		variable left_sample:             signed(bits_per_sample - 1 downto 0);
		variable right_sample:            signed(bits_per_sample - 1 downto 0);
		variable left_sample_extended:    unsigned(bits_per_sample downto 0);
		variable right_sample_extended:   unsigned(bits_per_sample downto 0);
		variable scaling_factor_int:      unsigned(scaling_factor'range);

	begin
	
		left_sample  := signed(equalized_frequency_sample_left ((sample_number + 1) * bits_per_sample - 1 downto sample_number * bits_per_sample));
		right_sample := signed(equalized_frequency_sample_right((sample_number + 1) * bits_per_sample - 1 downto sample_number * bits_per_sample));
		
		if (scaling_factor = to_unsigned(0, scaling_factor'length)) then
			scaling_factor_int := to_unsigned(1, scaling_factor_int'length);
		else 
			scaling_factor_int := scaling_factor;
		end if;

		if (left_sample >= 0) then
			left_sample_extended  := unsigned(  resize(left_sample,  bits_per_sample + 1));
		else 
			left_sample_extended  := unsigned(- resize(left_sample,  bits_per_sample + 1));
		end if;

		if (right_sample >= 0) then
			right_sample_extended := unsigned(  resize(right_sample, bits_per_sample + 1));
		else
			right_sample_extended := unsigned(- resize(right_sample, bits_per_sample + 1));
		end if;

		avg := resize((left_sample_extended + right_sample_extended) / 2, avg'length);

		if ((avg / scaling_factor_int) > thresholds(level)) then
			return true;
		else
			return false;
		end if;
		
	end function;

end package body;