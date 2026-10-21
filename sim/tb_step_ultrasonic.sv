`timescale 1ns/1ps
module tb_step_ultrasonic;
    localparam integer CLOCK_HZ = 12000000;
    localparam integer PERIOD_CYCLES = 780000; // 65 ms; production is 1 second.
    reg clk=0, key_n=0, echo=0;
    wire trig, buzzer;
    wire [8:0] seg1, seg2;
    wire [1:0] led_n;
    wire por_rst_n;
    reset_release por_check(.clk(clk),.key_n(1'b1),.rst_n(por_rst_n));
    initial begin
        repeat(7) begin
            @(negedge clk);
            if(por_rst_n!==0) $fatal(1,"Power-up reset released too early");
        end
        @(negedge clk);
        if(por_rst_n!==1) $fatal(1,"Power-up reset failed without a key press");
        $display("PASS FPGA power-up reset without a key press");
    end
    always #(1000000000.0 / CLOCK_HZ / 2.0) clk = !clk;
    step_ultrasonic_top #(.PERIOD_US(65000), .PAGE_MS(20), .BUZZER_TONE_HZ(2000)) dut (
        .clk_12m(clk), .key1_n(key_n), .echo_in(echo),
        .trig_out(trig), .buzzer_out(buzzer), .seg1(seg1), .seg2(seg2), .led_n(led_n)
    );
    wire default_trig;
    ultrasonic_ranger default_ranger (
        .clk(clk), .rst_n(dut.rst_n), .echo_in(1'b0), .trig(default_trig),
        .distance_cm(), .valid(), .sample_done(), .busy()
    );
    integer cycle_count=0, last_rise=0, trigger_width=0, trigger_count=0;
    reg previous_trig=0, default_seen=0;
    reg expect_skipped_trigger=0;
    real default_first_ns;
    always @(posedge default_trig) begin
        default_seen=1;
        default_first_ns=$realtime;
        if ($realtime < 1000000000.0 || $realtime > 1000100000.0)
            $fatal(1,"Default measurement period is not 1 second: %f", $realtime);
    end
    always @(posedge clk) begin
        cycle_count=cycle_count+1;
        #1;
        if (!dut.rst_n) begin
            previous_trig=0;
            last_rise=0;
            trigger_width=0;
        end else begin
            if ((^{trig,buzzer,seg1,seg2,led_n}) === 1'bx)
                $fatal(1,"Unknown value on a board output");
            if (!dut.buzzer && buzzer!==0)
                $fatal(1,"Audio carrier is active outside the distance envelope");
            if (trig && !previous_trig) begin
                if (last_rise && cycle_count-last_rise != PERIOD_CYCLES) begin
                    if (expect_skipped_trigger && cycle_count-last_rise == 2*PERIOD_CYCLES)
                        expect_skipped_trigger=0;
                    else $fatal(1,"Unexpected trigger interval %0d",cycle_count-last_rise);
                end
                last_rise=cycle_count;
                trigger_count=trigger_count+1;
                trigger_width=0;
            end
            if (trig) trigger_width=trigger_width+1;
            if (!trig && previous_trig && trigger_width != 240)
                $fatal(1,"Trigger width %0d != 240 clocks (20 us)",trigger_width);
            previous_trig=trig;
        end
    end

    task automatic await_trigger;
        begin
            @(posedge trig);
            @(negedge trig);
            repeat (300) @(negedge clk);
        end
    endtask
    task automatic check_result(input integer cm, input bit expected_valid);
        begin
            @(posedge dut.sample_done);
            #2;
            if (dut.valid !== expected_valid || dut.distance_cm !== cm)
                $fatal(1,"Result got %0d valid=%b, expected %0d valid=%b",
                    dut.distance_cm,dut.valid,cm,expected_valid);
            if (led_n[0] !== !expected_valid) $fatal(1,"Valid LED polarity incorrect");
            $display("PASS echo distance=%0d cm valid=%b at %0t",cm,expected_valid,$time);
        end
    endtask
    task automatic measure(input integer cm);
        integer n;
        begin
            // Calculate echo from physical time, independent of DUT accumulator.
            n=$rtoi(cm * 12000000.0 / 17000.0 + 0.5);
            await_trigger();
            #13.7; echo=1;
            repeat(n) @(negedge clk);
            #13.7; echo=0;
            check_result(cm, cm>=2 && cm<=400);
        end
    endtask

    // Buzzer boundary checks with a reduced clock parameter: cycle counts retain
    // their meaning while the full system above still uses the real 12 MHz.
    reg bz_rst=0, bz_valid=0;
    reg [8:0] bz_distance=0;
    wire bz;
    reg buzzer_tests_done=0;
    active_buzzer #(.CLOCK_HZ(1000)) test_buzzer (
        .clk(clk), .rst_n(bz_rst), .distance_cm(bz_distance), .valid(bz_valid), .buzzer(bz)
    );
    task automatic check_buzzer_band(input integer cm, input integer half_cycles);
        integer i;
        begin
            @(negedge clk); bz_rst=0; bz_valid=0;
            repeat(2) @(negedge clk);
            bz_distance=cm; bz_rst=1; bz_valid=1;
            @(posedge bz); #1;
            for(i=1;i<half_cycles;i=i+1) begin
                @(posedge clk); #1;
                if(bz!==1) $fatal(1,"Buzzer pulse too short for %0d cm",cm);
            end
            @(posedge clk); #1;
            if(bz!==0) $fatal(1,"Buzzer half-period incorrect for %0d cm",cm);
            $display("PASS active buzzer %0d cm, ON/OFF=%0d ms",cm,half_cycles);
        end
    endtask
    initial begin
        check_buzzer_band(10,100); check_buzzer_band(19,100);
        check_buzzer_band(20,200); check_buzzer_band(39,200);
        check_buzzer_band(40,300); check_buzzer_band(79,300);
        check_buzzer_band(80,500); check_buzzer_band(149,500);
        check_buzzer_band(150,750); check_buzzer_band(400,750);
        @(negedge clk); bz_distance=9;
        repeat(1000) begin @(posedge clk); #1; if(bz!==1) $fatal(1,"Near alarm not continuous"); end
        @(negedge clk); bz_valid=0;
        @(posedge clk); #1; if(bz!==0) $fatal(1,"Invalid sample did not mute buzzer");
        buzzer_tests_done=1;
    end

    // Display test independently verifies page encoding and sample consistency.
    reg disp_rst=0, disp_valid=0;
    reg [8:0] disp_distance=0;
    wire [8:0] ds1,ds2;
    wire mp;
    reg display_tests_done=0;
    distance_display #(.CLOCK_HZ(1000),.PAGE_MS(10)) test_display (
        .clk(clk),.rst_n(disp_rst),.distance_cm(disp_distance),.valid(disp_valid),
        .seg1(ds1),.seg2(ds2),.meter_page(mp)
    );
    initial begin
        repeat(4) @(negedge clk);
        disp_rst=1; disp_distance=123; disp_valid=1;
        @(posedge clk); #1;
        if(ds1!==9'h086 || ds2!==0 || !mp) $fatal(1,"123 cm meter page incorrect");
        @(negedge clk); disp_distance=287;
        @(negedge mp); #1;
        if(ds1!==9'h05b || ds2!==9'h04f) $fatal(1,"Display changed sample between pages");
        @(posedge mp); #1;
        if(ds1!==9'h0db || ds2!==0) $fatal(1,"Next display sample not loaded");
        @(negedge mp); #1;
        if(ds1!==9'h07f || ds2!==9'h007) $fatal(1,"287 cm fraction page incorrect");
        @(negedge clk); disp_valid=0;
        @(posedge clk); #1;
        if(ds1!==9'h040 || ds2!==9'h040) $fatal(1,"Invalid display is not --");
        display_tests_done=1;
        $display("PASS display meters/centimeters, coherent pages, invalid --");
    end

    initial begin
        repeat(4) @(negedge clk);
        key_n=1;
        // HC-SR04 range endpoints and every alarm threshold.
        measure(2); measure(5); measure(9); measure(10);
        measure(19); measure(20); measure(39); measure(40);
        measure(79); measure(80); measure(99); measure(100);
        measure(123); measure(149); measure(150); measure(399); measure(400);
        measure(401); measure(1);
        await_trigger();
        check_result(0,0); // No echo: 30 ms wait timeout.
        await_trigger();
        #13.7; echo=1;
        check_result(0,0); // ECHO stuck high: measurement timeout.
        expect_skipped_trigger=1;
        @(posedge dut.sample_done); #2;
        if (dut.valid!==0 || trig!==0) $fatal(1,"Already-high ECHO accepted as new pulse");
        @(negedge clk); echo=0;
        measure(50); // Recover without resetting after both timeout types.
        // Asynchronous reset in the middle of a real measurement.
        await_trigger(); #13.7; echo=1;
        repeat(400) @(negedge clk);
        #7; key_n=0; #2;
        if(trig!==0 || buzzer!==0 || led_n!==2'b11) $fatal(1,"Reset did not assert immediately");
        echo=0;
        repeat(3) @(negedge clk);
        key_n=1;
        measure(25);
        if(!default_seen || !buzzer_tests_done || !display_tests_done)
            $fatal(1,"A required parallel check did not run");
        $display("PASS default first trigger at %f ns",default_first_ns);
        $display("ALL TESTS PASSED: ranging, trigger timing, boundaries, timeouts, recovery, reset, display, buzzer");
        $finish;
    end
    initial begin
        #2000000000;
        $fatal(1,"Simulation watchdog timeout");
    end
endmodule
