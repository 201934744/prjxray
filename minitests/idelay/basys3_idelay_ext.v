`include "src/idelay_calibrator.v"

`default_nettype none

// ============================================================================

module top
(
input  wire clk,

input  wire rx,
output wire tx,

input  wire [15:0] sw,
output wire [15:0] led,

output wire ja1,
output wire ja2,
output wire ja3,
output wire ja4,
input  wire ja7,
input  wire ja8,
input  wire ja9,
input  wire ja10,

output wire jb1,
output wire jb2,
output wire jb3,
output wire jb4,
input  wire jb7,
input  wire jb8,
input  wire jb9,
input  wire jb10,

output wire jc1,
output wire jc2,
output wire jc3,
output wire jc4,
input  wire jc7,
input  wire jc8,
input  wire jc9,
input  wire jc10,

output wire xadc1_p,
input  wire xadc1_n,
output wire xadc2_p,
output wire xadc2_n
);

// ============================================================================
// Clock & reset
reg [3:0] rst_sr;

initial rst_sr <= 4'hF;

always @(posedge clk)
    if (sw[0])
        rst_sr <= 4'hF;
    else
        rst_sr <= rst_sr >> 1;

wire CLK = clk;
wire RST = rst_sr[0];

// ============================================================================
// IDELAY calibrator
wire cal_rdy;

idelay_calibrator cal
(
.refclk (CLK),
.rst    (RST),
.rdy    (cal_rdy)
);

// ============================================================================
// Delay selector
wire       btn_in = sw[1];
reg [3:0]  btn_sr;
wire       btn_edge;
reg [16:0] btn_cnt;

always @(posedge CLK)
    if (RST)
        btn_sr <= (btn_in) ? 4'hF : 4'h0;
    else
        btn_sr <= (btn_sr >> 1) | (btn_in << 3);

assign btn_edge = btn_sr[1] ^ btn_sr[0];

always @(posedge CLK)
    if (RST)
        btn_cnt <= -1;
    else if (btn_edge)
        btn_cnt <= 1000000 - 1;
    else if (!btn_cnt[15])
        btn_cnt <= btn_cnt - 1;

wire dly_ld_req = btn_edge && btn_cnt[15];

// ============================================================================
// IDELAY path
reg        dly_ld;
wire       dly_out;
reg  [4:0] dly_delay_in;
wire [4:0] dly_delay_out;

always @(posedge CLK)
    if (RST || !cal_rdy)
        dly_ld <= 0;
    else if ( dly_ld)
        dly_ld <= 0;
    else if (!dly_ld && dly_ld_req)
        dly_ld <= 1;

always @(posedge CLK)
    if (RST || !cal_rdy)
        dly_delay_in <= 0;
    else if (!dly_ld && dly_ld_req)
        dly_delay_in <= dly_delay_in + 1;

(* KEEP, DONT_TOUCH *)
IDELAYE2 #
(
.IDELAY_TYPE    ("VAR_LOAD"),
.DELAY_SRC      ("IDATAIN")
)
idelay
(
.IDATAIN        (xadc1_n),
.DATAOUT        (dly_out),

.REGRST         (RST),
.C              (CLK),
.LD             (dly_ld),
.CNTVALUEIN     (dly_delay_in),
.CNTVALUEOUT    (dly_delay_out)
);

// ============================================================================
// I/O connections
reg O;
always @(posedge CLK)
    if (RST) O <= 0;
    else     O <= ~O;

reg [23:0] heartbeat_cnt;

always @(posedge CLK)
    heartbeat_cnt <= heartbeat_cnt + 1;

assign led[ 0] = heartbeat_cnt[23];
assign led[ 1] = cal_rdy;
assign led[ 2] = 1'b0;
assign led[ 3] = 1'b0;
assign led[ 4] = 1'b0;
assign led[ 5] = 1'b0;
assign led[ 6] = 1'b0;
assign led[ 7] = 1'b0;
assign led[ 8] = 1'b0;
assign led[ 9] = 1'b0;
assign led[10] = 1'b0;
assign led[11] = dly_delay_out[0];
assign led[12] = dly_delay_out[1];
assign led[13] = dly_delay_out[2];
assign led[14] = dly_delay_out[3];
assign led[15] = dly_delay_out[4];

assign ja1  = 1'b0;
assign ja2  = 1'b0;
assign ja3  = 1'b0;
assign ja4  = 1'b0;

assign jb1  = 1'b0;
assign jb2  = 1'b0;
assign jb3  = 1'b0;
assign jb4  = 1'b0;

assign jc1  = 1'b0;
assign jc2  = 1'b0;
assign jc3  = 1'b0;
assign jc4  = 1'b0;

assign xadc2_p = O;
assign xadc2_n = O;
assign xadc1_p = dly_out;

endmodule
