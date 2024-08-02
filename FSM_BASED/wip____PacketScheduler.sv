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
            O_valid<=0;
            O_current_type <= '0;        
        end 
      else begin
            //CSTATE <= i_valid ? NSTATE : CSTATE;
            CSTATE <= NSTATE;
        case(NSTATE)
            IDLE: begin r_voip_count <= '0; r_data_count <= '0; O_valid<= '0; O_current_type<='0; end
            STREAMING: begin /*r_byte_count <= '0;*/   
              r_data <= data_in;
              r_valid <= i_valid;
              
              O_valid <= i_valid;
              O_current_type <= i_valid ? 2'b01 : 2'b00;              
            end 
            VOIP: begin 
              r_voip_count <= w_voip_done ? '0 : i_valid && (stream_type==2'd0) ? r_voip_count + 1 : r_voip_count;
              voip_buffer[r_voip_count*8 +: 8] <= i_valid ? data_in : voip_buffer[r_voip_count*8 +: 8];
              O_valid <= (r_voip_count == 7) && i_valid ? 1'b1 : 0;
              O_current_type <= (r_voip_count == 7) && i_valid ? 2'b00 : 2'b00;
              
            end 
            DATA: begin 
              r_data_count <= w_data_done ? '0 : i_valid && (stream_type==2'd2) ? r_data_count + 1 : r_data_count;
              data_buffer[r_data_count*8 +: 8] <= i_valid ? data_in : data_buffer[r_data_count*8 +: 8];    
              O_valid <= (r_data_count == 15) && i_valid ? 1'b1 : 0;
              O_current_type <= (r_data_count == 15) && i_valid ? 2'b10 : 2'b00;              
            end 
          endcase
        end
    end

    always_comb begin
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
              if(i_valid && stream_type==2'b01) begin 
                NSTATE = STREAMING;
              end 
              else if(i_valid && stream_type==2'b10) begin 
                NSTATE = DATA;
              end 
            
              else if (!i_valid && O_valid) 
                NSTATE = IDLE;
           
              else /*if (i_valid && stream_type==2'b00) */begin                 
                    NSTATE = VOIP;
              end  
            end 
        
            STREAMING: begin  
              if(i_valid && stream_type==2'b00) begin 
                NSTATE = VOIP;
              end 
              else if(i_valid && stream_type==2'b10) begin 
                NSTATE = DATA;
              end 
              else if(i_valid && stream_type==2'b01) begin 
                NSTATE = STREAMING;
              end              
              else if (!i_valid && O_valid) begin 
                NSTATE = IDLE; 
              end
            end
        
            DATA: begin
              if(i_valid && stream_type==2'b00) begin 
                NSTATE = VOIP;
              end 
              else if(i_valid && stream_type==2'b01) begin 
                NSTATE = STREAMING;
              end              
              else if (!i_valid && O_valid) begin 
                NSTATE = IDLE;
              end
              else /*(i_valid && stream_type==2'b10) */begin
                    NSTATE = DATA;
              end        
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

    
  assign w_voip_done = i_valid && (CSTATE == VOIP) && (r_voip_count == 8'd7);
  assign w_data_done = i_valid && (CSTATE == DATA) && (r_data_count == 8'd15);
  assign O_data = (O_current_type == 2'h0) ? voip_buffer : (O_current_type == 2'h1) ? r_data : (O_current_type == 2'h2) ? data_buffer : '0;
  

endmodule

//+++++++++++++++++++++++++++++++++//
//++++++++++ Test Bench +++++++++++//
//+++++++++++++++++++++++++++++++++//
`timescale 1ns / 1ps

module tb_PacketScheduler;

  logic clk;
  logic reset;
  logic [1:0] stream_type;
  logic i_valid;
  logic [7:0] data_in;
  logic [127:0] O_data;
  logic O_valid;
  logic [1:0] O_current_type;

  // Instance of PacketScheduler
  PacketScheduler uut (
    .clk(clk),
    .reset(reset),
    .stream_type(stream_type),
    .i_valid(i_valid),
    .data_in(data_in),
    .O_data(O_data),
    .O_valid(O_valid),
    .O_current_type(O_current_type)
  );

  // Clock generation
  always #1 clk = ~clk; // 100MHz clock

  // Stimulus
  initial begin
    clk = 0;
    reset = 1;
    i_valid = 0;
    stream_type = 0;
    data_in = 0;
    #10;
    reset = 0;

    // Send VoIP data
    @(posedge clk);
    send_data(2'b00, 8'hAA);
    send_data(2'b00, 8'hBB);
    send_data(2'b00, 8'hCC);
    send_data(2'b00, 8'hDD);
    send_data(2'b00, 8'hEE);
    send_data(2'b00, 8'hFF);
    send_data(2'b00, 8'h11);
    send_data(2'b00, 8'h22);

    // Send Streaming data
    @(posedge clk);
    send_data(2'b01, 8'h99);

    // Send Data packets
    @(posedge clk);
    for (int i = 0; i < 16; i++) begin
      send_data(2'b10, $random % 256);
    end

    // Test quick switching between types
    @(posedge clk);
    send_data(2'b01, 8'h77);
    send_data(2'b00, 8'h88);
    send_data(2'b10, 8'h44);
    
    //DATA 
    @(posedge clk);
    for (int i = 0; i < 16; i++) begin
      send_data(2'b10, $random % 256);
    end
    
    //VOIP
    @(posedge clk);
    for (int i = 0; i < 20; i++) begin
      send_data(2'b00, $random % 256);
    end   
      
    //Stream
    for (int i = 0; i < 20; i++) begin
      send_data(2'b01, $random % 256);
    end   
    
    //VOIP
    for (int i = 0; i < 20; i++) begin
      send_data(2'b00, $random % 256);
    end       
    // Finish the test
    @(posedge clk);
    $finish;
  end

  // Task to send data
  task send_data(input logic[1:0] dtype, input logic[7:0] data);
    begin
      @(posedge clk);
      stream_type = dtype;
      data_in = data;
      i_valid = 1;
      //@(posedge clk);
      //i_valid = 0;  // Ensure only one valid clock cycle per data
    end
  endtask

  // Monitor outputs
  initial begin
    $monitor("Time=%t, State=%h, Input Valid=%b, Stream Type=%b, Data In=%h, Output Valid=%b, Output Data=%h, Output Type=%b",
              $time, uut.CSTATE, i_valid, stream_type, data_in, O_valid, O_data, O_current_type);
  end
  initial begin 
    $dumpvars();
  end 

endmodule


 
