library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_image_generator is
	generic (
		vertical_axis:               integer := 128;
		horizontal_input_axis:       integer := 128 + 256;
		horizontal_output_re_axis:   integer := 128 + 256;
		horizontal_output_im_axis:   integer := 128 + 256 + 256;

		number_of_samples:           integer := 16; --for testing 4
		bits_per_sample:             integer := 24); --for testing 2
	port (
		reset_n:                    in  std_logic;
		disp_enabled:               in  std_logic;
		
		row:                        in  integer;
		column:                     in  integer;
		
		input_samples:              in  std_logic_vector(number_of_samples * bits_per_sample - 1 downto 0);
		output_re:                  in  std_logic_vector(number_of_samples * bits_per_sample - 1 downto 0);
		output_im:                  in  std_logic_vector(number_of_samples * bits_per_sample - 1 downto 0);

		input_samples_available:    in  std_logic;
		output_re_samples_available:in  std_logic;
		output_im_samples_available:in  std_logic;
		
		change_image:               in  std_logic;

		red:                        out std_logic_vector(9 downto 0);
		green:                      out std_logic_vector(9 downto 0);
		blue:                       out std_logic_vector(9 downto 0));
end vga_image_generator;

architecture vga_image_generator_impl of vga_image_generator is

	signal red_axis:         std_logic_vector(9 downto 0) := (others => '0');
	signal green_axis:       std_logic_vector(9 downto 0) := (others => '0');
	signal blue_axis:        std_logic_vector(9 downto 0) := (others => '0');
	signal red_points:       std_logic_vector(9 downto 0) := (others => '0');
	signal green_points:     std_logic_vector(9 downto 0) := (others => '0');
	signal blue_points:      std_logic_vector(9 downto 0) := (others => '0');

	signal input_samples_int:std_logic_vector(number_of_samples * bits_per_sample - 1 downto 0);
	signal output_re_int:    std_logic_vector(number_of_samples * bits_per_sample - 1 downto 0);
	signal output_im_int:    std_logic_vector(number_of_samples * bits_per_sample - 1 downto 0);

begin
	green_axis <= (others => '0');
	blue_axis <= (others => '0');

	process(disp_enabled)
	begin
		if(disp_enabled = '1') then
			red <= red_axis or red_points;
			green <= green_axis or green_points;
			blue <= blue_axis or blue_points;
		else
			red <= (others => '0');
			green <= (others => '0');
			blue <= (others => '0');
		end if;
	end process;

--todo: latching has to be done <=> new samples are available and when change_image was requested.
	process(reset_n, input_samples_available)
	begin
		if(reset_n = '0') then
			input_samples_int <= (others => '0');
		elsif(rising_edge(input_samples_available)) then
			input_samples_int <= input_samples;
		end if;
	end process;

	process(reset_n, disp_enabled, row, column)
		variable input_sample_start_index:       integer                              := 0;
		variable input_sample_full_value:        signed(bits_per_sample - 1 downto 0) := to_signed(0, bits_per_sample);
		variable input_sample_reduced_value:     signed(23 downto 0)                   := to_signed(0, 24); ---changed
		variable input_sample_int_value:         integer                              := 0;
	begin
		if (reset_n = '0' or disp_enabled = '0') then
			red_axis     <= (others => '0');
			red_points   <= (others => '0');
			green_points <= (others => '0');
			blue_points  <= (others => '0');
		else 
			if (row = horizontal_input_axis or row = horizontal_output_re_axis or row = horizontal_output_im_axis or column = vertical_axis) then
				red_axis <= (others => '1');
			else
				red_axis <= (others => '0');
			end if;

			if (column < vertical_axis or vertical_axis + number_of_samples <= column) then
				red_points   <= (others => '0');
				green_points <= (others => '0');
				blue_points  <= (others => '0');
			else
				input_sample_start_index   := bits_per_sample * (column - vertical_axis);
				for i in bits_per_sample - 1 downto 0 loop
					input_sample_full_value(i) := input_samples_int(input_sample_start_index + i);
				end loop;
--				input_sample_reduced_value := --input_sample_full_value(bits_per_sample - 1 downto bits_per_sample - 7);
--				input_sample_int_value     := to_integer(input_sample_reduced_value);
--
				input_sample_int_value := to_integer(input_sample_full_value);
				if (input_sample_int_value + horizontal_input_axis = row) then
					red_points   <= (others => '1');
					green_points <= (others => '1');
					blue_points  <= (others => '1');
				else 
					red_points   <= (others => '0');
					green_points <= (others => '0');
					blue_points  <= (others => '0');
				end if;
			end if;
		end if;
	end process;
end vga_image_generator_impl;