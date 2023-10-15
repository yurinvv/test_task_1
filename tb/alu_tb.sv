`timescale 1ns/1ns

module alu_tb;

	parameter DATA_WIDTH = 64;
	parameter ALU_OPP_WIDTH = 2;
	
	localparam RSTN_HIGH_t = 1000; 
	
	localparam  SUM = 0,
				MULT = 1,
				DIV = 2;
	
	
	/////////////////
	// Knobs
		parameter A = 64'd19;
		parameter B = 64'd48;
	
	/////////////////
	
	bit aclk;
	bit aresetn;
	bit [ALU_OPP_WIDTH - 1 : 0] alu_opp;
	IAxiStream #(.DATA_SIZE(DATA_WIDTH)) driver_a_axis(aclk);
	IAxiStream #(.DATA_SIZE(DATA_WIDTH)) driver_b_axis(aclk);
	IAxiStream #(.DATA_SIZE(DATA_WIDTH)) monitor_axis(aclk);
	
	
	alu #(
		.IDATA_WIDTH   (DATA_WIDTH),
		.ALU_OPP_WIDTH (ALU_OPP_WIDTH)
	) dut (
		.aclk    (aclk),
		.aresetn (aresetn),
		
		.i_alu_opp (alu_opp),
		.s_axis_a_tdata   (driver_a_axis.tdata),
		.s_axis_a_tvalid  (driver_a_axis.tvalid),
		.s_axis_a_tready  (driver_a_axis.tready),
		
		.s_axis_b_tdata   (driver_b_axis.tdata),
		
		.m_axis_result_tdata  (monitor_axis.tdata),
		.m_axis_result_tvalid (monitor_axis.tvalid)
	);
	
	// CLOCK
	initial begin
		aclk = 0;
		forever #5 aclk = !aclk;
	end
	
	// RESET
	initial begin
		aresetn = 0;
		#RSTN_HIGH_t aresetn = 1;
	end
	
	// Drive
	initial begin
		driver_a_axis.m_init();
		driver_b_axis.m_init();
		
		wait(aresetn);
		driver_b_axis.tready = 1;
		
		// SUM
		alu_opp = SUM;
		fork
		driver_a_axis.sendSingleData(A);
		driver_b_axis.sendSingleData(B);
		join
		
		// MULT
		alu_opp = MULT;
		fork
		driver_a_axis.sendSingleData(A);
		driver_b_axis.sendSingleData(B);
		join
		
		// DIV
		alu_opp = DIV;
		fork
		driver_a_axis.sendSingleData(A);
		driver_b_axis.sendSingleData(B);
		join
	end
	
	//Monitor
	initial begin
		repeat(3) begin
			wait(monitor_axis.tvalid);
			$display(">>>>>>> Result: %d", monitor_axis.tdata);
			wait(!monitor_axis.tvalid);
		end
		$finish;
	end

endmodule