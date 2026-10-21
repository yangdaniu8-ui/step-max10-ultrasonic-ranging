`default_nettype none
module active_buzzer #(
    parameter integer CLOCK_HZ = 12000000
) (
    input wire clk,
    input wire rst_n,
    input wire [8:0] distance_cm,
    input wire valid,
    output reg buzzer
);
    localparam integer CW = $clog2(CLOCK_HZ);
    localparam integer HALF_100 = (CLOCK_HZ/1000)*100;
    localparam integer HALF_200 = (CLOCK_HZ/1000)*200;
    localparam integer HALF_300 = (CLOCK_HZ/1000)*300;
    localparam integer HALF_500 = (CLOCK_HZ/1000)*500;
    localparam integer HALF_750 = (CLOCK_HZ/1000)*750;
    reg [CW-1:0] count;
    reg [CW-1:0] half_period;
    reg [CW-1:0] previous_period;
    reg previous_valid;
    // A powered active buzzer generates its own pitch. Only gate its enable.
    // <10 cm: continuous. Remaining bands are 100/200/300/500/750 ms ON/OFF.
    always @* begin
        if (distance_cm < 20) half_period = HALF_100[CW-1:0];
        else if (distance_cm < 40) half_period = HALF_200[CW-1:0];
        else if (distance_cm < 80) half_period = HALF_300[CW-1:0];
        else if (distance_cm < 150) half_period = HALF_500[CW-1:0];
        else half_period = HALF_750[CW-1:0];
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 0;
            buzzer <= 0;
            previous_period <= 0;
            previous_valid <= 0;
        end else begin
            previous_period <= half_period;
            previous_valid <= valid;
            if (!valid) begin count <= 0; buzzer <= 0; end
            else if (distance_cm < 10) begin count <= 0; buzzer <= 1; end
            else if (!previous_valid || previous_period != half_period) begin count <= 0; buzzer <= 1; end
            else if (count >= half_period-1'b1) begin count <= 0; buzzer <= !buzzer; end
            else count <= count + 1'b1;
        end
    end
endmodule
`default_nettype wire
