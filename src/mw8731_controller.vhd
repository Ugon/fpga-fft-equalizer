library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--mclk to mw8731 must be 18.432

entity mw8731_controller is
	port (
		clk_50MHz:            in    std_logic;
		reset_n:              in    std_logic;
		
		left_channel_sample:  out   signed(23 downto 0) := (others => '0');
		right_channel_sample: out   signed(23 downto 0) := (others => '0');
		sample_available:     out   std_logic           := '0';
		start_operation:      in    std_logic; --starts operation at rising edge
		
		mclk_18MHz:           out   std_logic;               --18.432MHz

		bclk:                 in    std_logic;
		adclrc:               in    std_logic;
		adcdat:               in    std_logic;

		i2c_sdat:             out   std_logic           := '1';
		i2c_sclk:             out   std_logic           := '1';
		
		test_programming_done:out std_logic := '0');-------------------------------------------------------
end mw8731_controller;

architecture wm8731_controller_impl of mw8731_controller is
	constant wm8731_address: std_logic_vector(6 downto 0) := "0011010";
		
	type fsm is (idle, reg0001001deactivate, reg0000000, reg0000001, reg0000010, reg0000011, reg0000100, reg0000101, reg0000110, reg0000111, reg0001000, reg0001001activate, receive);
	signal state:                    fsm := idle;

	signal clk_100kHz:               std_logic;

	signal i2c_byte1:                std_logic_vector(7 downto 0);
	signal i2c_byte2:                std_logic_vector(7 downto 0);

	signal i2c_transmission_start:   std_logic;
	signal i2c_transmission_ongoing: std_logic;

	signal dsp_transmit:             std_logic;

	signal data_available_int:       std_logic := '0';
	signal finished_config:          std_logic := '0';


begin

	MW8731_PLL_INSTANCE: entity work.wm8731_pll port map (
		inclk0 => clk_50MHz,
		c0 => 	  mclk_18MHz	
	);

	I2C_CLK_PRESCALER_INSTANCE: entity work.i2c_clk_prescaler port map (
		clk_50MHz => clk_50MHz,
		clk_100kHz => clk_100kHz
	);

	I2C_MASTER_WRITER_INSTANCE: entity work.i2c_master_writer port map (
		clk => clk_100kHz,
		reset_n => reset_n,
		
		address => wm8731_address,
		byte1 => i2c_byte1,
		byte2 => i2c_byte2,
		
		transmission_start => i2c_transmission_start,
		transmission_ongoing => i2c_transmission_ongoing,

		i2c_sdat => i2c_sdat,
		i2c_sclk => i2c_sclk
	);

	DSP_SLAVE_READER_INSTANCE: entity work.dsp_slave_reader port map (
		reset_n => reset_n,
		
		left_channel_sample => left_channel_sample,
		right_channel_sample => right_channel_sample,
		sample_available => sample_available,
		transmit => dsp_transmit,
		
		bclk => bclk,
		adclrc => adclrc,
		adcdat => adcdat
	);

	data_available_int <= data_available_int and finished_config;

	process (reset_n, clk_100kHz) 
	begin
		if(reset_n = '0') then
			finished_config <= '0';
			state <= idle;
		elsif(rising_edge(clk_100kHz)) then
			case state is
				when idle =>
					if(start_operation = '1') then
						state <= reg0001001deactivate;
					end if;
				when reg0001001deactivate =>                     --Active Control
					if(i2c_transmission_ongoing = '1') then
						i2c_transmission_start <= '0';
					else
						i2c_byte1 <= "00010010";
						i2c_byte2 <= "00000000";
						i2c_transmission_start <= '1';
						state <= reg0000000;	
					end if;
				when reg0000000 =>                               --Left Line In
					i2c_byte1 <= "00000001";
					i2c_byte2 <= "00010111";
					i2c_transmission_start <= '1';
					state <= reg0000001;					
				when reg0000001 =>                               --Right Line In
					state <= reg0000010;	
				when reg0000010 =>                               --Left Headphone Out
					state <= reg0000011;	
				when reg0000011 =>                               --Right Headphone Out
					state <= reg0000100;	
				when reg0000100 =>                               --Analogue Audio Path Control
					if(i2c_transmission_ongoing = '1') then
						i2c_transmission_start <= '0';
					else
						i2c_byte1 <= "00001000";
						i2c_byte2 <= "00000010";
						i2c_transmission_start <= '1';
						state <= reg0000101;	
					end if;
				when reg0000101 =>                               --Digital Audio Path Control
					if(i2c_transmission_ongoing = '1') then
						i2c_transmission_start <= '0';
					else
						i2c_byte1 <= "00001010";
						i2c_byte2 <= "00000000";
						i2c_transmission_start <= '1';
						state <= reg0000110;	
					end if;
				when reg0000110 =>                               --Power Down Control
					if(i2c_transmission_ongoing = '1') then
						i2c_transmission_start <= '0';
					else
						i2c_byte1 <= "00001100";
						i2c_byte2 <= "00000000";
						i2c_transmission_start <= '1';
						state <= reg0000111;	
					end if;
				when reg0000111 =>                               --Digital Audio Interface Format
					if(i2c_transmission_ongoing = '1') then
						i2c_transmission_start <= '0';
					else
						i2c_byte1 <= "00001110";
						i2c_byte2 <= "01011011";
						i2c_transmission_start <= '1';
						state <= reg0001000;	
					end if;
				when reg0001000 =>                               --Sampling Control
					if(i2c_transmission_ongoing = '1') then
						i2c_transmission_start <= '0';
					else
						i2c_byte1 <= "00010000";
						i2c_byte2 <= "00000010";
						i2c_transmission_start <= '1';
						state <= reg0001001activate;	
					end if;
				when reg0001001activate =>                       --Active Control
					if(i2c_transmission_ongoing = '1') then
						i2c_transmission_start <= '0';
					else
						i2c_byte1 <= "00010010";
						i2c_byte2 <= "00000001";
						i2c_transmission_start <= '1';
						state <= receive;	
					end if;
				when receive =>
					if(i2c_transmission_ongoing = '1') then
						i2c_transmission_start <= '0';
					else
						finished_config <= '1';
						dsp_transmit <= '1';
test_programming_done <= '1'; ---------------------------------------------------------------
					end if;					
			end case;
		end if;
	end process;

end wm8731_controller_impl;