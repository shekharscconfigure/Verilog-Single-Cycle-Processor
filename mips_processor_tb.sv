`timescale 1ns/1ns
module tb_mips_proc();    
      // Inputs  
      reg clk;  
      reg reset;        
      // Instantiate the Design Inder Test DUT
      MIPS_PROCESSOR dut (  
           .clock(clk),   
           .reset(reset)
            );  
      initial begin  
        $dumpfile("dump.vcd"); $dumpvars;
           clk = 0;  
           forever #10 clk = ~clk;  
      end  
      initial
      begin 
      reset = 1; 
      # 20; 
      reset = 0;
      end
      initial begin  
           // Initialize Inputs  
      end  
      initial 
      begin	
       #1000;
       $finish;
      end 
 endmodule