// Code your design here
`timescale 1ns/1ns
//MIPS PROCESSOR
module MIPS_PROCESSOR(clock,reset);
  input clock;
  input reset;
  wire [31:0] _pcout;
  wire [31:0] _Instruction;
  wire [31:0] _ReadData1;
  wire [31:0] _ReadData2;
  wire _RegDst,_Branch,_MemRead,_MemtoReg,_MemWrite,_ALUSrc,_RegWrite,_Jump;
  wire [1:0] _ALUOp;
  wire [31:0] _sign_out;
  wire [31:0] _shift_out;
  wire [31:0] _sum_pcplus4;
  wire [31:0] _sum_branchadder;
  wire _sel_regfiledest;
  wire [31:0] _mux_out_alusrc;
  wire _sel_alusrc;
  wire [31:0] _mux_out_branchornot;
  wire [31:0] _mux_out_branchornot_addr;
  wire _sel_branchornot;
  wire [31:0] _mux_out_regfiledata;
  wire [4:0] _mux_out_regfiledest_5b;
  wire [5:0] _ALUControl;
  wire [31:0] _ReadData;
  wire [31:0] _ALUresult;
  wire [31:0] _isZero;
  
  
  PROGRAM_COUNTER model_pc(.clock(clock),.reset(reset),.pcin(_mux_out_branchornot_addr),.pcout(_pcout));
  INSTRUCTION_MEMORY model_instructionmemory(.Read_Addr(_pcout),.Instruction(_Instruction));
  REGISTERS model_registers(.clk(clock),.Read_Register1(_Instruction[25:21]),.Read_Register2(_Instruction[20:16]),.Write_Register(_mux_out_regfiledest_5b),.WriteData_reg(_mux_out_regfiledata),.Reg_Write(_RegWrite),.Read_Data1(_ReadData1),.Read_Data2(_ReadData2));
  CONTROL model_control(.opcode(_Instruction[31:26]),.Reg_Dst(_RegDst),.Jump(_Jump),.Branch(_Branch),.Mem_Read(_MemRead),.MemtoReg(_MemtoReg),.ALU_Op(_ALUOp),.Mem_Write(_MemWrite),.ALU_Src(_ALUSrc),.Reg_Write(_RegWrite));
  SIGN_EXTEND model_signextend( .sign_in(_Instruction[15:0]), .sign_out(_sign_out) );
  SHIFT_LEFT model_shiftleft( .shift_in(_sign_out), .shift_out(_shift_out) );
  ADDER model_add_pc_plus4(.data1(_pcout), .data2(32'b100), .sum(_sum_pcplus4));
  ADDER model_add_branchadder(.data1(_sum_pcplus4), .data2(_shift_out), .sum(_sum_branchadder));
  MUX_2x1 model_mux_regfiledest( .mux_in_1({27'b0,_Instruction[20:16]}), .mux_in_2({27'b0,_Instruction[15:11]}), .sel(_RegDst), .mux_out(_mux_out_regfiledest_5b) );
  MUX_2x1 model_mux_alusrc( .mux_in_1(_ReadData2), .mux_in_2(_sign_out), .sel(_ALUSrc), .mux_out(_mux_out_alusrc) );
  and_gate a(_Branch,_isZero,_sel_branchornot);
  MUX_2x1 model_mux_branchornot( .mux_in_1(_sum_pcplus4), .mux_in_2(_sum_branchadder), .sel(_sel_branchornot), .mux_out(_mux_out_branchornot) );
  MUX_2x1 model_mux_branchornot_addr( .mux_in_1(_mux_out_branchornot), .mux_in_2({_sum_pcplus4[31:28],_Instruction[25:0],2'b00}), .sel(_Jump), .mux_out(_mux_out_branchornot_addr) );
  MUX_2x1 model_mux_regfiledata( .mux_in_1(_ReadData), .mux_in_2(_ALUresult), .sel(_MemtoReg), .mux_out(_mux_out_regfiledata) );
  ALU_CONTROL model_alucontrol( .ALU_Op(_ALUOp), .Funct(_Instruction[5:0]), .ALU_Control(_ALUControl) );
  DATA_MEMORY model_datamemory(.Addr(_ALUresult),.Mem_Write(_MemWrite),.Mem_Read(_MemRead),.Write_Data(_ReadData2),.Read_Data(_ReadData));
  ALU model_alu( .Read_data_1(_ReadData1), .Read_data_2(_mux_out_alusrc), .ALU_Control(_ALUControl), .ALU_result(_ALUresult),.is_Zero(_isZero) );
endmodule

//PROGRAM COUNTER
module PROGRAM_COUNTER(clock,reset,pcin,pcout);
  input clock;
  input reset;
  input [31:0] pcin;
  output [31:0] pcout;
  reg [31:0] pcout=0;
     always @(posedge clock, posedge reset)
       if (reset)
       pcout<=0;
       else 
       pcout <=pcin;
endmodule


//INSTRUCTION MEMORY
module INSTRUCTION_MEMORY(Read_Addr,Instruction);
  input [31:0] Read_Addr;
  output [31:0] Instruction;
  reg [31:0] Instruction;
  reg [31:0] IMEM[0:63];
     integer i;
     initial begin
           IMEM[0]<= 32'b00000000010000110000000000000010;
           IMEM[1]<= 32'b00000000010000110000000000000010;
           IMEM[2]<= 32'b10000100010000110000000000000010;
           IMEM[3]<= 32'b10001000010000110000000000000010;
           IMEM[4]<= 32'b10001100010000110000000000000010;
           IMEM[5]<= 32'b11001100010000110000000000000010;
           IMEM[6]<= 32'b10010100010000110000000000000010;
     for(i=7;i<64;i=i+1)
     IMEM[i]='b0;
     end
     
     always @(Read_Addr)
       Instruction<=IMEM[Read_Addr/4];
endmodule

//DATA MEMORY
module DATA_MEMORY(Addr,Mem_Write,Mem_Read,Write_Data,Read_Data);
   input [31:0] Addr;
   input Mem_Write;
   input Mem_Read;
   input [31:0] Write_Data;
   output [31:0] Read_Data;
   reg [31:0] Read_Data=0;
   reg [31:0] RAM[0:63];
   integer i,j;
   initial
   begin
   for(i=0;i<64;i=i+1)
   for(j=0;j<32;j=j+1)
   RAM[i][j]<=0;
         RAM[0] <= 32'b00000000000000000000000000000001;
         RAM[1] <= 32'b00000000000000000000000000000010;
         RAM[2] <= 32'b00000000000000000000000000000011;
         RAM[3] <= 32'b00000000000000000000000000000100;
         RAM[4] <= 32'b00000000000000000000000000000101;
   end
   always @(Addr,Mem_Write,Mem_Read,Write_Data)
   if(Mem_Write==1'b1)
   RAM[Addr]=Write_Data;
   else if(Mem_Read==1'b1)
   Read_Data=RAM[Addr];
endmodule

//ADDER
module ADDER(data1, data2, sum);
  input [31:0] data1;
  input [31:0] data2;
  output [31:0]sum;
  assign sum = data1 + data2;
endmodule

//MULTIPLEXER
module MUX_2x1(mux_in_1,mux_in_2,sel,mux_out);
  input [31:0] mux_in_1;
  input [31:0] mux_in_2;
  input sel;
  output [31:0] mux_out;
  assign mux_out=sel ? mux_in_2 : mux_in_1;
endmodule

//REGISTERS
module REGISTERS(clk, Read_Register1,Read_Register2, Write_Register, WriteData_reg,Reg_Write,Read_Data1,Read_Data2);
  input clk;
  input [4:0] Read_Register1, Read_Register2, Write_Register;
  input [31:0] WriteData_reg;
  input Reg_Write;
  output [31:0] Read_Data1, Read_Data2;
  reg [31:0] REG[0:31];
  
  integer i;
  initial
  begin
   REG[0] <= 32'b00000000000000000000000000000001;
   REG[1] <= 32'b00000000000000000000000000000010;
   REG[2] <= 32'b00000000000000000000000000000011;
   REG[3] <= 32'b00000000000000000000000000000100;
   REG[4] <= 32'b00000000000000000000000000000101;
  for(i=5;i<32;i=i+1)
  REG[i]=0;
  end
  always @(posedge clk)
  begin
  if(Reg_Write==1'b1)
  begin
  REG[Write_Register]=WriteData_reg;
  end
  end
  assign Read_Data1 = REG[Read_Register1];
  assign Read_Data2 = REG[Read_Register2];
endmodule

//CONTROL
module CONTROL(opcode,Reg_Dst,Jump,Branch,Mem_Read,MemtoReg,ALU_Op,Mem_Write,ALU_Src,Reg_Write);
   input [5:0] opcode ;
   output Reg_Dst, Jump, Branch, Mem_Read, MemtoReg, Mem_Write, ALU_Src, Reg_Write;
   output [1:0] ALU_Op;
   reg Reg_Dst=0; 
   reg Jump=0;
   reg Branch=0;
   reg Mem_Read=0;
   reg MemtoReg=0;
   reg Mem_Write=0;
   reg ALU_Src=0;
   reg Reg_Write=0;
   reg [1:0] ALU_Op=0;
   
   always @(opcode)
   begin
   if(opcode==6'b000000) //r controls
   begin
      Reg_Dst<=1'b1;
      Jump<=1'b0;
      ALU_Src<=1'b0;
      MemtoReg<=1'b0;
      Reg_Write<=1'b1;
      Mem_Read<=1'b0;
      Mem_Write<=1'b0;
      Branch<=1'b0;
      ALU_Op<=2'b10;
   end
   if(opcode==6'b100011) //lw controls
   begin
      Reg_Dst<=1'b0;
      Jump<=1'b0;
      ALU_Src<=1'b1;
      MemtoReg<=1'b1;
      Reg_Write<=1'b1;
      Mem_Read<=1'b1;
      Mem_Write<=1'b0;
      Branch<=1'b0;
      ALU_Op<=2'b00;
   end
   if(opcode==6'b101011) //sw controls
   begin
      Reg_Dst<=1'bx;
      Jump<=1'b0;
      ALU_Src<=1'b1;
      MemtoReg<=1'bx;
      Reg_Write<=1'b0;
      Mem_Read<=1'b0;
      Mem_Write<=1'b1;
      Branch<=1'b0;
      ALU_Op<=2'b00;
   end
   if(opcode==6'b110011) //beq controls
   begin
      Reg_Dst<=1'bx;
      Jump<=1'b0;
      ALU_Src<=1'b0;
      MemtoReg<=1'bx;
      Reg_Write<=1'b0;
      Mem_Read<=1'b0;
      Mem_Write<=1'b0;
      Branch<=1'b1;
      ALU_Op<=2'b01;
   end
   end
endmodule

//ALU CONTROL
module ALU_CONTROL (ALU_Op,Funct, ALU_Control);
  input [1:0] ALU_Op;
  input [5:0] Funct;
  output [5:0] ALU_Control;
  reg [5:0] ALU_Control;
  
  always @ (*)
  begin
  if(ALU_Op==2'b10 && Funct==6'b000010)
  begin
        ALU_Control <= 6'b000010 ;
  end
  if(ALU_Op==2'b10 && Funct==6'b000110)
  begin
        ALU_Control <= 6'b000110;
  end
  if(ALU_Op==2'b10 && Funct==6'b000000)
  begin
        ALU_Control <= 6'b000000;
  end
  if(ALU_Op==2'b10 && Funct==6'b000001)
  begin
        ALU_Control <= 6'b000001;
  end
  if(ALU_Op==2'b10 && Funct==6'b000111)
  begin
        ALU_Control <= 6'b000111;
  end
  end
endmodule

//ALU
module ALU(Read_data_1, Read_data_2, ALU_Control, ALU_result, is_Zero);
  input [31:0] Read_data_1, Read_data_2;
  input [5:0] ALU_Control;
  output [31:0]ALU_result;
  output [31:0]is_Zero;
  reg [31:0] ALU_result=0;
  reg [31:0] is_Zero=0;
  
  always @(Read_data_1, Read_data_2, ALU_Control)
  if (ALU_Control == 6'b000010) //add
  ALU_result = Read_data_1 + Read_data_2;
  else if(ALU_Control == 6'b000110) //sub
  ALU_result = Read_data_1 - Read_data_2;
  else if(ALU_Control == 6'b000000) //and
  ALU_result = Read_data_1 & Read_data_2;
  else if(ALU_Control == 6'b000001) //or
  ALU_result = Read_data_1 | Read_data_2;
  else if(ALU_Control == 6'b000111) //slt
  if(Read_data_1 < Read_data_2)
  ALU_result = 32'b00000000000000000000000000000001;
  else
  ALU_result = 32'b00000000000000000000000000000000;
  always @(Read_data_1, Read_data_2, ALU_Control,ALU_result)
  if(ALU_result == 32'b0)
  is_Zero = 32'b00000000000000000000000000000001;
  else
  is_Zero = 32'b00000000000000000000000000000000;
endmodule

//SHIFT LEFT
module SHIFT_LEFT(shift_in,shift_out);
  input [31:0] shift_in;
  output [31:0] shift_out;
  assign shift_out= shift_in<<2;
endmodule

//SIGN EXTEND
module SIGN_EXTEND(sign_in, sign_out);
  input [15:0] sign_in;
  output [31:0] sign_out;
  assign sign_out = {{16{sign_in[15]}},sign_in};
endmodule

//AND gate
module and_gate (in0,in1,out);
  parameter DELAY=0;
  input in0,in1;
  output reg out;
  
  always @(in0,in1) begin
  out <= #DELAY(in0 & in1);
  end
endmodule