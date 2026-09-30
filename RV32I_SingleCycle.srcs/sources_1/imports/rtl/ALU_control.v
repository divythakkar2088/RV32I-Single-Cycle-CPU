module ALU_control (
    input  [1:0] ALUop,
    input  [2:0] funct3,
    input        funct7,   // instruction[30]
    input        is_Rtype,
    output reg [3:0] control
);

always @(*) begin
    case (ALUop)

        // Load / Store → ADD
        2'b00: control = 4'b0010;

        // Branch → SUB
        2'b01: control = 4'b0110;

        // R-type / I-type
        2'b10: begin
            case (funct3)
                3'b000: begin
                    if (funct7 && is_Rtype) control = 4'b0110; // SUB
                    else        control = 4'b0010; // ADD
                end
                3'b111: control = 4'b0000; // AND
                3'b110: control = 4'b0001; // OR
                default: control = 4'b0010;
            endcase
        end

        default: control = 4'b0010;
    endcase
end

endmodule