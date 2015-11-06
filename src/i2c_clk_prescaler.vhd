library ieee;
use ieee.std_logic_1164.all;

entity i2c_clk_prescaler is
	port (
		clk_50Mhz:  in  std_logic;
		clk_100kHz: out std_logic);
end i2c_clk_prescaler;

architecture i2c_clk_prescaler_impl of i2c_clk_prescaler is
	constant switch_threshold: integer := 250;
	signal   clk_100kHz_int:   std_logic;
begin
	clk_100kHz <= clk_100kHz_int;

	process (clk_50Mhz)
		variable count: integer := 0;
	begin
		if(rising_edge(clk_50Mhz)) then
			if(count < switch_threshold) then
				count := count + 1;
			else 
				count := 0;
				clk_100kHz_int <= not clk_100kHz_int;
			end if;
		end if;
	end process;
	
end i2c_clk_prescaler_impl;