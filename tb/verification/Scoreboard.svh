class Scoreboard;
	mailbox _mailbox;
	string pathToCheckList;
	
	local int fails;
    local int check_counter;
    local bit [31:0] vector_data;
    local bit [31:0] test_data;
    
    local int fd;
    local string line;
	
	task run();
		//$display("T=%0t Scoreboard is starting...", $time);
		
		fails = 0;
		check_counter = 0;
		fd = $fopen(pathToCheckList, "r");
		
		while(!$feof(fd)) begin
			check_counter++;
			$fgets(line, fd);
			
			if (line == "")
				break;
			
			test_data = line.atoi();
			_mailbox.get(vector_data);
			
			$display("T=%0t Scoreboard. %d) vector_data = %d, test_data = %d", $time, check_counter, vector_data, test_data);
			if (vector_data != test_data) begin
				//$display("T=%0t Scoreboard: Fail checking: vector_data = %d, test_data = %d", $time, vector_data, test_data);
				fails++;
			end
		end
		$fclose(fd);
		
		//$display("T=%0t Scoreboard stopped", $time);
		$display("T=%0t Scoreboard: Number of Comparissons = %d", $time, check_counter);
		$display("T=%0t Scoreboard: Number of Test fails = %d", $time, fails);
		
		if (fails > 0) begin
			$display("##################################");
			$display("####     TEST FAILED! :-(   ######");
			$display("##################################");
		end else begin
			$display("######################################");
			$display("####    TEST PASSED!!! :-D      ######");
			$display("######################################");
		end
	endtask
	
	
	
endclass