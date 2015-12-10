library ieee;
use ieee.std_logic_1164.all;

entity vga_image_refresh_rate_prescaler is
	port (
		clk_50Mhz:  in  std_logic;
		clk_16Hz:    out std_logic);
end vga_image_refresh_rate_prescaler;

architecture vga_image_refresh_rate_prescaler_impl of vga_image_refresh_rate_prescaler is
	constant switch_threshold: integer := 1562500;
	signal   clk_16Hz_int:   std_logic;
begin
	clk_16Hz <= clk_16Hz_int;

	process (clk_50Mhz)
		variable count: integer := 0;
	begin
		if(rising_edge(clk_50Mhz)) then
			if(count < switch_threshold) then
				count := count + 1;
			else 
				count := 0;
				clk_16Hz_int <= not clk_16Hz_int;
			end if;
		end if;
	end process;
	
end vga_image_refresh_rate_prescaler_impl;