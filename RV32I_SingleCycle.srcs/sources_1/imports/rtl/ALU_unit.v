module ALU_unit (
    input  [31:0] A,
    input  [31:0] B,
    input  [3:0]  control,
    output reg [31:0] ALU_result,
    output reg zero
);

always @(*) begin
    case (control)
        4'b0000: ALU_result = A & B;     // AND
        4'b0001: ALU_result = A | B;     // OR
        4'b0010: ALU_result = A + B;     // ADD
        4'b0110: ALU_result = A - B;     // SUB
        default: ALU_result = 32'b0;
    endcase

    zero = (ALU_result == 32'b0);
end

endmodule
