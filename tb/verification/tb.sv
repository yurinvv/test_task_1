`timescale 1ns/1ns

module tb;

	import tb_pckg::*;
	/////////////////////////////////////
	//  Select the Test
	/////////////////////////////////////
	//Test_Check_48 test;
	Test_Check_1008 test;
	//Test_Check_6144 test;
	
	////////////////////////////////////

	localparam CLOCK_PERIOD = 10;

	bit aclk;
	bit aresetn;
	
	// DUT Interface
	dut_if _if(aclk, aresetn);
	
	// DUT
	interleaver_design_wrapper dut (
		.aclk             ( aclk          ),
		.aresetn          ( aresetn       ),
		.m_axis_ind_tdata ( _if.ind_tdata ),
		.m_axis_ind_tlast ( _if.ind_tlast ),
		.m_axis_ind_tready( _if.ind_tready),
		.m_axis_ind_tuser ( _if.ind_tuser ),
		.m_axis_ind_tvalid( _if.ind_tvalid),
		.s_axis_f1_tdata  ( _if.f1_tdata  ),
		.s_axis_f2_tdata  ( _if.f2_tdata  ),
		.s_axis_k_tdata   ( _if.k_tdata   ),
		.s_axis_k_tready  ( _if.k_tready  ),
		.s_axis_k_tvalid  ( _if.k_tvalid  )
	);
		
	/////////////////////////////////
	// Clock generation

	initial begin
		aclk = 0;
		forever #(CLOCK_PERIOD/2) aclk = !aclk;
	end
	
	/////////////////////////////////
	// Reset

	initial begin
		aresetn <= 0;
		#1000 aresetn <= 1;
	end

	////////////////////////////////
	// Main thread
	initial begin
		//_if.initSlaveSignals();
		test = new; 
		test.environment0._if = _if;
		wait(aresetn);
		#1000;
		test.run();
		
		#100 $finish;
	end
	
endmodule