-- STOPWATCH.VHD (a peripheral module for SCOMP)
-- 2026.11.14
--
-- 12 lap timers, counting in deciseconds (0.1 s), 14 bits per lap.
-- Register map:
--   0x70  Reset          write: reset all          read: FULL in B0
--   0x71  Play/Pause     write: B0 = 1 play, 0 pause (current lap)
--                        read:  RUN in B0 (current lap)
--   0x72  Running status read:  B11-B0 = run bit of laps 12..1
--   0x73  Lap            write: next lap           read: lap number
--   0x74-0x7F  Lap timers 1-12 (B15 = RUN, B14 = 0, B13-B0 = time)
--
-- Authors: Sachi Mehta,

LIBRARY IEEE;
LIBRARY LPM;

USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE LPM.LPM_COMPONENTS.ALL;


ENTITY STOPWATCH IS
	GENERIC (
		DS_TICKS   : INTEGER   := 1000000;
		AUTO_START : STD_LOGIC := '0'
	);


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

	TYPE time_array IS ARRAY (1 TO 12) OF STD_LOGIC_VECTOR(13 DOWNTO 0); -- holds just the time
	TYPE reg_array  IS ARRAY (1 TO 12) OF STD_LOGIC_VECTOR(15 DOWNTO 0); -- full time register array 
	
	---- OUTPUT signals
	SIGNAL WATCH_DATA_OUT : STD_LOGIC_VECTOR(15 DOWNTO 0); -- general stopwatch output

	--GLOBAL REGISTERS
	SIGNAL REG_FULL        : STD_LOGIC_VECTOR(15 DOWNTO 0); -- only lowest bit used
	SIGNAL CURRENT_RUNNING : STD_LOGIC_VECTOR(15 DOWNTO 0); -- only lowest bit used
	SIGNAL RUNNING_STATUS  : STD_LOGIC_VECTOR(15 DOWNTO 0); -- bits 11 downto 0 = laps 12 downto 1
	SIGNAL LAP_NUMBER      : STD_LOGIC_VECTOR(15 DOWNTO 0); -- only lowest 4 bits used

	-- LAP TIMERS: bit 15 = running, bit 14 = blank, bits 13-0 = time
	SIGNAL TIMER      : reg_array;
	
	
	SIGNAL LAP_TIME   : time_array;
	SIGNAL lap_run    : STD_LOGIC_VECTOR(1 TO 12); -- which laps are running 
	
	SIGNAL temp_status : STD_LOGIC_VECTOR(11 DOWNTO 0);
	
	SIGNAL cur_lap    : INTEGER RANGE 1 TO 12;
	SIGNAL full       : STD_LOGIC;
	SIGNAL count      : INTEGER RANGE 0 TO DS_TICKS-1;
	SIGNAL write_prev : STD_LOGIC;

	----OTHER signals
	SIGNAL IO_EN : STD_LOGIC;

