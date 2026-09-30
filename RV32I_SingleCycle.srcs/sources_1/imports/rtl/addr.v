module addr(input1, input2, output_data);
    input [31:0] input1, input2;
    output [31:0] output_data;

    assign output_data = input1 + input2;
endmodule