module mux_2to1(input1, input2, select, output_data);
    input [31:0] input1, input2;
    input select;
    output [31:0] output_data;

    assign output_data = (select) ? input2 : input1;
endmodule