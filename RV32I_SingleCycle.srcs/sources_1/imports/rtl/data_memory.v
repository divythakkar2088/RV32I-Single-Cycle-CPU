module data_memory (
    input clk,
    input rst,
    input memread,
    input memwrite,
    input [31:0] address,
    input [31:0] write_data,
    output [31:0] memdata_out
);

    reg [31:0] data_memory [0:63];
    integer i;

    // Write 
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 64; i = i + 1)
                data_memory[i] <= 32'b0;
        end
        else if (memwrite) begin
            data_memory[address[31:2]] <= write_data;
        end
    end

    // Read
    assign memdata_out = (memread) ? data_memory[address[31:2]] : 32'b0;

endmodule
