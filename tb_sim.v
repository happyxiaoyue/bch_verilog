`timescale 1ns / 1ps

module tb_sim();

parameter N = 1023;
parameter K = 328;
parameter T = 90;
parameter OPTION = "SERIAL";
parameter SEED = 0;

reg [31:0] seed = SEED;

initial begin
	$dumpfile("test.vcd");
	$dumpvars(0);
end

localparam TCQ = 1;

reg clk = 0;
reg reset = 0;
reg [K-1:0] din = 0;
reg [$clog2(T+2)-1:0] nerr = 0;
reg [N-1:0] error = 0;

function [K-1:0] randk;
	input [31:0] useless;
	integer i;
begin
	for (i = 0; i < (31 + K) / 32; i = i + 1)
		if (i * 32 > K)
			randk[i*32+:K%32] = $random(seed);
		else
			randk[i*32+:32] = $random(seed);
end
endfunction

function integer n_errors;
	input [31:0] useless;
	integer i;
begin
	n_errors = (32'h7fff_ffff & $random(seed)) % (T + 1);
end
endfunction

function [N-1:0] rande;
	input [31:0] nerr;
	integer i;
begin
	rande = 0;
	while (nerr) begin
		i = (32'h7fff_ffff & $random(seed)) % N;
		if (!((1 << i) & rande)) begin
			rande = rande | (1 << i);
			nerr = nerr - 1;
		end
	end
end
endfunction

reg encode_start = 0;
wire encoded_penult;
wire vdout;
wire wrongNow;
wire wrong;
wire [K-1:0] dout;
wire busy;
reg active = 0;

sim #(N, K, T, OPTION) u_sim(
	.clk(clk),
	.reset(1'b0),
	.data_in(din),
	.error(error),
	.busy(busy),
	.encode_start(active && !busy),
	.encoded_penult(encoded_penult),
	.output_valid(vdout),
	.wrong_now(wrongNow),
	.wrong(wrong),
	.data_out(dout)
);

always
	#5 clk = ~clk;

always @(posedge wrong)
	#10 $finish;

reg [31:0] s;

always @(posedge clk) begin
	if (!busy) begin
		s = seed;
		#1;
		din <= randk(0);
		#1;
		nerr <= n_errors(0);
		#1;
		error <= rande(nerr);
		#1;
		active <= 1;
		$display("%b %d flips - %b (seed = %d)", din, nerr, error, s);
	end
end

initial begin
	$display("(%1d, %1d, %1d) %s", N, K, T, OPTION);
	@(posedge clk);
	@(posedge clk);
	reset <= #1 1;
	@(posedge clk);
	@(posedge clk);
	reset <= #1 0;
end

endmodule
