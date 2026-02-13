

### Discussion

Report 2 uses significantly fewer logic resources than Report 1: ALM utilization dropped ~18 % (111 → 91), combinational ALUTs fell ~12 % (171 → 150), and dedicated registers decreased ~10 % (129 → 116). Notably, all 14 seven-input LUT functions were eliminated, and six-input functions were reduced from 16 to 10, meaning the synthesizer mapped the design into simpler LUTs overall.

The trade-off is a doubling of block memory usage (64 → 128 bits). This indicates the FIFO storage was moved from distributed logic into dedicated block RAM — a common and efficient optimization on Cyclone V, since block RAM is a hard resource that would otherwise go unused. I/O pins (70) and DSP blocks (1) remained unchanged, as expected. Fan-out metrics stayed comparable, with average fan-out rising slightly (2.92 → 3.04), consistent with fewer but more shared logic elements.

Overall, Report 2 represents a more efficient synthesis that trades a small amount of block memory for a meaningful reduction in general-purpose logic utilization.
