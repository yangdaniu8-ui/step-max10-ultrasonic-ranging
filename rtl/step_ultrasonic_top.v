`default_nettype none
module step_ultrasonic_top #(
    parameter integer CLOCK_HZ = 12000000,
    parameter integer PERIOD_US = 1000000,
    parameter integer PAGE_MS = 1000,
    parameter integer BUZZER_ACTIVE_LOW = 0,
    parameter integer BUZZER_TONE_HZ = 0
) (
    input wire clk_12m,
    input wire key1_n,
    input wire echo_in,
    output wire trig_out,
    output wire buzzer_out,
    output wire [8:0] seg1,
    output wire [8:0] seg2,
    output wire [1:0] led_n
);
    wire rst_n, valid, sample_done, meter_page, buzzer, buzzer_audio;
    wire [8:0] distance_cm;
    reset_release u_reset(.clk(clk_12m), .key_n(key1_n), .rst_n(rst_n));
    ultrasonic_ranger #(.CLOCK_HZ(CLOCK_HZ), .PERIOD_US(PERIOD_US)) u_ranger (
        .clk(clk_12m), .rst_n(rst_n), .echo_in(echo_in),
        .trig(trig_out), .distance_cm(distance_cm), .valid(valid),
        .sample_done(sample_done), .busy()
    );
    distance_display #(.CLOCK_HZ(CLOCK_HZ), .PAGE_MS(PAGE_MS)) u_display (
        .clk(clk_12m), .rst_n(rst_n),
        .distance_cm(distance_cm), .valid(valid),
        .seg1(seg1), .seg2(seg2), .meter_page(meter_page)
    );
    active_buzzer #(.CLOCK_HZ(CLOCK_HZ)) u_buzzer (
        .clk(clk_12m), .rst_n(rst_n), .distance_cm(distance_cm),
        .valid(valid), .buzzer(buzzer)
    );
    // 0 preserves DC envelope drive for active indicators. The installed BEEP
    // module was audibly improved by a 2 kHz carrier, selected in the QSF.
    generate
        if (BUZZER_TONE_HZ > 0) begin : g_audio
            buzzer_tone_gate #(.CLOCK_HZ(CLOCK_HZ),.TONE_HZ(BUZZER_TONE_HZ)) u_audio (
                .clk(clk_12m),.rst_n(rst_n),.enable(buzzer),.tone_out(buzzer_audio)
            );
        end else begin : g_dc
            assign buzzer_audio = buzzer;
        end
    endgenerate
    assign buzzer_out = BUZZER_ACTIVE_LOW ? !buzzer_audio : buzzer_audio;
    assign led_n[0] = !valid;
    assign led_n[1] = !(valid && meter_page);
endmodule
`default_nettype wire
