// src/project.v
`default_nettype none

module tt_um_vga_example (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    // VGA timing: supplied by the VGA Playground.
    // One clk cycle equals one pixel at 640x480.
    wire       hsync;
    wire       vsync;
    wire       display_on;
    wire [9:0] pix_x;
    wire [9:0] pix_y;

    hvsync_generator hvsync_gen (
        .clk        (clk),
        .reset      (~rst_n),
        .hsync      (hsync),
        .vsync      (vsync),
        .display_on (display_on),
        .hpos       (pix_x),
        .vpos       (pix_y)
    );

    // Background: blue sky above a green ground strip.
    wire sky;
    wire ground;

    assign sky    = (pix_y < 10'd360);
    assign ground = (pix_y >= 10'd360);

    // House body: x=200..439, y=240..359.
    wire house_wall;
    assign house_wall = (pix_x >= 10'd200) && (pix_x < 10'd440) &&
                        (pix_y >= 10'd240) && (pix_y < 10'd360);

    // Roof: a triangle with peak at x=320, y=140.
    // Its left and right edges expand one pixel for each lower row.
    wire roof_left;
    wire roof_right;
    wire roof;

    assign roof_left  = (pix_y >= 10'd140) && (pix_y < 10'd240) &&
                        (pix_x >= (10'd320 - (pix_y - 10'd140)));
    assign roof_right = (pix_y >= 10'd140) && (pix_y < 10'd240) &&
                        (pix_x <  (10'd321 + (pix_y - 10'd140)));
    assign roof = roof_left && roof_right;

    // Door and two windows.
    wire door;
    wire window_left;
    wire window_right;

    assign door = (pix_x >= 10'd290) && (pix_x < 10'd350) &&
                  (pix_y >= 10'd290) && (pix_y < 10'd360);

    assign window_left = (pix_x >= 10'd225) && (pix_x < 10'd270) &&
                         (pix_y >= 10'd270) && (pix_y < 10'd310);

    assign window_right = (pix_x >= 10'd370) && (pix_x < 10'd415) &&
                          (pix_y >= 10'd270) && (pix_y < 10'd310);

    // Pixel colors, with black outside the visible VGA area.
    reg [1:0] red;
    reg [1:0] green;
    reg [1:0] blue;

    always @* begin
        // Default: sky blue.
        red   = 2'b00;
        green = 2'b10;
        blue  = 2'b11;

        if (ground) begin
            // Green ground.
            red   = 2'b00;
            green = 2'b10;
            blue  = 2'b00;
        end

        if (house_wall) begin
            // Yellow house walls.
            red   = 2'b11;
            green = 2'b10;
            blue  = 2'b00;
        end

        if (roof) begin
            // Red roof.
            red   = 2'b11;
            green = 2'b00;
            blue  = 2'b00;
        end

        if (window_left || window_right) begin
            // Cyan windows.
            red   = 2'b00;
            green = 2'b11;
            blue  = 2'b11;
        end

        if (door) begin
            // Dark brown / red door.
            red   = 2'b01;
            green = 2'b00;
            blue  = 2'b00;
        end

        // Blank RGB during sync and porch intervals.
        if (!display_on) begin
            red   = 2'b00;
            green = 2'b00;
            blue  = 2'b00;
        end
    end

    // TinyVGA PMOD order.
    assign uo_out  = {hsync, blue[0], green[0], red[0],
                      vsync, blue[1], green[1], red[1]};

    // Bidirectional pins unused.
    assign uio_out = 8'h00;
    assign uio_oe  = 8'h00;

    wire _unused = &{ena, ui_in, uio_in, 1'b0};

endmodule

`default_nettype wire
