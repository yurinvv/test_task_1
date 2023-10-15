class Driver;
	virtual dut_if _if;
	//event driver_done;
	
	integer f1, f2, k;
	
	task run();
		//$display("T=%0t Driver is starting...", $time);
		_if.initSlaveSignals();
		
		@(posedge _if.aclk);
		_if.sendConstatnts(f1, f2, k);
		//$display("T=%0t Driver sent data and stopped", $time);
		//->driver_done;
	endtask
endclass