module instr_mem(
    input  [31:0] addr,
    output [31:0] instr
);

    reg [31:0] memory [0:63];

    // Instruction according to current test
    initial begin
    // addr 0 : addi x1, x0, 10          x1 = 10
        memory[0]  = {12'd10, 5'b00000, 3'b000, 5'b00001, 7'b0010011};
 
        // addr 4 : addi x2, x0, 20          x2 = 20
        memory[1]  = {12'd20, 5'b00000, 3'b000, 5'b00010, 7'b0010011};
 
        // addr 8 : add  x3, x1, x2          x3 = 30
        memory[2]  = {7'b0000000, 5'b00010, 5'b00001, 3'b000, 5'b00011, 7'b0110011};
 
        // addr 12: sw   x3, 0(x0)           mem[0] = 30
        memory[3]  = {7'b0000000, 5'b00011, 5'b00000, 3'b010, 5'b00000, 7'b0100011};
 
        // addr 16: lw   x4, 0(x0)           x4 = 30
        memory[4]  = {12'd0, 5'b00000, 3'b010, 5'b00100, 7'b0000011};
 
        // addr 20: beq  x3, x4, +8          taken (30==30) -> target = 28
        memory[5]  = {1'b0, 6'b000000, 5'b00100, 5'b00011, 3'b000, 4'b0100, 1'b0, 7'b1100011};
 
        // addr 24: addi x5, x0, 1           SKIPPED by the taken branch above
        memory[6]  = {12'd1, 5'b00000, 3'b000, 5'b00101, 7'b0010011};
 
        // addr 28: addi x5, x0, 99          x5 = 99   (branch landing point)
        memory[7]  = {12'd99, 5'b00000, 3'b000, 5'b00101, 7'b0010011};
 
        // addr 32: addi x6, x0, -1          x6 = -1   (regression test: bit10 of the
        //                                    immediate is 1, this used to be mis-decoded
        //                                    as SUB before the ALU_control fix)
        memory[8]  = {12'hFFF, 5'b00000, 3'b000, 5'b00110, 7'b0010011};
 
        // addr 36: sub  x7, x1, x2          x7 = 10 - 20 = -10
        memory[9]  = {7'b0100000, 5'b00010, 5'b00001, 3'b000, 5'b00111, 7'b0110011};
 
        // addr 40: and  x8, x1, x2          x8 = 10 & 20 = 0
        memory[10] = {7'b0000000, 5'b00010, 5'b00001, 3'b111, 5'b01000, 7'b0110011};
 
        // addr 44: or   x9, x1, x2          x9 = 10 | 20 = 30
        memory[11] = {7'b0000000, 5'b00010, 5'b00001, 3'b110, 5'b01001, 7'b0110011};
 
        // addr 48: addi x10, x0, 5          x10 = 5
        memory[12] = {12'd5, 5'b00000, 3'b000, 5'b01010, 7'b0010011};
 
        // addr 52: beq  x1, x10, +8         NOT taken (10 != 5) -> falls through to addr 56
        memory[13] = {1'b0, 6'b000000, 5'b01010, 5'b00001, 3'b000, 4'b0100, 1'b0, 7'b1100011};
 
        // addr 56: addi x11, x0, 111        x11 = 111  (proves the not-taken branch fell through)
        memory[14] = {12'd111, 5'b00000, 3'b000, 5'b01011, 7'b0010011};
 
        // addr 60: addi x12, x0, 222        x12 = 222  (final marker instruction)
        memory[15] = {12'd222, 5'b00000, 3'b000, 5'b01100, 7'b0010011};
 
        // addr 64, 68: nop padding (addi x0, x0, 0) in case the testbench clocks
        // a cycle or two past the last real instruction
        memory[16] = {12'd0, 5'b00000, 3'b000, 5'b00000, 7'b0010011};
        memory[17] = {12'd0, 5'b00000, 3'b000, 5'b00000, 7'b0010011};
end


    assign instr = memory[addr[31:2]];

endmodule
