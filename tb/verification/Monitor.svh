class Monitor;
	virtual dut_if _if;
	mailbox _mailbox;
	
	OutData item;
	//bit [31:0] item;
	
	task run();
		//$display("T=%0t Monitor is starting...", $time);
		item = new;
		item.vector_data = 0;
		item.eov = 0;
	
		while( item.eov == 0) begin
			_if.receiveData(item.sov, item.vector_data, item.eov);
			_mailbox.put(item.vector_data);
		end
		
		//$display("T=%0t Monitor stopped", $time);
	endtask
	
endclass