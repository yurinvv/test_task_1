class Environment;

	Driver  driver0;
	Monitor monitor0;
	Scoreboard scoreboard0;
	
	mailbox scb_mailbox;
	
	virtual dut_if _if;
	
	function new(string pathToCheckList);
		scb_mailbox = new (100);
		driver0 = new;
		monitor0 = new;
		scoreboard0 = new;
		monitor0._mailbox = scb_mailbox;
		scoreboard0._mailbox = scb_mailbox;
		scoreboard0.pathToCheckList = pathToCheckList;
	endfunction
	
	task run();
		driver0._if = _if;
		monitor0._if = _if;
		
		fork
			driver0.run();
			monitor0.run();
			scoreboard0.run();
		join
		
	endtask
	
endclass