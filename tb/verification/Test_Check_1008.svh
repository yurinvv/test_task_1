class Test_Check_1008;
	Environment environment0;
	const integer F1 = 55;
	const integer F2 = 84;
	const integer K = 1008;
	const string PATH = "./check_1008.txt";
	
	function new();
		environment0 = new(PATH);
		environment0.driver0.f1 = F1;
		environment0.driver0.f2 = F2;
		environment0.driver0.k  = K;
	endfunction
	
	task run();
		$display("T=%0t Test_Check_1008 is starting...", $time);
		environment0.run();
	endtask
endclass