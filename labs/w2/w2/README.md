# Week 2. Warmup: RTL and Verification Fundamentals

## 1. DUT 1: 1-bit 2:1 multiplexer

`rtl/mux2.v` implements:

```verilog
assign y = sel ? b : a;
```

testbench's stimuli:

| Case | sel | a | b | Expected y |
|---|---:|---:|---:|---:|
| 1 | 0 | 0 | 1 | 0 |
| 2 | 1 | 0 | 1 | 1 |
| 3 | 0 | 1 | 0 | 1 |
| 4 | 1 | 1 | 0 | 0 |

## 2. DUT 2: resettable 8-bit register

`rtl/reg8.v` intentionally has **no enable input** here.

```verilog
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        q <= 8'h00;
    else
        q <= d;
end
```

The testbench demonstrates that:

1. asserting `rst_n=0` clears `q` asynchronously;
2. releasing reset does not itself capture `d`;
3. after reset release, `q` captures `d` only on rising clock edges;
4. changing `d` between rising edges does not immediately change `q`.

## 3. Package Files

| File | Purpose |
|---|---|
| `rtl/mux2.v` | 1-bit combinational 2:1 mux |
| `tb/tb_mux2.v` | Self-checking mux testbench |
| `rtl/reg8.v` | 8-bit resettable register |
| `tb/tb_reg8.v` | Self-checking clock/reset testbench |
| `scripts/run_icarus.sh` | Optional Icarus simulation helper |
| `scripts/run_xsim_direct.sh` | Standalone Vivado/XSim helper |
| `scripts/vivado/*.tcl` | Vivado batch wrappers |
| `logs/` | Simulation transcripts |
| `waves/` | Waveform evidence |

## 4. Timescale Policy

Every `.v` source and testbench file contains:

```verilog
`timescale 1ns/1ps
```

Keep these directives consistent. Vivado/XSim 2025.2 can reject elaboration when some modules have a timescale and others do not.

## 5. Simulation Runs

### 5.1 Icarus Verilog

``` bash
$ bash scripts/run_icarus.sh

[INFO] Running mux2 simulation...
VCD info: dumpfile waves/mux2.vcd opened for output.
============================================================
Week 2 mux2 functional simulation started
Expected behavior: sel=0 selects a; sel=1 selects b
============================================================
[PASS] case=1 sel=0 a=0 b=1 y=0
[PASS] case=2 sel=1 a=0 b=1 y=1
[PASS] case=3 sel=0 a=1 b=0 y=1
[PASS] case=4 sel=1 a=1 b=0 y=0
============================================================
[RESULT] MUX2 TEST PASSED
============================================================
tb/tb_mux2.v:75: $finish called at 7000 (1ps)

[INFO] Running reg8 simulation...
VCD info: dumpfile waves/reg8.vcd opened for output.
============================================================
Week 2 reg8 functional simulation started
Expected behavior: rst_n=0 clears q asynchronously;
after release, q captures d only on rising clock edges
============================================================
[PASS] ASYNC_RESET time=2000 q=00
[PASS] RESET_HELD_AT_EDGE time=6000 q=00
[PASS] RESET_RELEASE_NO_CAPTURE time=13000 q=00
[PASS] CAPTURE_A5 time=16000 q=a5
[PASS] HOLD_BETWEEN_EDGES time=21000 q=a5
[PASS] CAPTURE_3C time=26000 q=3c
[PASS] HOLD_AFTER_D_CHANGE time=29000 q=3c
[PASS] ASYNC_RESET_AGAIN time=31000 q=00
[PASS] SECOND_RELEASE_NO_CAPTURE time=33000 q=00
[PASS] CAPTURE_0F time=36000 q=0f
============================================================
[RESULT] REG8 TEST PASSED
============================================================
tb/tb_reg8.v:121: $finish called at 40000 (1ps)

[INFO] Done. Logs are in logs/. VCD waveforms are in waves/.
```

### 5.2 Vivado/XSim

``` bash
$ bash scripts/run_xsim_direct.sh 
[INFO] Running mux2 with standalone XSim tools
[INFO] Running reg8 with standalone XSim tools
[INFO] XSim run complete. Check logs/ and waves/.
```
