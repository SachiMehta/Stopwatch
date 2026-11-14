-- STOPWATCH.VHD (a peripheral module for SCOMP)
-- 2026.11.14
--
-- Timer returns a 16 bit counter value counting in seconds 
-- inputs:
-- outputs:

-- Authors: Sachi Mehta, 

LIBRARY IEEE;
LIBRARY LPM;

USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE LPM.LPM_COMPONENTS.ALL;


ENTITY STOPWATCH IS
	PORT(
		CLOCK,
		RESETN   : IN    STD_LOGIC;
		IO_ADDR  : IN    STD_LOGIC_VECTOR(10 DOWNTO 0);
		IO_READ  : IN    STD_LOGIC;
		IO_WRITE : IN    STD_LOGIC;
		IO_DATA  : INOUT STD_LOGIC_VECTOR(15 DOWNTO 0)
	);
END TIMER;


ARCHITECTURE a OF TIMER IS
	---- OUTPUT signals 
	SIGNAL WATCH_DATA_OUT : STD_LOGIC_VECTOR(15 DOWNTO 0); -- general stopwatch ouput (Connect mux from other registers to here)

	--GLOBAL TIMERS
	SIGNAL REG_FULL : STD_LOGIC_VECTOR(15 DOWNTO 0); -- only uses lowest bit but 16 bits to map easily to output
	SIGNAL LAP_NUMBER : STD_LOGIC_VECTOR(15 DOWNTO 0); -- only lowest 4 bits used 
	SIGNAL CURRENT_RUNNING : STD_LOGIC_VECTOR(15 DOWNTO 0); -- only lowest bit used 
	
	-- LAP SELECT
	SIGNAL TIMER_1 : STD_LOGIC_VECTOR(15 DOWNTO 0); -- highest bit tells if lap is running, next bit is blank, remaining 14 bits show timer data 
	SIGNAL TIMER_2 : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL TIMER_3 : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL TIMER_4 : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL TIMER_5 : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL TIMER_6 : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL TIMER_7 : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL TIMER_8 : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL TIMER_9 : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL TIMER_10 : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL TIMER_11 : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL TIMER_12 : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL TIMER_13 : STD_LOGIC_VECTOR(15 DOWNTO 0);
	
	----OTHER signals 
	SIGNAL IO_EN     : STD_LOGIC;

	BEGIN
	
	-- Use LPM function to create bidirection I/O data bus
	IO_BUS: lpm_bustri
	GENERIC MAP (
		lpm_width => 16
	)
	PORT MAP (
		data     => WATCH_DATA_OUT,   
		enabledt => IO_EN,
		tridata  => IO_DATA
	);

	
	-- CHANGE all of this 
	
	--RECEIVE command/data from SCOMP (SCOMP OUT)
	PROCESS (CLOCK, RESETN, IO_ADDR, IO_READ)
	BEGIN
	-- global reset  
		IF (RESETN = '0' OR ((IO_ADDR = "00000000010") AND (IO_WRITE = '1'))) THEN
			COUNT <= x"0000";
		ELSIF (rising_edge(CLOCK)) THEN
			COUNT <= COUNT + 1;
		END IF;
	END PROCESS;
	
	
	-- SEND register data to SCOMP (SCOMP IN)
	WITH IO_ADDR SELECT WATCH_OUT <=
		REG_FULL         WHEN "00001110000", -- 0x070
		LAP_NUMBER       WHEN "00001110001", -- 0x071
		CURRENT_RUNNING  WHEN "00001110010", -- 0x072
		 
		TIMER_1          WHEN "00001110011", -- 0x073
		TIMER_2          WHEN "00001110100", -- 0x074
		TIMER_3          WHEN "00001110101", -- 0x075
		TIMER_4          WHEN "00001110110", -- 0x076
		TIMER_5          WHEN "00001110111", -- 0x077
		TIMER_6          WHEN "00001111000", -- 0x078
		TIMER_7          WHEN "00001111001", -- 0x079
		TIMER_8          WHEN "00001111010", -- 0x07A
		TIMER_9          WHEN "00001111011", -- 0x07B
		TIMER_10         WHEN "00001111100", -- 0x07C
		TIMER_11         WHEN "00001111101", -- 0x07D
		TIMER_12         WHEN "00001111110", -- 0x07E
		TIMER_13         WHEN "00001111111", -- 0x07F
		x"0000"          WHEN OTHERS;
		
	IO_EN <=
		'1' WHEN (IO_ADDR(10 DOWNTO 4) = "0000111") AND (IO_READ = '1') -- address is any from x70 to x7F 
		ELSE '0';

END a;

