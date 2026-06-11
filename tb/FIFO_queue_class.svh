`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/29/2026 03:13:10 PM
// Design Name: 
// Module Name: FIFO_queue_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


class FIFO_queue_class;

`ifdef READ_WRITE_IN_QUEUE_DEBUG
    `define VERBOSE_PRINT_ENABLED 1
`endif    
`define IF_DEBUG_PRINT_ENABLED if(`VERBOSE_PRINT_ENABLED)   

   import FIFO_queue_pkg::*;
   virtual FIFO_queue_bfm bfm;
 
 
 //TODO: fix parameters, use parameters delcared in inteface
 logic [DATA_WIDTH-1:0] queue_16x16 [$:FIFO_DEPTH];
 
 function new(virtual FIFO_queue_bfm bfm_constructor);
    bfm=bfm_constructor;
 endfunction: new


 
 function bit FIFO_full();
    bit full;
    full = (queue_16x16.size()>=FIFO_DEPTH)? 1'b1 : 1'b0; 
    return full;
 endfunction 
 
  function bit FIFO_empty();
    bit empty;
    empty = (queue_16x16.size()=='h0)? 1'b1 : 1'b0;
    return empty;
 endfunction 
 
// function void update_flags();
//    bfm.full = FIFO_full();
//    bfm.empty = FIFO_empty();
// endfunction
 
task update_flags();
        forever begin: update
            // ugly solution using both clock edges to update flags as fast as posible
//          @(posedge bfm.clk_a or negedge bfm.clk_a)bfm.full = FIFO_full();
//          @(posedge bfm.clk_b or negedge bfm.clk_b)bfm.empty = FIFO_empty();
            // ugly solution using a single simulation step to update flags as fast as posilbe . probably more reliable than using dual clock rate
            // TODO: find a better more standard (less tricky) way to update flags instantanously. like a combinatorial signal.
            #1 bfm.full = FIFO_full();
            #1 bfm.empty = FIFO_empty();
        end : update
endtask
  
 task execute();
    fork
        run_FIFO_write();
        run_FIFO_read();
        update_flags();
    join
endtask: execute
 
task run_FIFO_write();
    forever begin: write_fifo
    @(posedge bfm.clk_a);
    if(bfm.push)begin
        `IF_DEBUG_PRINT_ENABLED $display("%0t,attempting push data: %2h, size: %2d",$realtime,bfm.datain_a,queue_16x16.size());    
        if(!FIFO_full())begin//if(!bfm.full)begin
            queue_16x16.push_front(bfm.datain_a);
            `IF_DEBUG_PRINT_ENABLED $display("%0t,pushed data: %2h success, size: %2d",$realtime,bfm.datain_a,queue_16x16.size());
        end                    
    end
    end: write_fifo
endtask

task run_FIFO_read;
    forever begin: read_fifo 
//    @(posedge bfm.clk_b);
    #1 // ugly solution to instantaneous flag check for ideal behavior . without a delay simulation gets stuck TODO: find a standard solution for this problem 
    if(bfm.pop)begin
        `IF_DEBUG_PRINT_ENABLED $display("%0t,attempting pop data: %2h size: %2d",$realtime,bfm.dataout_b,queue_16x16.size());
        if(!FIFO_empty())begin//if(!bfm.empty)begin
            @(posedge bfm.clk_b);
            bfm.dataout_b=queue_16x16.pop_back();
            `IF_DEBUG_PRINT_ENABLED $display("%0t,popped data: %2h size: %2d",$realtime,bfm.dataout_b,queue_16x16.size());
        end
    end
    end: read_fifo
endtask
 

endclass
