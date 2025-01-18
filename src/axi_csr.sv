
`include "defines.sv"

	module axi_csr #
	(
		// Width of S_AXI data bus
		parameter integer C_S_AXI_DATA_WIDTH	= `DATA_WIDTH,
		// Width of S_AXI address bus
		parameter integer C_S_AXI_ADDR_WIDTH	= `CSR_ADDR_WIDTH
	)
	(
		//-----------------------------------------------------------------------------------------------
		output wire [7:0] kernel_size, 	
		output wire [7:0] stride, 		
		output wire [7:0] padding, 	
		output wire has_bias,
		output wire has_relu,
		output wire conv_mode,
		output wire start,
		output wire [`DATA_RANGE] kernel_baseaddr,
		output wire [`DATA_RANGE] feature_baseaddr,
		output wire [`DATA_RANGE] feature_width,
		output wire [`DATA_RANGE] feature_height,
		output wire [`DATA_RANGE] feature_chin,
		output wire [`DATA_RANGE] feature_chout,
		output wire [`DATA_RANGE] output_baseaddr,
		output wire [`DATA_RANGE] output_width,
		output wire [`DATA_RANGE] output_height,
		//###############################################################################################
		input wire running,
		input wire compute_done,
		input wire exception,
		//-----------------------------------------------------------------------------------------------
		// Global Clock Signal
		input wire  S_AXI_ACLK,
		// Global Reset Signal. This Signal is Active LOW
		input wire  S_AXI_ARESETN,
		// Write address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
		// Write channel Protection type. This signal indicates the
    		// privilege and security level of the transaction, and whether
    		// the transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_AWPROT,
		// Write address valid. This signal indicates that the master signaling
    		// valid write address and control information.
		input wire  S_AXI_AWVALID,
		// Write address ready. This signal indicates that the slave is ready
    		// to accept an address and associated control signals.
		output wire  S_AXI_AWREADY,
		// Write data (issued by master, acceped by Slave) 
		input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
		// Write strobes. This signal indicates which byte lanes hold
    		// valid data. There is one write strobe bit for each eight
    		// bits of the write data bus.    
		input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		// Write valid. This signal indicates that valid write
    		// data and strobes are available.
		input wire  S_AXI_WVALID,
		// Write ready. This signal indicates that the slave
    		// can accept the write data.
		output wire  S_AXI_WREADY,
		// Write response. This signal indicates the status
    		// of the write transaction.
		output wire [1 : 0] S_AXI_BRESP,
		// Write response valid. This signal indicates that the channel
    		// is signaling a valid write response.
		output wire  S_AXI_BVALID,
		// Response ready. This signal indicates that the master
    		// can accept a write response.
		input wire  S_AXI_BREADY,
		// Read address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
		// Protection type. This signal indicates the privilege
    		// and security level of the transaction, and whether the
    		// transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_ARPROT,
		// Read address valid. This signal indicates that the channel
    		// is signaling valid read address and control information.
		input wire  S_AXI_ARVALID,
		// Read address ready. This signal indicates that the slave is
    		// ready to accept an address and associated control signals.
		output wire  S_AXI_ARREADY,
		// Read data (issued by slave)
		output reg [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
		// Read response. This signal indicates the status of the
    		// read transfer.
		output wire [1 : 0] S_AXI_RRESP,
		// Read valid. This signal indicates that the channel is
    		// signaling the required read data.
		output wire  S_AXI_RVALID,
		// Read ready. This signal indicates that the master can
    		// accept the read data and response information.
		input wire  S_AXI_RREADY
	);

	// AXI4LITE signals
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
	reg  	axi_awready;
	reg  	axi_wready;
	reg [1 : 0] 	axi_bresp;
	reg  	axi_bvalid;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	reg  	axi_arready;
	reg [1 : 0] 	axi_rresp;
	reg  	axi_rvalid;

	// Example-specific design signals
	// local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	// ADDR_LSB is used for addressing 32/64 bit registers/memories
	// ADDR_LSB = 2 for 32 bits (n downto 2)
	// ADDR_LSB = 3 for 64 bits (n downto 3)
	localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
	localparam integer OPT_MEM_ADDR_BITS = 3;
	//----------------------------------------------
	//-- Signals for user logic register space
	//------------------------------------------------
	reg [7:0] 	kernel_size_r;
	reg [7:0] 	stride_r;
	reg [7:0] 	padding_r;
	reg 		has_bias_r;
	reg 		has_relu_r;
	reg 		conv_mode_r;
	reg  		start_r;	// auto-clear
	reg [C_S_AXI_DATA_WIDTH-1:0]	kernel_baseaddr_r;
	reg [C_S_AXI_DATA_WIDTH-1:0]	feature_baseaddr_r;
	reg [C_S_AXI_DATA_WIDTH-1:0]	feature_width_r;
	reg [C_S_AXI_DATA_WIDTH-1:0]	feature_height_r;
	reg [C_S_AXI_DATA_WIDTH-1:0]	feature_chin_r;
	reg [C_S_AXI_DATA_WIDTH-1:0]	feature_chout_r;
	reg [C_S_AXI_DATA_WIDTH-1:0]	output_baseaddr_r;
	reg [C_S_AXI_DATA_WIDTH-1:0]	output_width_r;
	reg [C_S_AXI_DATA_WIDTH-1:0]	output_height_r;
	integer	 byte_index;

	// I/O Connections assignments

	assign S_AXI_AWREADY	= axi_awready;
	assign S_AXI_WREADY	= axi_wready;
	assign S_AXI_BRESP	= axi_bresp;
	assign S_AXI_BVALID	= axi_bvalid;
	assign S_AXI_ARREADY	= axi_arready;
	assign S_AXI_RRESP	= axi_rresp;
	assign S_AXI_RVALID	= axi_rvalid;
	 //state machine varibles 
	 reg [1:0] state_write;
	 reg [1:0] state_read;
	 //State machine local parameters
	 localparam Idle = 2'b00,Raddr = 2'b10,Rdata = 2'b11 ,Waddr = 2'b10,Wdata = 2'b11;
	// Implement Write state machine
	// Outstanding write transactions are not supported by the slave i.e., master should assert bready to receive response on or before it starts sending the new transaction
	always @(posedge S_AXI_ACLK)                                 
	  begin                                 
	     if (S_AXI_ARESETN == 1'b0)                                 
	       begin                                 
	         axi_awready <= 0;                                 
	         axi_wready <= 0;                                 
	         axi_bvalid <= 0;                                 
	         axi_bresp <= 0;                                 
	         axi_awaddr <= 0;                                 
	         state_write <= Idle;                                 
	       end                                 
	     else                                  
	       begin                                 
	         case(state_write)                                 
	           Idle:                                      
	             begin                                 
	               if(S_AXI_ARESETN == 1'b1)                                  
	                 begin                                 
	                   axi_awready <= 1'b1;                                 
	                //    axi_wready <= ~running; 
					   axi_wready <= '0;                                
	                   state_write <= Waddr;                                 
	                 end                                 
	               else state_write <= state_write;                                 
	             end                                 
	           Waddr:                                       
	             begin                                 
	               if (S_AXI_AWVALID && S_AXI_AWREADY)                                 
	                  begin                                 
	                    axi_awaddr <= S_AXI_AWADDR;                                 
	                    // if(S_AXI_WVALID)                                  
	                    //   begin                                   
	                    //     axi_awready <= 1'b1;                                 
	                    //     state_write <= Waddr;                                 
	                    //     axi_bvalid <= 1'b1;                                 
	                    //   end                                 
	                    // else                                  
	                    //   begin                                 
	                    //     axi_awready <= 1'b0;                                 
	                    //     state_write <= Wdata;                                 
	                    //     if (S_AXI_BREADY && axi_bvalid) axi_bvalid <= 1'b0;                                 
	                    //   end    
						axi_awready <= 1'b0;                                 
	                    state_write <= Wdata;
						axi_wready <= '1;
						if (S_AXI_BREADY && axi_bvalid) axi_bvalid <= 1'b0;                             
	                  end                                 
	               else                                  
	                  begin                                 
	                    state_write <= state_write;                                 
	                    if (S_AXI_BREADY && axi_bvalid) axi_bvalid <= 1'b0;                                 
	                   end                                 
	             end                                 
	          Wdata:                                      
	             begin                                 
	               if (S_AXI_WVALID)                                 
	                 begin                                 
	                   state_write <= Waddr;
					   axi_wready <= '0;                                  
	                   axi_bvalid <= 1'b1;                                 
	                   axi_awready <= 1'b1;                                 
	                 end                                 
	                else                                  
	                 begin                                 
	                   state_write <= state_write;                                 
	                   if (S_AXI_BREADY && axi_bvalid) axi_bvalid <= 1'b0;                                 
	                 end                                              
	             end                                 
	          endcase                                 
	        end                                 
	      end                                 

	// Implement memory mapped register select and write logic generation
	// The write data is accepted and written to memory mapped registers when
	// axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
	// select byte enables of slave registers while writing.
	// These registers are cleared when reset (active low) is applied.
	// Slave register write enable is asserted when valid address and data are available
	// and the slave is ready to accept the write address and write data.
	 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
		  kernel_size_r	<= '0;
		  stride_r 		<= '0;
		  padding_r 	<= '0;
		  has_bias_r 	<= '0;
		  has_relu_r	<= '0;
		  conv_mode_r	<= '0;
		  start_r 		<= '0;
	      kernel_baseaddr_r 	<= '0;
	      feature_baseaddr_r 	<= '0;
	      feature_width_r 		<= '0;
	      feature_height_r 		<= '0;
	      feature_chin_r 		<= '0;
	      feature_chout_r 		<= '0;
	      output_baseaddr_r 	<= '0;
	      output_width_r 		<= '0;
	      output_height_r 		<= '0;
	    end 
	  else if (S_AXI_WVALID && S_AXI_WREADY)
  	      begin
	        case ( (S_AXI_AWVALID) ? S_AXI_AWADDR[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] : axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	          4'h0: begin
				start_r <= S_AXI_WDATA[0];
				// BITS[4:1] READ ONLY
				conv_mode_r <= S_AXI_WDATA[5];
				has_relu_r <= S_AXI_WDATA[6];
				has_bias_r <= S_AXI_WDATA[7];
				padding_r <= S_AXI_WDATA[15:8];
				stride_r <= S_AXI_WDATA[23:16];
				kernel_size_r <= S_AXI_WDATA[31:24];
			  end
					
	          4'h1: begin
				start_r 		<= 1'b0;
				for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 1
	                kernel_baseaddr_r[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end 
			  end
	             
	          4'h2: begin
				start_r 		<= 1'b0;
				for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 2
	                feature_baseaddr_r[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
			  end
	            
	          4'h3: begin
				start_r 		<= 1'b0;
				for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 3
	                feature_width_r[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end 
			  end
	             
	          4'h4: begin
				start_r 		<= 1'b0;
				for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 4
	                feature_height_r[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end 
			  end
	             
	          4'h5: begin
				start_r 		<= 1'b0;
				for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 5
	                feature_chin_r[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
			  end
	            
	          4'h6: begin
				start_r 		<= 1'b0;
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 6
	                feature_chout_r[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end 
		        end
	          4'h7: begin
	            start_r 		<= 1'b0;
				for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 7
	                output_baseaddr_r[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end 
			    end 
	          4'h8: begin
				start_r 		<= 1'b0;
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 8
	                output_width_r[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
			    end
	          4'h9: begin
				start_r 		<= 1'b0;
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 9
	                output_height_r[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
			  	end
	          default : begin
	                      kernel_size_r	<= kernel_size_r;
						  stride_r 		<= stride_r;
						  padding_r 	<= padding_r;
						  has_bias_r 	<= has_bias_r;
						  has_relu_r	<= has_relu_r;
						  conv_mode_r	<= conv_mode_r;
						  start_r 		<= 1'b0;
	                      kernel_baseaddr_r 	<= kernel_baseaddr_r;
	                      feature_baseaddr_r 	<= feature_baseaddr_r;
	                      feature_width_r 		<= feature_width_r;
	                      feature_height_r 		<= feature_height_r;
	                      feature_chin_r 		<= feature_chin_r;
	                      feature_chout_r 		<= feature_chout_r;
	                      output_baseaddr_r 	<= output_baseaddr_r;
	                      output_width_r 		<= output_width_r;
	                      output_height_r 		<= output_height_r;
	                    end
	        endcase
	      end
		else begin
			kernel_size_r	<= kernel_size_r;
			stride_r 		<= stride_r;
			padding_r 		<= padding_r;
			has_bias_r 		<= has_bias_r;
			has_relu_r		<= has_relu_r;
			conv_mode_r		<= conv_mode_r;
			start_r 		<= 1'b0;
			kernel_baseaddr_r 		<= kernel_baseaddr_r;
			feature_baseaddr_r 		<= feature_baseaddr_r;
			feature_width_r 		<= feature_width_r;
			feature_height_r 		<= feature_height_r;
			feature_chin_r 			<= feature_chin_r;
			feature_chout_r 		<= feature_chout_r;
			output_baseaddr_r 		<= output_baseaddr_r;
			output_width_r 			<= output_width_r;
			output_height_r 		<= output_height_r;
		end
	end    

	// Implement read state machine
	  always @(posedge S_AXI_ACLK)                                       
	    begin                                       
	      if (S_AXI_ARESETN == 1'b0)                                       
	        begin                                       
	         //asserting initial values to all 0's during reset                                       
	         axi_arready <= 1'b0;                                       
	         axi_rvalid <= 1'b0;                                       
	         axi_rresp <= 1'b0;                                       
	         state_read <= Idle;                                       
	        end                                       
	      else                                       
	        begin                                       
	          case(state_read)                                       
	            Idle:     //Initial state inidicating reset is done and ready to receive read/write transactions                                       
	              begin                                                
	                if (S_AXI_ARESETN == 1'b1)                                        
	                  begin                                       
	                    state_read <= Raddr;                                       
	                    axi_arready <= 1'b1;                                       
	                  end                                       
	                else state_read <= state_read;                                       
	              end                                       
	            Raddr:        //At this state, slave is ready to receive address along with corresponding control signals                                       
	              begin                                       
	                if (S_AXI_ARVALID && S_AXI_ARREADY)                                       
	                  begin                                       
	                    state_read <= Rdata;                                       
	                    axi_araddr <= S_AXI_ARADDR;                                       
	                    axi_rvalid <= 1'b1;                                       
	                    axi_arready <= 1'b0;                                       
	                  end                                       
	                else state_read <= state_read;                                       
	              end                                       
	            Rdata:        //At this state, slave is ready to send the data packets until the number of transfers is equal to burst length                                       
	              begin                                           
	                if (S_AXI_RVALID && S_AXI_RREADY)                                       
	                  begin                                       
	                    axi_rvalid <= 1'b0;                                       
	                    axi_arready <= 1'b1;                                       
	                    state_read <= Raddr;                                       
	                  end                                       
	                else state_read <= state_read;                                       
	              end                                       
	           endcase                                       
	          end                                       
	        end                                         
	// Implement memory mapped register select and read logic generation
	always @* begin
		case (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB])
			4'd0:
				S_AXI_RDATA = {kernel_size_r, stride_r, padding_r, has_bias_r, has_relu_r, conv_mode_r, 1'b0, running, compute_done, exception, start_r};
			4'd1:
				S_AXI_RDATA = kernel_baseaddr_r;
			4'd2:
				S_AXI_RDATA = feature_baseaddr_r;
			4'd3:
				S_AXI_RDATA = feature_width_r;
			4'd4:
				S_AXI_RDATA = feature_height_r;
			4'd5:
				S_AXI_RDATA = feature_chin_r;
			4'd6:
				S_AXI_RDATA = feature_chout_r;
			4'd7:
				S_AXI_RDATA = output_baseaddr_r;
			4'd8:
				S_AXI_RDATA = output_width_r;
			4'd9:
				S_AXI_RDATA = output_height_r;
			default: 
				S_AXI_RDATA = 0;
		endcase
	end
	
	//-----------------------------------------------------------------------------------------------
	//# OUTPUT ASSIGNMENT
	assign kernel_size = kernel_size_r;
	assign stride = stride_r;
	assign padding = padding_r;
	assign has_bias = has_bias_r;
	assign has_relu = has_relu_r;
	assign conv_mode = conv_mode_r;
	assign start = start_r;
	assign kernel_baseaddr = kernel_baseaddr_r;
	assign feature_baseaddr = feature_baseaddr_r;
	assign feature_width = feature_width_r;
	assign feature_height = feature_height_r;
	assign feature_chin = feature_chin_r;
	assign feature_chout = feature_chout_r;
	assign output_baseaddr = output_baseaddr_r;
	assign output_width = output_width_r;
	assign output_height = output_height_r;
	//-----------------------------------------------------------------------------------------------

	endmodule
