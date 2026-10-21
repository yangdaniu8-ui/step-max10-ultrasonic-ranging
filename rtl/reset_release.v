`default_nettype none
module reset_release (
    input wire clk,
    input wire key_n,
    output wire rst_n
);
    // Quartus maps this initial value to the FPGA power-up register state.
    // Asynchronous assertion, eight-clock synchronous release, including POR.
    (* altera_attribute = "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS" *)
    reg [7:0] release_pipe = 8'b0;
    always @(posedge clk or negedge key_n)
        if (!key_n) release_pipe <= 8'b0;
        else release_pipe <= {release_pipe[6:0], 1'b1};
    assign rst_n = release_pipe[7];
endmodule
`default_nettype wire
