AES-128 Encryption Core: A Detailed Technical Report
Author: Aditya Singh
Target Platform: Xilinx Artix-7 AC701 Evaluation Platform
Development Tool: Xilinx Vivado Design Suite 2025.1

1. Project Overview and Design Philosophy
This report provides a comprehensive technical description of a hardware-based AES-128 encryption core implemented in the Verilog HDL. The primary objective was to architect a secure, efficient, and reusable IP (Intellectual Property) core for FPGA implementation, capable of performing high-speed data encryption as specified by the FIPS-197 standard. The core is designed to encrypt one 128-bit data block using a 128-bit key. The chosen architecture prioritizes a balance between hardware resource utilization and performance, making it suitable for a wide range of applications where dedicated hardware acceleration for cryptography is required.

Design Philosophy:
An iterative architecture was selected over a fully unrolled (pipelined) one. While an unrolled pipeline offers higher throughput (one block encrypted per clock cycle after an initial latency), it consumes significantly more hardware resources (approximately 10x the logic). The iterative design uses a single round's datapath repeatedly, controlled by a Finite State Machine (FSM), offering a compact and resource-efficient solution. The encryption of a single block is completed in 11 clock cycles.

2. System Architecture and Interfaces
The AES core employs a modular, hierarchical design, which is fundamental for complex digital systems. This approach isolates functionality, simplifies debugging, and enhances code maintainability. The system is composed of a top-level controller (aes_core) that integrates several specialized sub-modules responsible for the specific AES transformations.

3. Module Descriptions
3.1 aes_core.v - The Main Controller
This module is the central nervous system of the design. It contains the FSM, the main state register (state_reg), and connects all sub-modules to form the complete datapath.

Finite State Machine (FSM): The operation is governed by a 5-state Moore FSM. State transitions are determined by the current state and the round_counter.

Datapath: The module implements the ShiftRows (a permutation of wires) and AddRoundKey (a 128-bit XOR) transformations directly as combinational logic. It instantiates the other, more complex modules to complete the round's data path.

3.2 key_expansion.v - Round Key Generator
This module generates the 11 unique 128-bit round keys from the initial secret key.

Implementation: A fully combinational, unrolled architecture was chosen for performance. A generate for loop creates 10 distinct hardware blocks, one for each round's key generation (Rounds 1-10). This avoids combinational loops and allows Vivado to synthesize a highly parallel and efficient circuit.

g() Function: The core of the key schedule is the non-linear g() function. Within each generated block, dedicated S-Box instances are created to perform the SubWord step on a rotated version of the previous word (RotWord), which is then XORed with a round constant (Rcon). This structure ensures that all round keys are calculated simultaneously.

Output: The final stage is a 11-to-1 multiplexer that selects the appropriate 128-bit key based on the round input, providing the correct key to the aes_core for each cycle.

3.3 mix_columns.v - The MixColumns Transformation
This module implements the diffusion layer of AES, performing a matrix multiplication on each column of the state within the Galois Field GF(2⁸).

Galois Field Multiplication: The complex mathematics are reduced to simple hardware operations. Multiplication by 2 (xtime) is implemented as a 1-bit left shift, followed by a conditional XOR with 8'h1B if the original byte's most significant bit was 1. Multiplication by 3 is then simply (byte * 2) ^ byte.

Parallelism: A generate block is used to create 16 parallel instances of this multiplication logic, one for each byte of the input state.

Logic: The results of the multiplications are combined (XORed) according to the fixed AES MixColumns matrix to produce the final 128-bit output state. The entire module is purely combinational.

3.4 sbox.v - The SubBytes Transformation
This module provides the critical non-linear substitution step that forms the cornerstone of AES's security.

Implementation for Synthesis: To create a robust and reliable hardware ROM, the S-Box is implemented as a large combinational always @(*) block with a 256-entry case statement. This provides an explicit, unambiguous description of the lookup table.

Synthesis in Vivado: Vivado's synthesis engine is highly optimized for this structure. It recognizes the case statement as a memory and will map it to the most efficient hardware resource available on the Artix-7 FPGA. This could be a dedicated Block RAM (BRAM) for dense storage or distributed Look-Up Tables (LUTs) if that results in better overall timing and placement. This method is superior to simulation-only tasks like $readmemh for creating synthesizable hardware.

4. Verification Strategy
A comprehensive, two-tiered verification strategy was employed to guarantee the design's functional correctness.

4.1 Unit Testing
Each sub-module was verified in isolation to catch errors early. The tb_sbox.v is a key example of this methodology. It is a self-contained, self-checking testbench that performs the following sequence:

Loads the official S-Box values from sbox_table.hex into a golden reference memory.

Iterates through all 256 possible 8-bit inputs.

For each input, it drives the S-Box module and compares the output to the golden reference.

Reports any mismatches and provides a final summary, confirming the flawlessness of this critical component.

4.2 Top-Level Integration Testing
The tb_aes.v testbench validates the entire integrated aes_core. The test vector used (plaintext, key, and expected ciphertext) is taken directly from the Appendix of the official FIPS-197 standard. This ensures the implementation is being tested against a globally recognized, correct result. The testbench performs a full system check, verifying the FSM control, the datapath logic, and the correct interaction between all sub-modules. Waveform data is dumped to a VCD file, allowing for detailed visual debugging of all internal signals in a waveform viewer like GTKWave or the Vivado simulator.

5. Synthesis and Implementation Results
The design was synthesized and implemented using Vivado for the target Artix-7 AC701 platform. The resource utilization and performance metrics will be populated upon completion of the implementation flow.

Resource Utilization (Post-Implementation):
| Resource | Utilization | Available | Utilization (%) |
| :--- | :--- | :--- | :--- |
| Slice LUTs | TBD | 134,600 | TBD |
| Flip-Flops | TBD | 269,200 | TBD |
| Block RAM (BRAM) | TBD | 365 | TBD |

Performance (Post-Implementation):

Maximum Operating Frequency (Fmax): TBD MHz

Single-Block Encryption Time: 11 cycles / Fmax = TBD ns

6. Conclusion and Future Work
This project successfully demonstrates the creation of a complete, correct, and synthesizable AES-128 encryption core in Verilog. The final design is modular, thoroughly verified against official standards, and optimized for FPGA implementation. It provides a robust and efficient hardware solution for data encryption.

Potential Future Work:

Decryption Core: The architecture could be extended to include a decryption datapath, controlled by the same FSM with a mode select input.

Pipelining: For applications requiring higher throughput, the iterative design could be converted into a fully pipelined, unrolled architecture.

AXI4-Stream Interface: To ease integration into modern SoC designs, a standardized AXI4-Stream wrapper could be added to the core's interface.

