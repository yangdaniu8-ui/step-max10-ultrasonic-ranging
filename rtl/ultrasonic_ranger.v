`default_nettype none
module ultrasonic_ranger #(
    parameter integer CLOCK_HZ = 12000000,
    parameter integer PERIOD_US = 1000000,
    parameter integer TRIGGER_US = 20,
    parameter integer TIMEOUT_US = 30000
) (
    input wire clk,
    input wire rst_n,
    input wire echo_in,
    output reg trig,
    output reg [8:0] distance_cm,
    output reg valid,
    output reg sample_done,
    output wire busy
);
    localparam integer CYCLES_PER_US = CLOCK_HZ / 1000000;
    localparam integer PERIOD_CYCLES = CYCLES_PER_US * PERIOD_US;
    localparam integer TRIGGER_CYCLES = CYCLES_PER_US * TRIGGER_US;
    localparam integer TIMEOUT_CYCLES = CYCLES_PER_US * TIMEOUT_US;
    localparam integer PW = $clog2(PERIOD_CYCLES);
    localparam integer TW = $clog2(TIMEOUT_CYCLES + 1);
    localparam integer FW = $clog2(CLOCK_HZ + 17000);
    localparam integer CM_INCREMENT = 17000;
    localparam integer CLOCK_DENOMINATOR = CLOCK_HZ;
    localparam integer FIRST_FRACTION = CLOCK_HZ/2 + 17000;
    localparam [2:0] IDLE=0, SEND_TRIGGER=1, WAIT_RISE=2, MEASURE=3;

    (* altera_attribute = "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS" *)
    reg echo_meta, echo_sync;
    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin echo_meta <= 0; echo_sync <= 0; end
        else begin echo_meta <= echo_in; echo_sync <= echo_meta; end

    reg [PW-1:0] period_count;
    reg [TW-1:0] timer;
    reg [2:0] state;
    // Round(N * 17000 / CLOCK_HZ), using the report's 340 m/s sound speed.
    // A rational accumulator avoids a large combinational divider.
    reg [FW-1:0] fraction;
    reg [8:0] cm_accum;
    wire [FW:0] fraction_next = {1'b0, fraction} + CM_INCREMENT[FW:0];
    wire [FW:0] fraction_wrapped = fraction_next - CLOCK_DENOMINATOR[FW:0];
    assign busy = (state != IDLE);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            period_count <= 0;
            timer <= 0;
            state <= IDLE;
            trig <= 0;
            distance_cm <= 0;
            valid <= 0;
            sample_done <= 0;
            fraction <= 0;
            cm_accum <= 0;
        end else begin
            sample_done <= 0;
            if (period_count == PERIOD_CYCLES-1) period_count <= 0;
            else period_count <= period_count + 1'b1;
            case (state)
                IDLE: begin
                    trig <= 0;
                    timer <= 0;
                    if (period_count == PERIOD_CYCLES-1) begin
                        // An already-high ECHO cannot identify a new pulse.
                        if (echo_sync) begin
                            valid <= 0;
                            distance_cm <= 0;
                            sample_done <= 1;
                        end else begin
                            trig <= 1;
                            state <= SEND_TRIGGER;
                        end
                    end
                end
                SEND_TRIGGER: begin
                    if (timer == TRIGGER_CYCLES-1) begin
                        trig <= 0;
                        timer <= 0;
                        state <= WAIT_RISE;
                    end else timer <= timer + 1'b1;
                end
                WAIT_RISE: begin
                    if (echo_sync) begin
                        // This clock is the first measured high clock.
                        timer <= 1;
                        cm_accum <= 0;
                        fraction <= FIRST_FRACTION[FW-1:0];
                        state <= MEASURE;
                    end else if (timer == TIMEOUT_CYCLES-1) begin
                        valid <= 0;
                        distance_cm <= 0;
                        sample_done <= 1;
                        state <= IDLE;
                    end else timer <= timer + 1'b1;
                end
                MEASURE: begin
                    if (!echo_sync) begin
                        distance_cm <= cm_accum;
                        valid <= (cm_accum >= 2 && cm_accum <= 400);
                        sample_done <= 1;
                        state <= IDLE;
                    end else if (timer == TIMEOUT_CYCLES-1) begin
                        valid <= 0;
                        distance_cm <= 0;
                        sample_done <= 1;
                        state <= IDLE;
                    end else begin
                        timer <= timer + 1'b1;
                        if (fraction_next >= CLOCK_DENOMINATOR) begin
                            fraction <= fraction_wrapped[FW-1:0];
                            // Saturate instead of wrapping if an echo is too long.
                            if (cm_accum != 9'd511) cm_accum <= cm_accum + 1'b1;
                        end else fraction <= fraction_next[FW-1:0];
                    end
                end
                default: begin state <= IDLE; trig <= 0; valid <= 0; end
            endcase
        end
    end
endmodule
`default_nettype wire
