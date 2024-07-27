/*
Create a SystemVerilog module for a network packet scheduler that uses an FSM to manage packet queuing and transmission based on priority and type. The FSM should handle different network conditions dynamically.

Specifications:

Multiple queues for different types of traffic (e.g., VoIP, streaming, data).
Dynamic adjustment based on bandwidth availability.
Error handling for packet loss or corruption.
States to manage congestion and optimize throughput.
Prioritization mechanism for critical data packets.
*/
//WIP - ERROR, CONGESTION is remaining , 

//immediate transition to other steam_type shd work



module PacketScheduler(
    input logic clk,
    input logic reset,
    input logic[1:0] stream_type,  // 2-bit signal for data type
    input i_valid,
    input logic[7:0] data_in,      // Incoming data byte
  output logic[127:0] O_data,    // Outgoing data packet
    output logic O_valid,         // Signal to indicate data out is valid
  output logic [1:0] O_current_type
);

    typedef enum logic[2:0] {
        IDLE = 3'b000,
        VOIP = 3'b001,      
        STREAMING = 3'b010,
        DATA = 3'b011
        //ERROR = 3'b100,
        //CONGESTION = 3'b101
    } state_t;

    state_t CSTATE, NSTATE;

    // Data buffers for accumulation
    logic[63:0] voip_buffer;
    logic[127:0] data_buffer;
  logic [7:0] r_voip_count;
  logic [7:0] r_data_count,r_data,r_data_d1;
  logic w_voip_done,w_data_done,r_valid;
  logic w_valid_out,r_valid_out;
  logic [1:0] w_current_type;
  logic [1:0] r_current_type;  

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            CSTATE <= IDLE;
            r_voip_count <= 0;
            r_data_count <= 0;
            voip_buffer <= 0;
            data_buffer <= 0;
            r_valid <= 0;
            r_data <= '0;
            r_data_d1 <= '0;
            //data_out <= '0; // Send byte by byte
            //valid_out <= '0;           
        end 
      else begin
            //CSTATE <= i_valid ? NSTATE : CSTATE;
            CSTATE <= NSTATE;
            r_valid <= i_valid;
            r_data <= data_in;
          case(CSTATE)
            IDLE: begin r_voip_count <= '0; r_data_count <= '0; end
            STREAMING: begin /*r_byte_count <= '0;*/ 
            //data_out <= r_data; // Send byte by byte
            //valid_out <= r_valid;    
              r_data_d1 <= r_data;
            end 
            VOIP: begin 
              r_voip_count <= w_voip_done ? '0 : i_valid && (stream_type==2'd0) ? r_voip_count + 1 : r_voip_count;
              voip_buffer[r_voip_count*8 +: 8] <= r_valid ? r_data : voip_buffer[r_voip_count*8 +: 8];
              //data_out  <= w_voip_done ? voip_buffer : '0;  
              //valid_out <= w_voip_done; 
            end 
            DATA: begin 
              r_data_count <= w_data_done ? '0 : i_valid && (stream_type==2'd2) ? r_data_count + 1 : r_data_count;
              data_buffer[r_data_count*8 +: 8] <= r_valid ? r_data : data_buffer[r_data_count*8 +: 8];
              //data_out <= w_data_done ? data_buffer : '0; // Send all at once
              //valid_out <= w_data_done;              
            end 
          endcase
        end
    end

    always_comb begin
        //valid_out = 0;
        //data_out = 8'b0;
        //voip_buffer = '0;
        //data_buffer = '0;
      //NSTATE = state_t'('0);
      case (CSTATE)
            IDLE: begin
              //valid_out = 0;
              case ({stream_type,i_valid})
                    3'b001: NSTATE = VOIP;
                    3'b011: NSTATE = STREAMING;
                    3'b101: NSTATE = DATA;
                    default: NSTATE = IDLE;
                endcase
            end
            VOIP: begin
              //voip_buffer[r_byte_count*8 +: 8] = data_in;
                //byte_count++;
              //valid_out = 0;
              if ((r_voip_count == 7) && r_valid) begin
                    //data_out = voip_buffer; // Send all at once
                    //valid_out = 1;                    
                    NSTATE = IDLE;
                end
              else if(r_valid && stream_type==2'b01) begin 
                NSTATE = STREAMING;
              end 
              else if(r_valid && stream_type==2'b10) begin 
                NSTATE = DATA;
              end 
              else 
                NSTATE = VOIP;
            end
            STREAMING: begin
                //data_out = data_in; // Send byte by byte
                //valid_out = 1;
                //NSTATE = IDLE;
              if(i_valid && stream_type==2'b01) begin 
                NSTATE = STREAMING;
                //data_out = data_in; // Send byte by byte
                //valid_out = 1;
              end  
              else if(i_valid && stream_type==2'b00) begin 
                NSTATE = VOIP;
              end 
              else if(i_valid && stream_type==2'b10) begin 
                NSTATE = DATA;
              end 
              else 
                NSTATE = STREAMING; 
            end
            DATA: begin
              //data_buffer[r_byte_count*8 +: 8] = data_in;
              //valid_out = 0;
                //byte_count++;
              if ((r_data_count == 15) && r_valid) begin
                    //data_out = data_buffer; // Send all at once
                    //valid_out = 1;
                    //r_byte_count = 0;
                    NSTATE = IDLE;
                end
              else if(r_valid && stream_type==2'b00) begin 
                NSTATE = VOIP;
              end 
              else if(r_valid && stream_type==2'b01) begin 
                NSTATE = STREAMING;
              end 
              else 
                NSTATE = DATA;
            end
          /*
            ERROR: begin
                // Handle error
                next_state = IDLE;
            end
            CONGESTION: begin
                // Adjust sending logic based on congestion
                next_state = IDLE;
            end
            */
        endcase
    end
  always_ff @(posedge clk)begin 
    if(reset) begin 
      r_valid_out <= '0;
      r_current_type <= '0;
    end 
    else if (w_valid_out ^ r_valid_out)  begin 
      r_valid_out <= w_valid_out;
      r_current_type <= w_current_type;
    end 
  end 
    
  assign w_voip_done = (CSTATE == VOIP) && (r_voip_count == 8'd7);
  assign w_data_done = (CSTATE == DATA) && (r_data_count == 8'd15);
  //assign O_data = (CSTATE == VOIP) ? voip_buffer : (CSTATE == DATA) ? data_buffer : (CSTATE == STREAMING) ? r_data : '0;
  assign O_data = (O_current_type == 2'h0) ? voip_buffer : (O_current_type == 2'h1) ? r_data_d1 : (O_current_type == 2'h2) ? data_buffer : '0;
  assign w_valid_out = (CSTATE == VOIP) ? w_voip_done : (CSTATE == DATA) ? w_data_done : (CSTATE == STREAMING) ? r_valid : 1'd0;
  assign w_current_type = ((CSTATE == VOIP) && w_voip_done) ? 2'd0 : ((CSTATE == STREAMING) && r_valid) ? 2'd1 : ((CSTATE == DATA) && w_data_done) ? 2'd2 : 2'd0;
  assign O_valid = (CSTATE == STREAMING) ? r_valid :  r_valid_out;
  assign O_current_type = (CSTATE == STREAMING) ? w_current_type : r_current_type; //for streaming the 1 clk delay isnt req

endmodule