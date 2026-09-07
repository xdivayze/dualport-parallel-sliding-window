`timescale 1ns / 1ps
//TODO add address size checker

//TODO add internal register write mechanism, take another cycle to avoid
//penalty

//dualport single clock read first bram
module row_bank #(
    parameter int DEPTH = 16,
    parameter int SIZE = 1920,
    parameter int ADDR_SIZE = $clog2(SIZE)
) (
    input logic clk,
    a_wen,
    a_ren,
    b_wen,
    b_ren,

    input logic [ADDR_SIZE-1:0] a_addr,
    b_addr,

    input logic [DEPTH-1:0] a_din,
    b_din,

    output logic [DEPTH-1:0] a_dout,
    b_dout,
    output logic a_valid,
    b_valid,
    a_success,
    b_success
);

  logic [DEPTH-1:0] block[SIZE];

  logic w_collision;
  assign w_collision = (a_wen && b_wen) && (b_addr == a_addr);

  //a
  always @(posedge clk) begin
    if (a_ren) begin
      a_dout  <= block[a_addr];
      a_valid <= '1;
    end
    if (a_wen) begin
      if (!w_collision) begin
        block[a_addr] <= a_din;
        a_success <= '1;
      end else begin
        a_success <= '0;
      end
    end
  end


  //b
  always @(posedge clk) begin
    if (b_ren) begin
      b_dout  <= block[b_addr];
      b_valid <= '1;
    end
    if (b_wen) begin
      if (!w_collision) begin
        block[b_addr] <= b_din;
        b_success <= '1;
      end else begin
        b_success <= '0;

      end
    end
  end


endmodule
