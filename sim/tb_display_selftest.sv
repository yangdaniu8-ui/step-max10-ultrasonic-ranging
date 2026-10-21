`timescale 1ns/1ps
module tb_display_selftest;
    reg clk=0,key_n=0;
    wire trig,buzzer;
    wire [8:0] s1,s2;
    wire [1:0] led;
    reg [6:0] expected[0:9];
    integer i;
    always #5 clk=!clk;
    board_display_selftest #(.CLOCK_HZ(1000)) dut (
        .clk_12m(clk),.key1_n(key_n),.echo_in(1'b0),
        .trig_out(trig),.buzzer_out(buzzer),.seg1(s1),.seg2(s2),.led_n(led)
    );
    initial begin
        expected[0]='h3f; expected[1]='h06; expected[2]='h5b; expected[3]='h4f;
        expected[4]='h66; expected[5]='h6d; expected[6]='h7d; expected[7]='h07;
        expected[8]='h7f; expected[9]='h6f;
        repeat(3) @(negedge clk);
        key_n=1;
        @(posedge dut.rst_n); #1;
        for(i=0;i<12;i=i+1) begin
            if(i<10 && (s1!=={2'b00,expected[i]} || s2!=={2'b00,expected[i]}))
                $fatal(1,"Selftest digit mismatch step %0d",i);
            if(i==10 && (s1!==9'h0bf || s2!==0)) $fatal(1,"First decimal point mismatch");
            if(i==11 && (s1!==0 || s2!==9'h0bf)) $fatal(1,"Second decimal point mismatch");
            if(trig!==0 || buzzer!==1'bz) $fatal(1,"External control state is not safe");
            repeat(1000) @(posedge clk);
            #1;
        end
        if(s1!==9'h03f || s2!==9'h03f) $fatal(1,"Sequence did not wrap to 00");
        @(negedge clk);key_n=0; #1;
        if(s1!==9'h03f || s2!==9'h03f) $fatal(1,"Key reset failed");
        $display("SELFTEST PASSED: 00-99 sequence, both decimal points, reset, trigger low, buzzer high impedance");
        $finish;
    end
    initial begin #200000; $fatal(1,"Selftest simulation watchdog"); end
endmodule