BEGIN

	-- Use LPM function to create bidirectional I/O data bus
	IO_BUS: lpm_bustri
	GENERIC MAP (
		lpm_width => 16
	)
	PORT MAP (
		data     => WATCH_DATA_OUT,
		enabledt => IO_EN,
		tridata  => IO_DATA
	);

	-- RECEIVE command/data from SCOMP (SCOMP OUT)
	PROCESS (CLOCK, RESETN)
		VARIABLE sel  : INTEGER RANGE 1 TO 12;
		VARIABLE nxt  : INTEGER RANGE 1 TO 12;
		VARIABLE tick : BOOLEAN;

	BEGIN
		IF RESETN = '0' THEN
			FOR i IN 1 TO 12 LOOP
				LAP_TIME(i) <= (OTHERS => '0');
			END LOOP;
			
			lap_run    <= (1 => AUTO_START, OTHERS => '0');
			cur_lap    <= 1;
			full       <= '0';
			count      <= 0;
			write_prev <= '0';
		
		ELSIF RISING_EDGE(CLOCK) THEN
			
			write_prev <= IO_WRITE;

			tick := FALSE;
			IF count = DS_TICKS-1 THEN
				count <= 0;
				tick  := TRUE;
			ELSE
				count <= count + 1;
			END IF;

			IF tick THEN
				FOR i IN 1 TO 12 LOOP
					IF lap_run(i) = '1' AND LAP_TIME(i) /= "11111111111111" THEN
						LAP_TIME(i) <= LAP_TIME(i) + 1;
					END IF;
				END LOOP;
			END IF;
			
			IF IO_WRITE = '1' AND IO_ADDR(10 DOWNTO 4) = "0000111" THEN
			CASE IO_ADDR(3 DOWNTO 0) IS

				WHEN "0000" => -- 0x70 RESET
					FOR i IN 1 TO 12 LOOP
						LAP_TIME(i) <= (OTHERS => '0');
					END LOOP;
					
					lap_run    <= (1 => AUTO_START, OTHERS => '0');
					cur_lap    <= 1;
					full       <= '0';
					count   <= 0;
				
				WHEN "0001" => -- 0x71 PLAY data bit 0 sets the run bit of the current lap
					lap_run(cur_lap) <= '1';
				
				WHEN "0010" => -- 0x72 PAUSE data bit 0 sets the run bit of the current lap
					lap_run(cur_lap) <= '0'; 
					
				WHEN "0011" => -- 0x73 LAP: pause current lap, start next lap from 0
					IF cur_lap = 12 THEN
							nxt := 1;
					ELSE
						nxt := cur_lap + 1;
					END IF;
					
					lap_run(cur_lap) <= '0';
					lap_run(nxt)     <= '1';
					LAP_TIME(nxt)    <= (OTHERS => '0');
					cur_lap          <= nxt;
					
				WHEN OTHERS => -- lap select functions
						sel := CONV_INTEGER(IO_ADDR(3 DOWNTO 0)) - 3;
						CASE IO_DATA(15 DOWNTO 14) IS
							WHEN "00"   => LAP_TIME(sel) <= (OTHERS => '0'); -- reset 
							
							WHEN "01"   => lap_run(sel)  <= '1'; -- play
							WHEN "10"   => lap_run(sel)  <= '0'; -- pause
							
							WHEN "11"   => LAP_TIME(sel) <= IO_DATA(13 DOWNTO 0); -- manual set
							WHEN OTHERS => NULL;
						END CASE;
			END CASE;
		END IF;

		END IF;
		
		 
				
		
		
	END PROCESS;

	-- SEND register data to SCOMP (SCOMP IN)
	WITH IO_ADDR SELECT WATCH_DATA_OUT <=
		REG_FULL         WHEN "00001110000", -- 0x070
		CURRENT_RUNNING  WHEN "00001110001", -- 0x071
		RUNNING_STATUS   WHEN "00001110010", -- 0x072
		LAP_NUMBER       WHEN "00001110011", -- 0x073

		TIMER(1)         WHEN "00001110100", -- 0x074
		TIMER(2)         WHEN "00001110101", -- 0x075
		TIMER(3)         WHEN "00001110110", -- 0x076
		TIMER(4)         WHEN "00001110111", -- 0x077
		TIMER(5)         WHEN "00001111000", -- 0x078
		TIMER(6)         WHEN "00001111001", -- 0x079
		TIMER(7)         WHEN "00001111010", -- 0x07A
		TIMER(8)         WHEN "00001111011", -- 0x07B
		TIMER(9)         WHEN "00001111100", -- 0x07C
		TIMER(10)        WHEN "00001111101", -- 0x07D
		TIMER(11)        WHEN "00001111110", -- 0x07E
		TIMER(12)        WHEN "00001111111", -- 0x07F
		x"0000"          WHEN OTHERS;

	IO_EN <=
		'1' WHEN (IO_ADDR(10 DOWNTO 4) = "0000111") AND (IO_READ = '1') -- address is any from x70 to x7F
		ELSE '0';
		
		-- Internal Signals into register
		REG_FULL        <= "0000000000000000";
		--REG_FULL        <= "000000000000000" & full;
		CURRENT_RUNNING <= "000000000000000" & lap_run(cur_lap);
		
		Status_gen: FOR i IN 1 TO 12 GENERATE
			temp_status(i - 1) <= lap_run(i); 
		END GENERATE;
	
		RUNNING_STATUS <= "0000" & temp_status;
		--RUNNING_STATUS <= "0000" & lap_run;
		
		LAP_NUMBER      <= CONV_STD_LOGIC_VECTOR(cur_lap, 16);

		TIMER_REGS: FOR i IN 1 TO 12 GENERATE
			TIMER(i) <= lap_run(i) & '0' & LAP_TIME(i);
		END GENERATE;

END a;
