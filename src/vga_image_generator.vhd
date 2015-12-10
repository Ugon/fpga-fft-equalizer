library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.vga_utils.all;

entity vga_image_generator is
	generic (
		number_of_samples:                    integer := 32;
		bits_per_sample:                      integer := 16;

		h_pixels:                             integer := 1024;
		v_pixels:                             integer := 768;

		left_margin:                          integer := 32;
		bottom_margin:                        integer := 30;

		vertical_gap:                         integer := 2;
		horizontal_gap:                       integer := 1;

		brick_width:                          integer := 120;
		brick_height:                         integer := 70;

		number_of_frequency_bins:             integer := 8;
		number_of_levels:                     integer := 10);
	port (
		reset_n:                          in  std_logic;
		clk_50MHz:                        in  std_logic;

		disp_enabled:                     in  std_logic;
		change_image:                     in  std_logic;
		
		row:                              in  integer;
		column:                           in  integer;
		
		equalized_frequency_sample_left:  in  std_logic_vector(number_of_samples * bits_per_sample - 1 downto 0); 
		equalized_frequency_sample_right: in  std_logic_vector(number_of_samples * bits_per_sample - 1 downto 0);

		scaling_factor:                   in  unsigned(7 downto 0);
		
		red:                              out std_logic_vector(9 downto 0);
		green:                            out std_logic_vector(9 downto 0);
		blue:                             out std_logic_vector(9 downto 0));
end vga_image_generator;

architecture vga_image_generator_impl of vga_image_generator is
	type color_type is (green_color, yellow_color, red_color, black_color);
	signal color: color_type;

	type img_type is array (0 to number_of_frequency_bins - 1, 0 to number_of_levels - 1) of boolean;
	signal abstract_image: img_type;

	signal equalized_frequency_sample_left_latched:  std_logic_vector(number_of_samples * bits_per_sample - 1 downto 0);
	signal equalized_frequency_sample_right_latched: std_logic_vector(number_of_samples * bits_per_sample - 1 downto 0);

	signal row_internal:                             integer;

begin
	
	row_internal <= v_pixels - row - 1;

	process (change_image) begin
		if rising_edge(change_image) then
			equalized_frequency_sample_left_latched <= equalized_frequency_sample_left;
			equalized_frequency_sample_right_latched <= equalized_frequency_sample_right;
		end if;
	end process;
	
	process	(equalized_frequency_sample_left_latched, equalized_frequency_sample_right_latched, scaling_factor) begin
		for sample_index in 0 to number_of_frequency_bins - 1 loop
			for level in 0 to number_of_levels - 1 loop
				if brick_is_on(sample_index, level, number_of_samples, bits_per_sample, equalized_frequency_sample_left_latched, equalized_frequency_sample_right_latched, scaling_factor) then 
					abstract_image(sample_index, level) <= true;
				else
					abstract_image(sample_index, level) <= false;
				end if ;
			end loop;
		end loop;
	end process;

	process (column, row_internal, abstract_image)
		variable abstract_column: integer;
		variable abstract_row:    integer;
	begin
		abstract_column := number_of_frequency_bins;
		abstract_row    := number_of_levels;

		for sample_index in 0 to number_of_frequency_bins - 1 loop
			if (left_margin + sample_index * (brick_width + vertical_gap) <= column and column < left_margin + sample_index * (brick_width + vertical_gap) + brick_width) then
				abstract_column := sample_index;
			end if;
		end loop;

		for level in 0 to number_of_levels - 1 loop
			if (bottom_margin + level * (brick_height + horizontal_gap) <= row_internal and row_internal < bottom_margin + level * (brick_height + horizontal_gap) + brick_height) then
				abstract_row := level;
			end if;
		end loop;

		if(abstract_column = number_of_frequency_bins or abstract_row = number_of_levels) then
			color <= black_color;
		elsif abstract_image(abstract_column, abstract_row) then 
			case abstract_row is
				when 0|1|2|3|4|5|6 => 
					color <= green_color;
				when 7|8 =>
					color <= yellow_color;
				when others => 
					color <= red_color;
			end case;
		else 
			color <= black_color;
		end if;
	end process;

	process(reset_n, disp_enabled, color) begin
		if (reset_n = '0' or disp_enabled = '0') then
			red   <= (others => '0');
			green <= (others => '0');
			blue  <= (others => '0');
		else
			case color is
				when green_color =>
					red   <= (others => '0');
					green <= (others => '1');
					blue  <= (others => '0');
				when yellow_color =>
					red   <= (others => '1');
					green <= (others => '1');
					blue  <= (others => '0');
				when red_color =>
					red   <= (others => '1');
					green <= (others => '0');
					blue  <= (others => '0');
				when black_color =>
					red   <= (others => '0');
					green <= (others => '0');
					blue  <= (others => '0');
			end case;
		end if;
	end process;

end vga_image_generator_impl;