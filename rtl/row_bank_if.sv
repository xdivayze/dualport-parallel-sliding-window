`timescale 1ns / 1ps

interface row_bank_if #(
    parameter int DEPTH = 16,
    parameter int ADDR_SIZE = 11
);

  logic a_wen, a_ren, b_wen, b_ren;
  logic [ADDR_SIZE-1:0] a_addr, b_addr;
  logic [DEPTH-1:0] a_din, b_din;
  logic [DEPTH-1:0] a_dout, b_dout;
  logic a_valid, b_valid, a_success, b_success;

  modport dut(
      input a_wen, a_ren, b_wen, b_ren, a_addr, b_addr, a_din, b_din,
      output a_dout, b_dout, a_valid, b_valid, a_success, b_success
  );

  modport handler(
      output a_wen, a_ren, b_wen, b_ren, a_addr, b_addr, a_din, b_din,
      input a_dout, b_dout, a_valid, b_valid, a_success, b_success
  );

endinterface
