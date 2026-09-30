module control_unit (
    input  [6:0] instruction,   // opcode
    output reg branch,
    output reg memRead,
    output reg memtoReg,
    output reg [1:0] ALUop,
    output reg memWrite,
    output reg ALUsrc,
    output reg regWrite
);

always @(*) begin
    // default values 
    branch   = 0;
    memRead = 0;
    memtoReg= 0;
    ALUop   = 2'b00;
    memWrite= 0;
    ALUsrc  = 0;
    regWrite= 0;

    case (instruction)

        // R-type
        7'b0110011: begin
            ALUsrc   = 0;
            regWrite = 1;
            ALUop    = 2'b10;
        end

        // I-type ALU (addi, andi, ori)
        7'b0010011: begin
            ALUsrc   = 1;
            regWrite = 1;
            ALUop    = 2'b10;
        end

        // Load (lw)
        7'b0000011: begin
            ALUsrc   = 1;
            memtoReg = 1;
            regWrite = 1;
            memRead  = 1;
            ALUop    = 2'b00;
        end

        // Store (sw)
        7'b0100011: begin
            ALUsrc   = 1;
            memWrite = 1;
            ALUop    = 2'b00;
        end

        // Branch (beq)
        7'b1100011: begin
            branch = 1;
            ALUop  = 2'b01;
        end

        default: begin
            // keep defaults
        end
    endcase
end

endmodule
