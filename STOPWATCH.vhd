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
	
	--CHANGE (need to add a lot more signals)
	SIGNAL WATCH_OUT : STD_LOGIC_VECTOR(15 DOWNTO 0); -- general stopwatch ouput (Connect mux from other registers to here)

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
	
	SIGNAL IO_EN     : STD_LOGIC;

	BEGIN
	
	-- Use LPM function to create bidirection I/O data bus
	IO_BUS: lpm_bustri
	GENERIC MAP (
		lpm_width => 16
	)
	PORT MAP (
		data     => WATCH_OUT,   
		enabledt => IO_EN,
		tridata  => IO_DATA
	);

	
	-- CHANGE all of this 
	PROCESS (CLOCK, RESETN, IO_ADDR, IO_READ)
	BEGIN
	-- global reset  
		IF (RESETN = '0' OR ((IO_ADDR = "00000000010") AND (IO_WRITE = '1'))) THEN
			COUNT <= x"0000";
		ELSIF (rising_edge(CLOCK)) THEN
			COUNT <= COUNT + 1;
		END IF;
	END PROCESS;
	
	-- Drive IO_DATA when requested.
	IO_EN <=
		'1' WHEN (IO_ADDR(10 DOWNTO 4) = "0000111") AND (IO_READ = '1') -- address is any from x70 to x7F 
		ELSE '0';

END a;

