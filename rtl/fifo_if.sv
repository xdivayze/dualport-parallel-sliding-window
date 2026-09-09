
`timescale 1ns / 1ps
interface fifo_if #(
    parameter int SIZE = 1920,
    parameter int DEPTH = 16,
    parameter int ADDR_SIZE = $clog2(SIZE)
);


  logic clk;
  logic rst_n;
  logic write_en;
  logic read_en;
  logic [DEPTH-1:0] sig_in;
  logic r_valid;
  logic w_success;
  logic [DEPTH-1:0] sig_out;

  modport dut(input clk, rst_n, write_en, read_en, sig_in, output r_valid, w_success, sig_out);
  modport handler(output clk, rst_n, write_en, read_en, sig_in, input r_valid, w_success, sig_out);




endinterface
