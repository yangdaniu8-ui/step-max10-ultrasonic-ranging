`timescale 1ns/1ps
module tb_buzzer_tone;
    reg clk=0,rst_n=0,enable=0;
    wire tone;
    realtime last_rise,period_ns,last_fall,high_ns;
    integer i;
    always #(1000000000.0/12000000/2.0) clk=!clk;
    buzzer_tone_gate dut(.clk(clk),.rst_n(rst_n),.enable(enable),.tone_out(tone));
    initial begin
        repeat(3) @(negedge clk);
        if(tone!==0) $fatal(1,"Tone is not silent during reset");
        rst_n=1;
        repeat(10) @(negedge clk);
        if(tone!==0) $fatal(1,"Tone is not silent when disabled");
        enable=1;
        @(posedge tone);last_rise=$realtime;
        for(i=0;i<5;i=i+1) begin
            @(negedge tone);high_ns=$realtime-last_rise;
            if(high_ns<249990 || high_ns>250010) $fatal(1,"Tone high time is %f ns",high_ns);
            @(posedge tone);period_ns=$realtime-last_rise;last_rise=$realtime;
            if(period_ns<499990 || period_ns>500010) $fatal(1,"Tone period is %f ns",period_ns);
        end
        #17;enable=0;#1;
        if(tone!==0) $fatal(1,"Envelope did not mute immediately");
        repeat(8000) @(negedge clk);
        if(tone!==0) $fatal(1,"Disabled tone toggled");
        enable=1;@(posedge tone);#7;rst_n=0;#1;
        if(tone!==0) $fatal(1,"Reset did not mute tone");
        $display("TONE TEST PASSED: 2 kHz, 50%% duty, envelope mute and reset");
        $finish;
    end
    initial begin #10000000; $fatal(1,"Tone test watchdog"); end
endmodule
