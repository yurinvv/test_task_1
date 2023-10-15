class Test_Check_6144;
	Environment environment0;
	const integer F1 = 263;
	const integer F2 = 480;
	const integer K = 6144;
	const string PATH = "./check_6144.txt";
	
	function new();
		environment0 = new(PATH);
		environment0.driver0.f1 = F1;
		environment0.driver0.f2 = F2;
		environment0.driver0.k  = K;
	endfunction
	
	task run();
		$display("T=%0t Test_Check_6144 is starting...", $time);
		environment0.run();
	endtask
endclass