`timescale 1ns / 1ps

module row_bank_tb;

  localparam int DEPTH = 8;  // word width
  localparam int SIZE = 16;  // number of entries
  localparam int ADDR_SIZE = $clog2(SIZE);

  logic clk;
  logic a_wen, a_ren, b_wen, b_ren;
  logic [ADDR_SIZE-1:0] a_addr, b_addr;
  logic [DEPTH-1:0] a_din, b_din;
  logic [DEPTH-1:0] a_dout, b_dout;
  logic a_valid, b_valid, a_success, b_success;

  int errors = 0;
  int checks = 0;

  row_bank #(
      .DEPTH(DEPTH),
      .SIZE (SIZE)
  ) dut (
      .clk(clk),
      .a_wen(a_wen),
      .a_ren(a_ren),
      .b_wen(b_wen),
      .b_ren(b_ren),
      .a_addr(a_addr),
      .b_addr(b_addr),
      .a_din(a_din),
      .b_din(b_din),
      .a_dout(a_dout),
      .b_dout(b_dout),
      .a_valid(a_valid),
      .b_valid(b_valid),
      .a_success(a_success),
      .b_success(b_success)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  task automatic idle();
    a_wen  = 0;
    a_ren  = 0;
    b_wen  = 0;
    b_ren  = 0;
    a_addr = 0;
    b_addr = 0;
    a_din  = 'x;
    b_din  = 'x;
  endtask

  task automatic check(input bit cond, input string name, input string detail);
    checks++;
    if (!cond) begin
      errors++;
      $display("FAIL [%s]: %s", name, detail);
    end else begin
      $display("PASS [%s]: %s", name, detail);
    end
  endtask

  // single-port write
  task automatic write_a(input logic [ADDR_SIZE-1:0] addr, input logic [DEPTH-1:0] data,
                          output logic ok);
    a_addr = addr;
    a_din  = data;
    a_wen  = 1;
    a_ren  = 0;
    @(posedge clk);
    #1;
    ok = a_success;
    a_wen = 0;
    a_din = 'x;
  endtask

  task automatic write_b(input logic [ADDR_SIZE-1:0] addr, input logic [DEPTH-1:0] data,
                          output logic ok);
    b_addr = addr;
    b_din  = data;
    b_wen  = 1;
    b_ren  = 0;
    @(posedge clk);
    #1;
    ok = b_success;
    b_wen = 0;
    b_din = 'x;
  endtask

  // single-port read
  task automatic read_a(input logic [ADDR_SIZE-1:0] addr, output logic [DEPTH-1:0] data,
                         output logic valid_ok);
    a_addr = addr;
    a_ren  = 1;
    a_wen  = 0;
    @(posedge clk);
    #1;
    data = a_dout;
    valid_ok = a_valid;
    a_ren = 0;
  endtask

  task automatic read_b(input logic [ADDR_SIZE-1:0] addr, output logic [DEPTH-1:0] data,
                         output logic valid_ok);
    b_addr = addr;
    b_ren  = 1;
    b_wen  = 0;
    @(posedge clk);
    #1;
    data = b_dout;
    valid_ok = b_valid;
    b_ren = 0;
  endtask

  // simultaneous write on both ports (used for collision testing)
  task automatic write_both(input logic [ADDR_SIZE-1:0] addr_a, input logic [DEPTH-1:0] data_a,
                             input logic [ADDR_SIZE-1:0] addr_b, input logic [DEPTH-1:0] data_b,
                             output logic ok_a, output logic ok_b);
    a_addr = addr_a;
    a_din  = data_a;
    a_wen  = 1;
    a_ren  = 0;
    b_addr = addr_b;
    b_din  = data_b;
    b_wen  = 1;
    b_ren  = 0;
    @(posedge clk);
    #1;
    ok_a = a_success;
    ok_b = b_success;
    a_wen = 0;
    b_wen = 0;
    a_din = 'x;
    b_din = 'x;
  endtask

  // simultaneous read on both ports
  task automatic read_both(input logic [ADDR_SIZE-1:0] addr_a, input logic [ADDR_SIZE-1:0] addr_b,
                            output logic [DEPTH-1:0] data_a, output logic valid_a,
                            output logic [DEPTH-1:0] data_b, output logic valid_b);
    a_addr = addr_a;
    a_ren  = 1;
    a_wen  = 0;
    b_addr = addr_b;
    b_ren  = 1;
    b_wen  = 0;
    @(posedge clk);
    #1;
    data_a  = a_dout;
    valid_a = a_valid;
    data_b  = b_dout;
    valid_b = b_valid;
    a_ren = 0;
    b_ren = 0;
  endtask

  // simultaneous write(A) + read(B), for cross-port write/read collision checks
  task automatic write_a_read_b(input logic [ADDR_SIZE-1:0] waddr, input logic [DEPTH-1:0] wdata,
                                 input logic [ADDR_SIZE-1:0] raddr, output logic ok,
                                 output logic [DEPTH-1:0] rdata, output logic rvalid);
    a_addr = waddr;
    a_din  = wdata;
    a_wen  = 1;
    a_ren  = 0;
    b_addr = raddr;
    b_ren  = 1;
    b_wen  = 0;
    @(posedge clk);
    #1;
    ok = a_success;
    rdata = b_dout;
    rvalid = b_valid;
    a_wen = 0;
    b_ren = 0;
    a_din = 'x;
  endtask

  // simultaneous write+read on the SAME port/address (self read-during-write)
  task automatic write_read_a(input logic [ADDR_SIZE-1:0] addr, input logic [DEPTH-1:0] data,
                               output logic ok, output logic [DEPTH-1:0] rdata,
                               output logic rvalid);
    a_addr = addr;
    a_din  = data;
    a_wen  = 1;
    a_ren  = 1;
    @(posedge clk);
    #1;
    ok = a_success;
    rdata = a_dout;
    rvalid = a_valid;
    a_wen = 0;
    a_ren = 0;
    a_din = 'x;
  endtask

  initial begin
    logic [DEPTH-1:0] data, data_a, data_b;
    logic ok, ok_a, ok_b, valid_ok, valid_a, valid_b;

    idle();
    @(posedge clk);
    #1;

    // --- basic write/readback on port A ---
    write_a(0, 8'hA5, ok);
    check(ok == 1, "port A: write accepted", $sformatf("a_success=%0b (expected 1)", ok));
    read_a(0, data, valid_ok);
    check(valid_ok == 1 && data == 8'hA5, "port A: readback matches write",
          $sformatf("a_valid=%0b a_dout=%0h (expected 1, a5)", valid_ok, data));

    // --- basic write/readback on port B, different address ---
    write_b(1, 8'h5A, ok);
    check(ok == 1, "port B: write accepted", $sformatf("b_success=%0b (expected 1)", ok));
    read_b(1, data, valid_ok);
    check(valid_ok == 1 && data == 8'h5A, "port B: readback matches write",
          $sformatf("b_valid=%0b b_dout=%0h (expected 1, 5a)", valid_ok, data));

    // --- cross-port visibility: A writes, B reads the same location ---
    write_a(2, 8'h33, ok);
    check(ok == 1, "cross-port: A write accepted", $sformatf("a_success=%0b (expected 1)", ok));
    read_b(2, data, valid_ok);
    check(valid_ok == 1 && data == 8'h33, "cross-port: B reads value written by A",
          $sformatf("b_valid=%0b b_dout=%0h (expected 1, 33)", valid_ok, data));

    // --- independent parallel writes to different addresses in the same cycle ---
    write_both(3, 8'h11, 4, 8'h22, ok_a, ok_b);
    check(ok_a == 1 && ok_b == 1, "parallel writes: both accepted (different addresses)",
          $sformatf("a_success=%0b b_success=%0b (expected 1, 1)", ok_a, ok_b));
    read_both(3, 4, data_a, valid_a, data_b, valid_b);
    check(valid_a == 1 && data_a == 8'h11 && valid_b == 1 && data_b == 8'h22,
          "parallel writes: both locations hold correct data",
          $sformatf("a_dout=%0h b_dout=%0h (expected 11, 22)", data_a, data_b));

    // --- simultaneous read of the same address on both ports ---
    read_both(3, 3, data_a, valid_a, data_b, valid_b);
    check(valid_a == 1 && valid_b == 1 && data_a == data_b && data_a == 8'h11,
          "simultaneous same-address read: both ports agree",
          $sformatf("a_dout=%0h b_dout=%0h (expected 11, 11)", data_a, data_b));

    // --- write/write collision: same address, different data -> both rejected, memory unchanged ---
    write_a(5, 8'h77, ok);
    check(ok == 1, "collision setup: baseline write accepted", $sformatf("a_success=%0b", ok));
    write_both(5, 8'hAA, 5, 8'hBB, ok_a, ok_b);
    check(ok_a == 0 && ok_b == 0, "write/write collision: both ports report failure",
          $sformatf("a_success=%0b b_success=%0b (expected 0, 0)", ok_a, ok_b));
    read_a(5, data, valid_ok);
    check(valid_ok == 1 && data == 8'h77, "write/write collision: memory left unchanged",
          $sformatf("a_dout=%0h (expected 77, i.e. baseline preserved)", data));

    // --- cross-port write(A)/read(B) collision on the same address: B sees the OLD value ---
    write_a(6, 8'hC0, ok);
    check(ok == 1, "rw-collision setup: baseline write accepted", $sformatf("a_success=%0b", ok));
    write_a_read_b(6, 8'hDE, 6, ok, data, valid_ok);
    check(ok == 1 && valid_ok == 1 && data == 8'hC0,
          "cross-port write/read collision: read returns pre-write (old) data",
          $sformatf("a_success=%0b b_valid=%0b b_dout=%0h (expected 1, 1, c0)", ok, valid_ok,
                     data));
    read_b(6, data, valid_ok);
    check(valid_ok == 1 && data == 8'hDE,
          "cross-port write/read collision: new value visible on the following cycle",
          $sformatf("b_dout=%0h (expected de)", data));

    // --- same-port write+read collision (self read-during-write): read returns OLD value ---
    write_a(7, 8'h01, ok);
    check(ok == 1, "self rw-collision setup: baseline write accepted", $sformatf("a_success=%0b", ok));
    write_read_a(7, 8'h02, ok, data, valid_ok);
    check(ok == 1 && valid_ok == 1 && data == 8'h01,
          "self read/write collision: read returns pre-write (old) data on same port",
          $sformatf("a_success=%0b a_valid=%0b a_dout=%0h (expected 1, 1, 01)", ok, valid_ok,
                     data));
    read_a(7, data, valid_ok);
    check(valid_ok == 1 && data == 8'h02,
          "self read/write collision: new value visible on the following cycle",
          $sformatf("a_dout=%0h (expected 02)", data));

    // --- full sweep across the whole address range, write via A, verify via B ---
    for (int i = 0; i < SIZE; i++) begin
      write_a(ADDR_SIZE'(i), 8'(i * 3 + 1), ok);
      check(ok == 1, $sformatf("sweep: write %0d/%0d accepted", i + 1, SIZE),
            $sformatf("a_success=%0b (expected 1)", ok));
    end
    for (int i = 0; i < SIZE; i++) begin
      read_b(ADDR_SIZE'(i), data, valid_ok);
      check(valid_ok == 1 && data == 8'(i * 3 + 1),
            $sformatf("sweep: entry %0d/%0d reads back correctly", i + 1, SIZE),
            $sformatf("b_dout=%0h (expected %0h)", data, 8'(i * 3 + 1)));
    end

    $display("--------------------------------------------------");
    if (errors == 0) $display("ALL %0d CHECKS PASSED", checks);
    else $display("%0d / %0d CHECKS FAILED", errors, checks);

    $finish;
  end

endmodule
