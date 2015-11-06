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
		row:              out integer;
		column:           out integer;
		sync_n:           out std_logic;    --sync on green
		blank_n:          out std_logic;
		h_sync:           out std_logic;      
		v_sync:           out std_logic;
		vga_clk:          out std_logic);
end vga_controller;

architecture vga_controller_impl of vga_controller is

	constant h_period: integer := h_pixels + h_front_porch + h_sync_pulse + h_back_porch;
	constant v_period: integer := v_pixels + v_front_porch + v_sync_pulse + v_back_porch;
	signal clk_65MHz:  std_logic;

begin
	VGA_PLL_INSTANCE: entity work.vga_pll port map (
		inclk0 => clk_50MHz,
		c0 => 	  clk_65MHz
	);

	sync_n <=  '0';
	blank_n <= '1';
	vga_clk <= clk_65MHz;

	process(clk_65MHz, reset_n)
		variable h_counter : integer range 0 to (h_period - 1) := 0;
		variable v_counter : integer range 0 to (v_period - 1) := 0;
	begin
		if (reset_n = '0') then
			h_counter    := 0;
			v_counter    := 0;
			h_sync       <= not h_polarity;
			v_sync       <= not v_polarity;
			disp_enabled <= '0';
			column       <= 0;
			row          <= 0;
		elsif (rising_edge(clk_65MHz)) then 
			-- calculating h_counter and _ v_counter
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

--      IF(h_counter < h_pixels + h_front_porch OR h_counter > h_pixels + h_front_porch + h_sync_pulse) THEN
--        h_sync <= NOT h_polarity;    --deassert horiztonal sync pulse
--      ELSE
--        h_sync <= h_polarity;        --assert horiztonal sync pulse
--      END IF;

			-- calculating h_sync
			if (h_pixels + h_front_porch <= h_counter and h_counter <= h_pixels + h_front_porch + h_sync_pulse) then
				h_sync <= h_polarity;
			else 
				h_sync <= not h_polarity;
			end if;

--      IF(v_counter < v_pixels + v_front_porch OR v_counter > v_pixels + v_front_porch + v_sync_pulse) THEN
--        v_sync <= NOT v_polarity;    --deassert vertical sync pulse
--      ELSE
--        v_sync <= v_polarity;        --assert vertical sync pulse
--      END IF;

			-- calculating v_sync
			if (v_pixels + v_front_porch <= v_counter and v_counter <= v_pixels + v_front_porch + v_sync_pulse) then
				v_sync <= v_polarity;
			else 
				v_sync <= not v_polarity;
			end if;

			-- calculating row
			if (v_counter < v_pixels) then
				row <= v_counter;
			end if;

			-- calculating column
			if (h_counter < h_pixels) then
				column <= h_counter;
			end if;

			-- calculating when to enable display
			if (h_counter < h_pixels and v_counter < v_pixels) then
				disp_enabled <= '1';
			else
				disp_enabled <= '0';
			end if;
			
		end if;	
	end process;
end vga_controller_impl;