`default_nettype none
module board_display_selftest #(
    parameter integer CLOCK_HZ = 12000000
) (
    input wire clk_12m,
    input wire key1_n,
    input wire echo_in,
    output wire trig_out,
    output wire buzzer_out,
    output reg [8:0] seg1,
    output reg [8:0] seg2,
    output wire [1:0] led_n
);
    wire rst_n;
    reg [$clog2(CLOCK_HZ)-1:0] second_count;
    reg [3:0] step;
    reset_release u_reset(.clk(clk_12m),.key_n(key1_n),.rst_n(rst_n));
    always @(posedge clk_12m or negedge rst_n) begin
        if (!rst_n) begin second_count<=0; step<=0; end
        else if (second_count==CLOCK_HZ-1) begin
            second_count<=0;
            if (step==11) step<=0;
            else step<=step+1'b1;
        end else second_count<=second_count+1'b1;
    end
    function [6:0] digit_segments;
        input [3:0] digit;
        begin
            case(digit)
                0:digit_segments=7'h3f; 1:digit_segments=7'h06;
                2:digit_segments=7'h5b; 3:digit_segments=7'h4f;
                4:digit_segments=7'h66; 5:digit_segments=7'h6d;
                6:digit_segments=7'h7d; 7:digit_segments=7'h07;
                8:digit_segments=7'h7f; 9:digit_segments=7'h6f;
                default:digit_segments=0;
            endcase
        end
    endfunction
    always @* begin
        seg1={2'b00,digit_segments(step)};
        seg2={2'b00,digit_segments(step)};
        if (step==10) begin seg1=9'h0bf; seg2=0; end
        if (step==11) begin seg1=0; seg2=9'h0bf; end
    end
    assign led_n={step[0],!step[0]};
    assign trig_out=1'b0;
    // Unknown module supply/polarity: do not drive the external buzzer input.
    assign buzzer_out=1'bz;
    // echo_in is intentionally unused. ECHO has been physically disconnected.
endmodule
`default_nettype wire
