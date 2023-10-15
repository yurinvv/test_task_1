class Test_Check_48;
	Environment environment0;
	const integer F1 = 7;
	const integer F2 = 12;
	const integer K = 48;
	const string PATH = "./check_48.txt";
	
	function new();
		environment0 = new(PATH);
		environment0.driver0.f1 = F1;
		environment0.driver0.f2 = F2;
		environment0.driver0.k  = K;
	endfunction
	
	task run();
		$display("T=%0t Test_Check_48 is starting...", $time);
		environment0.run();
	endtask
endclass