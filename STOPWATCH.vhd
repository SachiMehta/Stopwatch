-- STOPWATCH.VHD (a peripheral module for SCOMP)
-- 2026.11.14
--
-- Timer returns a 16 bit counter value counting in seconds 
-- inputs:
-- outputs:

-- Authors: Sachi Mehta, Junwoo Min

LIBRARY IEEE;
LIBRARY LPM;

USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE LPM.LPM_COMPONENTS.ALL;


ENTITY STOPWATCH IS
	GENERIC (
		CLK_HZ  : INTEGER := 5   --  change when testing on hardware
	)
	PORT(
		CLOCK,
		RESETN   : IN    STD_LOGIC;
		IO_ADDR  : IN    STD_LOGIC_VECTOR(10 DOWNTO 0);
		IO_READ  : IN    STD_LOGIC;
		IO_WRITE : IN    STD_LOGIC;
		IO_DATA  : INOUT STD_LOGIC_VECTOR(15 DOWNTO 0)
	);
END STOPWATCH;


ARCHITECTURE a OF STOPWATCH IS
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

	-- Internal signals
	TYPE time_array IS ARRAY (1 TO 13) OF STD_LOGIC_VECTOR(8 DOWNTO 0);
	SIGNAL LAP_TIME : time_array;                          -- 9-bit seconds count for each lap
	SIGNAL RUN_BIT  : STD_LOGIC_VECTOR(1 TO 13);           -- Run flag per lap
	SIGNAL cur_lap  : INTEGER RANGE 1 TO 13;
	SIGNAL running  : STD_LOGIC;
	SIGNAL full     : STD_LOGIC;
	SIGNAL count : INTEGER RANGE 0 TO CLK_HZ-1;        -- clock divider for 1 second
	
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
	

	--CHANGE ALL OF THIS
	--RECEIVE command/data from SCOMP (SCOMP OUT)
	PROCESS (CLOCK, RESETN, IO_ADDR, IO_READ)
	BEGIN
	-- global reset  CHANGE ALL OF THIS
		IF (RESETN = '0' OR ((IO_ADDR = "00001110000") AND (IO_WRITE = '1'))) THEN
			--RESET ALL THE TIMERS
			FOR i IN 1 TO 13 LOOP
				LAP_TIME(i) <= (OTHERS => '0');
			END LOOP;
			cur_lap  <= 1;
			full     <= '0';
			count <= 0;
		ELSIF ((IO_ADDR = "00001110001") AND (IO_WRITE = '1')) THEN -- other global functions 
			--....
		--ELSIF (rising_edge(CLOCK)) THEN
			--if timer1 is set to play and within the 14bits data range 
				--count <= count +1 --(for that timer)
			-- if timer 2 is set to play and within the 14bits data range
				-- count 
			--....
			
		END IF;
	END PROCESS;
	
	
	-- SEND register data to SCOMP (SCOMP IN)
	WITH IO_ADDR SELECT WATCH_DATA_OUT <=
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

	-- Internal Signals into register
	REG_FULL        <= (15 DOWNTO 1 => '0') & full;
	CURRENT_RUNNING <= (15 DOWNTO 1 => '0') & running;
	LAP_NUMBER      <= CONV_STD_LOGIC_VECTOR(cur_lap, 16);

	RUN_FLAGS: FOR i IN 1 TO 13 GENERATE
		RUN_BIT(i) <= '1' WHEN (cur_lap = i AND running = '1') ELSE '0';
	END GENERATE;

	TIMER_1  <= RUN_BIT(1)  & "000000" & LAP_TIME(1);
	TIMER_2  <= RUN_BIT(2)  & "000000" & LAP_TIME(2);
	TIMER_3  <= RUN_BIT(3)  & "000000" & LAP_TIME(3);
	TIMER_4  <= RUN_BIT(4)  & "000000" & LAP_TIME(4);
	TIMER_5  <= RUN_BIT(5)  & "000000" & LAP_TIME(5);
	TIMER_6  <= RUN_BIT(6)  & "000000" & LAP_TIME(6);
	TIMER_7  <= RUN_BIT(7)  & "000000" & LAP_TIME(7);
	TIMER_8  <= RUN_BIT(8)  & "000000" & LAP_TIME(8);
	TIMER_9  <= RUN_BIT(9)  & "000000" & LAP_TIME(9);
	TIMER_10 <= RUN_BIT(10) & "000000" & LAP_TIME(10);
	TIMER_11 <= RUN_BIT(11) & "000000" & LAP_TIME(11);
	TIMER_12 <= RUN_BIT(12) & "000000" & LAP_TIME(12);
	TIMER_13 <= RUN_BIT(13) & "000000" & LAP_TIME(13);

END a;

