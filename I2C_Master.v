module i2c_master(
		  i2c_scl_inout,
		  i2c_sda_inout,
		  addr,
		  data,
		  clk_in,
		  rst_in,
		  start,
		  ready_out,
		  read_write,
		  sda_in
		 );//PORT LIST

  //PORT DECLARATIONS
  inout i2c_scl_inout;
  input sda_in;
  output i2c_sda_inout;
  input [6:0]addr;
  input [7:0]data;
  input clk_in;
  input rst_in;
  input start;
  input read_write;
  output ready_out;
  

  //SIGNAL DECLARATIONS
  wire i2c_scl_inout;
  wire i2c_sda_inout;
 
  //INTERNAL REGISTERS
  reg [2:0] present_state;
  reg [2:0] next_state;
  reg [2:0] count;
  reg en;
  //reg sda_write;
  //reg sda_read;
  reg sda_out;
  reg sda_en;
  reg [6:0]Waddr_reg;
  reg [7:0]Wdata_reg;
  reg [7:0]Rdata_reg = 'b0;
  reg ack = 'b0;

  //PARAMETERS
  parameter [2:0] IDLE     = 'b000;
  parameter [2:0] START    = 'b001;
  parameter [2:0] ADDR     = 'b010;
  parameter [2:0] RW       = 'b011;
  parameter [2:0] ACK      = 'b100;
  parameter [2:0] DATA     = 'b101;
  parameter [2:0] ACK_2    = 'b110;
  parameter [2:0] STOP     = 'b111;
 
  //ASSIGN
  assign i2c_scl_inout = (en) ? clk_in : 1;
  assign i2c_sda_inout = (sda_en ) ? sda_out : sda_in;

  //PROCEDURAL BLOCK
  always@(posedge clk_in)begin
    if(rst_in)begin
      present_state <= IDLE;
      en 	    <= 'b0;
    end
    else begin
      present_state <= next_state;
      Waddr_reg <= addr;
      Wdata_reg <= data;
	if(present_state == ADDR)begin
	  count <= count - 1;
	end
	else if(present_state == DATA)begin
	  count <= count - 1;
	end
    end
  end
  
  always@(*)begin
    sda_en = 'b0;
    case(present_state)
     
    IDLE : begin
	      sda_en = 'b1;
	     en  = 'b0;
             next_state = START;
 	     sda_out    = 'b1;
	   end

   START : begin
   		  sda_en = 'b1;
	     en  = 'b1;
	     sda_out    = 'b0;
             next_state = ADDR;
             count = 6;
	   end
    
    ADDR :   begin
       	      sda_en = 'b1;
	      sda_out = Waddr_reg[count];
	       if(count == 0)begin
             next_state = RW;
	   end
	   else begin
		 sda_en    = 'b1;
		 next_state = ADDR;
	   end
	  end
      
    RW  : if(!read_write)begin
		sda_en     = 'b1;
	    next_state = ACK;
	    sda_out    = 'b0;
	  end
	  else if(read_write)begin
		sda_en     = 'b1;
		sda_out    = 'b1;
	    next_state = ACK;
	  end
 
   ACK  :  if(sda_in == 'b0)begin
	      count      = 7;
	      next_state = DATA;
	  end
	  else begin
	     next_state = STOP;
	  end
        
   DATA : if(!read_write)begin
	    sda_en = 'b1;
	    sda_out = Wdata_reg[count];
	    if(count == 0)begin
	      next_state = ACK_2;
	    end
	    else begin
	      next_state = DATA;
	    end
	   end
          else begin
	     sda_en  = 'b0;
	     Rdata_reg[count] = {sda_in};
	    if(count == 0)begin
	      next_state = ACK_2;
 	    end
	    else begin
              next_state = DATA;
	    end
	  end 

  ACK_2 : if(!read_write)begin
	    if(sda_in == 0)begin
              next_state = DATA;
	    end 
	    else begin 
             // sda_en = 'b1;
	      next_state = STOP;
            end
	  end
	  else begin
	  sda_en  = 'b0;
	    if(sda_in == 'b0)begin
	      next_state = DATA;
		end
	    else begin//sda_out = 'b1;
	      next_state = STOP;
		end
	  end
	    
  STOP : begin
  	   //sda_en     = 'b1;
	   //sda_out    = 'b1;
	   en         = 'b0;
	   next_state = IDLE;
	 end
  default : next_state = IDLE; 
  endcase
 end

endmodule
    
  
