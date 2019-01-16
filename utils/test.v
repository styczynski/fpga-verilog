/*
 * Piotr Styczyński @styczynski
 * Verilog Components Library
 *
 * Verilog test utils.
 *
 * MIT License
 */
 
 /*
  * Define clock with given period
  */
`define defClock(name, period)          \
        always begin                    \
            #(period/2) name = ~name;   \
	    end                             \
        reg name
 
 /*
  * Macro used in place of "initial begin" to start a test block with given name
  */
`define startTest(text)                        \
        integer testNo = 0;                    \
        integer assertionsNo = 0;              \
        initial begin                          \
        $display("\n    [ TEST %s ]\n", text);

 /*
  * Macro to end the test block started by startTest
  */
`define endTest                                                          \
        $display("\n    Total number of assertions: %d", assertionsNo);  \
        $display("    Total number of tests:      %d", testNo);          \
        $finish;                                                         \
        end

/*
 * Define a describe block with given title
 */
`define describe(text)                       \
        $display("%d. %s", testNo+1, text);  \
        testNo = testNo + 1;

/*
 * Assert signal <signal> to be equal to <value>
 */
`define assert(signal, value)                                                       \
        #1;                                                                         \
        assertionsNo = assertionsNo + 1;                                            \
        if (signal !== value) begin                                                 \
            $display("ASSERTION FAILED in %m: signal != value", value);             \
            $display("                        EXPECTED %d GOT %d", value, signal);  \
            $finish;                                                                \
        end