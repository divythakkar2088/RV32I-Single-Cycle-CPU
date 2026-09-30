//immediate generator
module immGen(
    input  [6:0]  opcode,
    input  [31:0] instruction,
    output reg [31:0] immExt
);

always @(*) begin
    case (opcode)

        // I-type (loads and ALU immediates)
        7'b0000011,       // lw
        7'b0010011: begin // addi, andi, ori, slti
            immExt = {{20{instruction[31]}}, instruction[31:20]};
        end

        // S-type (stores)
        7'b0100011: begin
            immExt = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
        end

        // SB-type (branches)
        7'b1100011: begin
            immExt = {{19{instruction[31]}}, instruction[31], instruction[30:25], instruction[11:8], 1'b0};
        end

        default: begin
            immExt = 32'b0;
        end
    endcase
end

endmodule
