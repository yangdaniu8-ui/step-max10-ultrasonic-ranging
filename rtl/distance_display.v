`default_nettype none
module distance_display #(
    parameter integer CLOCK_HZ = 12000000,
    parameter integer PAGE_MS = 1000
) (
    input wire clk,
    input wire rst_n,
    input wire [8:0] distance_cm,
    input wire valid,
    output reg [8:0] seg1,
    output reg [8:0] seg2,
    output wire meter_page
);
    localparam integer PAGE_CYCLES = (CLOCK_HZ/1000)*PAGE_MS;
    localparam integer CW = $clog2(PAGE_CYCLES);
    reg [CW-1:0] page_count;
    reg page;
    // Freeze one sample across both pages, so 1.23 cannot become 1.87 mid-pair.
    reg [8:0] display_cm;
    reg display_valid;
    wire [8:0] meters = display_cm / 9'd100;
    wire [8:0] remainder_cm = display_cm % 9'd100;
    wire [8:0] tens = remainder_cm / 9'd10;
    wire [8:0] ones = remainder_cm % 9'd10;

    // STEP MAX10: bit 8=DIG(common cathode), 7=DP, 6:0=GFEDCBA.
    // DIG=0 enables each digit, segment/DP=1 illuminates it.
    function [6:0] encode_digit;
        input [3:0] digit;
        begin
            case (digit)
                0: encode_digit=7'h3f; 1: encode_digit=7'h06;
                2: encode_digit=7'h5b; 3: encode_digit=7'h4f;
                4: encode_digit=7'h66; 5: encode_digit=7'h6d;
                6: encode_digit=7'h7d; 7: encode_digit=7'h07;
                8: encode_digit=7'h7f; 9: encode_digit=7'h6f;
                default: encode_digit=7'h40;
            endcase
        end
    endfunction
    assign meter_page = !page;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            page_count <= 0;
            page <= 0;
            display_cm <= 0;
            display_valid <= 0;
        end else if (!valid) begin
            page_count <= 0;
            page <= 0;
            display_valid <= 0;
        end else if (!display_valid) begin
            display_cm <= distance_cm;
            display_valid <= 1;
            page_count <= 0;
            page <= 0;
        end else if (page_count == PAGE_CYCLES-1) begin
            page_count <= 0;
            page <= !page;
            if (page) display_cm <= distance_cm;
        end else page_count <= page_count + 1'b1;
    end

    always @* begin
        seg1 = 9'h040;
        seg2 = 9'h040;
        if (valid && display_valid) begin
            if (!page) begin
                seg1 = {1'b0, 1'b1, encode_digit(meters[3:0])};
                seg2 = 9'h000;
            end else begin
                seg1 = {2'b00, encode_digit(tens[3:0])};
                seg2 = {2'b00, encode_digit(ones[3:0])};
            end
        end
    end
endmodule
`default_nettype wire
