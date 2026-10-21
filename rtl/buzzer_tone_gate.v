`default_nettype none
module buzzer_tone_gate #(
    parameter integer CLOCK_HZ = 12000000,
    parameter integer TONE_HZ = 2000
) (
    input wire clk,
    input wire rst_n,
    input wire enable,
    output wire tone_out
);
    localparam integer HALF_CYCLES = CLOCK_HZ/(2*TONE_HZ);
    localparam integer CW = $clog2(HALF_CYCLES+1);
    reg [CW-1:0] count;
    reg tone;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin count<=0; tone<=0; end
        else if (!enable) begin count<=0; tone<=0; end
        else if (count==HALF_CYCLES-1) begin count<=0; tone<=!tone; end
        else count<=count+1'b1;
    end
    assign tone_out = enable && tone;
endmodule
`default_nettype wire
