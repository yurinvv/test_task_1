interface dut_if #(
	parameter DATA_WIDTH = 32,
	parameter ALU_OPP_WIDTH = 2
)(
	input bit aclk,
	input bit aresetn
);

	logic [DATA_WIDTH - 1 : 0]   f1_tdata;	
	logic [DATA_WIDTH - 1 : 0]   f2_tdata;
	logic [DATA_WIDTH - 1 : 0]   k_tdata;
	logic                        k_tvalid;
	logic                        k_tready;	
	logic                        ind_tready; 
	logic                        ind_tvalid;
	logic [DATA_WIDTH - 1 : 0]   ind_tdata;
	logic                        ind_tuser;   // Start of vector 
	logic                        ind_tlast;    // End of vector

	
/*
	clocking cb @(posedge aclk);
		default input #1step output #2ns;
		output f1_tdata;	
		output f2_tdata;
		output k_tdata;
		output k_tvalid;
		output ind_tready;
		
		input  k_tready;
		input  ind_tvalid;
		input  ind_tdata;
		input  ind_tuser; 
		input  ind_tlast; 
	endclocking
	*/
	task initSlaveSignals();
		f1_tdata = 0;	
		f2_tdata = 0;
		k_tdata  = 0;
		k_tvalid = 0;
		ind_tready = 0;
	endtask;
	
	////////////////////////////////////
	// Send method
	task sendConstatnts (input bit[DATA_WIDTH - 1 : 0] f1, f2, k);
		//@(posedge cb);
		@(posedge aclk);
		k_tvalid <= 1;
		k_tdata  <= k;
		f1_tdata <= f1;
		f2_tdata <= f2;
		wait(k_tready);
		//@(posedge cb);
		@(posedge aclk);
		k_tvalid <= 0;
	endtask
	
	///////////////////////////////////
	// Receive method
	task receiveData (
		output bit sov,
		output bit [DATA_WIDTH - 1 : 0] data,
		output bit eov
		);
	//@(posedge cb);	
	@(posedge aclk);
	ind_tready <= 1;
	wait(ind_tvalid);
	//@(posedge cb);
	@(posedge aclk);
	data <= ind_tdata;
	sov  <= ind_tuser;
	eov  <= ind_tlast;
	//@(posedge cb);	
	ind_tready <= 0;
	@(posedge aclk);
	endtask
	
endinterface