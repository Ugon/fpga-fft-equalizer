library ieee;
use ieee.std_logic_1164.all;

--  resolution:                1024x768
--  refresh rate:              60Hz
--  pixel clock:               65MHz
--  horizontall front porch:   24
--  horizontall sync pulse:    136
--  horizontall back porch:    160
--  vertical front porch:      3
--  vertical sync pulse:       6
--  vertical back porch:       29
--  hsync polarity:            n
--  vsync polarity:            n

entity vga_controller is
	generic (
		h_pixels:             integer   := 1024;
		h_front_porch:        integer   := 24;
		h_sync_pulse:         integer   := 136;
		h_back_porch:         integer   := 160;
		h_polarity:           std_logic := '0';
		v_pixels:             integer   := 768;
		v_front_porch:        integer   := 3;
		v_sync_pulse:         integer   := 6;
		v_back_porch:         integer   := 29;
		v_polarity:           std_logic := '0');
	port (
		clk_50MHz:        in  std_logic;
		reset_n:          in  std_logic;
		disp_enabled:     out std_logic;
		sync_n:           out std_logic;    --sync on green
		blank_n:          out std_logic;
		h_sync:           out std_logic;      
		v_sync:           out std_logic;
		vga_clk:          out std_logic;
		
		row:              out integer;
		column:           out integer;
		change_image:     out std_logic);
end vga_controller;

architecture vga_controller_impl of vga_controller is

	constant h_period: integer := h_pixels + h_front_porch + h_sync_pulse + h_back_porch;
	constant v_period: integer := v_pixels + v_front_porch + v_sync_pulse + v_back_porch;
	
	signal clk_65MHz:  std_logic;
	signal clk_16Hz:    std_logic;

	signal change_image_available: std_logic := '0';
	signal change_image_used:      std_logic := '1';

begin
	sync_n <=  '0';
	blank_n <= '1';
	vga_clk <= clk_65MHz;
	
	VGA_PLL_INSTANCE: entity work.vga_pll port map (
		inclk0 => clk_50MHz,
		c0 => 	  clk_65MHz
	);

	VGA_IMAGE_REFRESH_RATE_PRESCALER1: entity work.vga_image_refresh_rate_prescaler port map(
		clk_50MHz => clk_50MHz,
		clk_16Hz =>   clk_16Hz
	);

	process(reset_n, clk_16Hz) begin
		if(reset_n = '0') then
			change_image_available <= '0';
		elsif rising_edge(clk_16Hz) then
			if (change_image_available = change_image_used) then
				change_image_available <= not change_image_used;
			end if;
		end if;
	end process;

	process(clk_65MHz, reset_n, change_image_available)
		variable h_counter: integer range 0 to (h_period - 1) := 0;
		variable v_counter: integer range 0 to (v_period - 1) := 0;
	begin
		if (reset_n = '0') then
			h_counter    := 0;
			v_counter    := 0;
			h_sync       <= not h_polarity;
			v_sync       <= not v_polarity;
			disp_enabled <= '0';
			column       <= 0;
			row          <= 0;
			change_image_used <= '0';
		elsif (rising_edge(clk_65MHz)) then 
			if (h_counter < h_period - 1) then
				h_counter := h_counter + 1;
			else
				h_counter := 0;
				if (v_counter < v_period - 1) then
					v_counter := v_counter + 1;
				else
					v_counter := 0;
				end if;
			end if;

			if (h_pixels + h_front_porch <= h_counter and h_counter <= h_pixels + h_front_porch + h_sync_pulse) then
				h_sync <= h_polarity;
			else 
				h_sync <= not h_polarity;
			end if;

			if (v_pixels + v_front_porch <= v_counter and v_counter <= v_pixels + v_front_porch + v_sync_pulse) then
				v_sync <= v_polarity;
			else 
				v_sync <= not v_polarity;
			end if;

			if (v_counter < v_pixels) then
				row <= v_counter;
			end if;

			if (h_counter < h_pixels) then
				column <= h_counter;
			end if;

			if (h_counter < h_pixels and v_counter < v_pixels) then
				disp_enabled <= '1';
			else
				disp_enabled <= '0';
			end if;

			if (h_counter < h_pixels) then
				change_image <= '0';
			else 
				if(change_image_available = not change_image_used) then
					change_image_used <= change_image_available;
					change_image <= '1';
				end if;
			end if;
			
		end if;	
	end process;
end vga_controller_impl;