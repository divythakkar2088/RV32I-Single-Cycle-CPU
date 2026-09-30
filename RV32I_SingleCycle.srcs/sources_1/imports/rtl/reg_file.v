module reg_file (
    input clk,
    input rst,
    input regwrite,
    input [4:0] rs1,
    input [4:0] rs2,
    input [4:0] rd,
    input [31:0] write_data,
    output [31:0] rs1_data,
    output [31:0] rs2_data
);

    reg [31:0] Registers [31:0];
    integer i;

    // Optional reset (for simulation only)
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1)
                Registers[i] <= 32'b0;
        end
        else if (regwrite && rd != 5'b00000) begin
            Registers[rd] <= write_data;
        end

        // Enforce x0 = 0
        Registers[0] <= 32'b0;
    end

    
    assign rs1_data = (rs1 == 0) ? 32'b0 : Registers[rs1];
    assign rs2_data = (rs2 == 0) ? 32'b0 : Registers[rs2];

endmodule
