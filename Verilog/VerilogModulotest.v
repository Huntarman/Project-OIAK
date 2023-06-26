
module SumCoputationZero(
    input H,
    input H_prim,
    input C_out,
    output S
);
    assign S = (C_out == 1'b0)? H : H_prim;
endmodule

module SumCoputationNormal(
    input H,
    input H_prim,
    input C,
    input C_prim,
    input C_out,
    output S
);
    assign S = (C_out == 1'b0)? H ^ C : H_prim ^ C_prim;
endmodule

module SumComputation  #(parameter N = 8) (
    input [N -1 :0] C,
    input [N -1:0] C_prim,
    input [N - 1:0] H,
    input [N - 1:0] H_prim,
    
    output [N - 1 : 0] sum
);
    genvar i;
    SumCoputationZero zero(
        .H(H[0]),
        .H_prim(H_prim[0]),
        .C_out(C[N-1] | C_prim[N-1]),
        .S(sum[0])
    );

    for (i = 1; i < N; i = i + 1) begin
        SumCoputationNormal norm(
            .H(H[i]),
            .H_prim(H_prim[i]),
            .C(C[i-1]),
            .C_prim(C_prim[i-1]),
            .C_out(C[N-1] | C_prim[N-1]),
            .S(sum[i])
        );
    end
endmodule
    
module ParallelPrefixSingle (
    input G,
    input P,
    input P_prev,
    input G_prev,
    output G_out,
    output P_out
);
    assign P_out = P & P_prev;
    assign G_out = G | (G_prev & P);
endmodule


module ParallelPrefix #(parameter N = 8) (
    input [N -1 : 0] G,
    input [N -1 : 0] P,
    input [N -1 : 0] G_prim,
    input [N -1 : 0] P_prim,

    output [N -1: 0] C,
    output [N -1: 0] C_prim
);
	parameter levels = $clog2(N);
    genvar i;
    genvar j;
    wire [N-1: 0] G_W[levels: 0];
    wire [N-1: 0] P_W[levels: 0];
    wire [N-1: 0] P_prim_W[levels: 0];
    wire [N-1: 0] G_prim_W[levels: 0];

    for ( i = 0; i <= levels; i = i + 1) begin
        assign G_W[i][0] = G[0];
        assign P_W[i][0] = P[0];
        assign G_prim_W[i][0] = G_prim[0];
        assign P_prim_W[i][0] = P_prim[0];
    end

    for (i = 1; i < N; i = i + 1) begin
        if(i[0] == 1'b1) begin
                ParallelPrefixSingle prefixNormal(
                    .G(G[i]),
                    .P(P[i]),
                    .G_prev(G[i-1]),
                    .P_prev(P[i-1]),
                    .G_out(G_W[0][i]),
                    .P_out(P_W[0][i])
                );
                ParallelPrefixSingle prefixPrim(
                    .G(G_prim[i]),
                    .P(P_prim[i]),
                    .G_prev(G_prim[i-1]),
                    .P_prev(P_prim[i-1]),
                    .G_out(G_prim_W[0][i]),
                    .P_out(P_prim_W[0][i])
                );
            end
        else begin
            assign G_W[0][i] = G[i];
            assign P_W[0][i] = P[i];
            assign G_prim_W[0][i] = G_prim[i];
            assign P_prim_W[0][i] = P_prim[i];
        end
    end

    for ( i = 1; i <= levels; i = i + 1) begin
        for ( j = 0; j < N; j = j + 1) begin
            if(j[i] == 1'b1) begin
                localparam index_of_Source = j - (j % (2**i) + 1);

                ParallelPrefixSingle prefixNormal(
                    .G(G_W[i-1][j]),
                    .P(P_W[i-1][j]),
                    .G_prev(G_W[i-1][index_of_Source]),
                    .P_prev(P_W[i-1][index_of_Source]),
                    .G_out(G_W[i][j]),
                    .P_out(P_W[i][j])
                );

                ParallelPrefixSingle prefixPrim(
                    .G(G_prim_W[i-1][j]),
                    .P(P_prim_W[i-1][j]),
                    .G_prev(G_prim_W[i-1][index_of_Source]),
                    .P_prev(P_prim_W[i-1][index_of_Source]),
                    .G_out(G_prim_W[i][j]),
                    .P_out(P_prim_W[i][j])
                );
            end

            else begin
            assign G_W[i][j] = G_W[i-1][j];
            assign G_prim_W[i][j] = G_prim_W[i-1][j];
            assign P_W[i][j] = P_W[i-1][j];
            assign P_prim_W[i][j] = P_prim_W[i-1][j];
            end
        end
    end

    for (i = 1; i <= N; i = i + 1) begin
        assign C[i-1] = G_W[levels][i-1];
        assign C_prim[i - 1] = G_prim_W[levels][i-1];
    end

endmodule

module PreProcessingSingle (
    input num1,
    input num2,
    
    output H,
    output G,
    output P
);
    assign H = num1 ^ num2;
    assign G = num1 & num2;
    assign P = num1 | num2;
endmodule

module PreProcessing #(parameter N = 8) (
    input [N - 1: 0] num1,
    input [N - 1: 0] num2,
    input [N - 1: 0] num1_prim,
    input [N : 0] num2_prim,

    output [N - 1: 0] H,
    output [N - 1: 0] G,
    output [N - 1: 0] P,
    output [N - 1: 0] H_prim,
    output [N - 1: 0] G_prim,
    output [N - 1: 0] P_prim
);
    genvar i;
    for (i = 0; i < N; i = i + 1) begin
        PreProcessingSingle preprocessNorm(
            .num1(num1[i]),
            .num2(num2[i]),
            .H(H[i]),
            .G(G[i]),
            .P(P[i])
        );

        PreProcessingSingle preprocessPrim(
            .num1(num1_prim[i]),
            .num2(num2_prim[i]),
            .H(H_prim[i]),
            .G(G_prim[i]),
            .P(P_prim[i])
        );
    end
endmodule
module numbersPrimSingle(
    input num1,
    input num2,
    input k,

    output num1_Prim,
    output num2_Prim
);
    assign num1_Prim = (k == 1'b0) ? num1^num2 : ~(num1 ^ num2);
    assign num2_Prim = (k == 1'b0) ? (num1 & num2) : (num1|num2);
endmodule

module numbersPrim #(parameter N = 8) (
    input [N-1 :0] number1,
    input [N-1 :0] number2,
    input [N-1 :0] k,

    output [N-1: 0] number1_prim,
    output [N: 0] number2_prim
);  
    genvar i;
    assign number2_prim[0] = 1'b0;
    for (i = 0; i < N; i = i + 1) begin
        numbersPrimSingle lol(
            .num1(number1[i]),
            .num2(number2[i]),
            .k(k[i]),
            .num1_Prim(number1_prim[i]),
            .num2_Prim(number2_prim[i+1])
        );
    end
endmodule

module hello_world;
    parameter N = 7;

	reg [N - 1:0] a;
	reg [N - 1:0] b;
	reg [N - 1:0] k;

    wire [N - 1:0] a_prim;
    wire [N : 0] b_prim;

    wire [N - 1:0] H;
    wire [N - 1:0] G;
    wire [N - 1:0] P;

    wire [N - 1:0] H_prim;
    wire [N - 1:0] G_prim;
    wire [N - 1:0] P_prim;

    wire [N -1:0] C;
    wire [N -1:0] C_prim;

    wire [N - 1 :0] SUM;
    reg niepoprawne;
    reg [N - 1 :0] spodziewany_wynik;

    numbersPrim #(N) numbers_Prim(
        .number1(a),
        .number2(b),
        .k(k),
        .number1_prim(a_prim),
        .number2_prim(b_prim)
    );
    
    PreProcessing #(N) preprocess(
        .num1(a),
        .num2(b),
        .num1_prim(a_prim),
        .num2_prim(b_prim),

        .H(H),
        .G(G),
        .P(P),
        .H_prim(H_prim),
        .G_prim(G_prim),
        .P_prim(P_prim)
    );

    ParallelPrefix #(N) parapre(
        .G(G),
        .P(P),
        .G_prim(G_prim),
        .P_prim(P_prim),
        .C(C),
        .C_prim(C_prim)
    );

    SumComputation #(N) sumcomp(
        .H(H),
        .C(C),
        .H_prim(H_prim),
        .C_prim(C_prim),
        .sum(SUM)
    );

    initial begin
		niepoprawne = 0;
            for(k = 3; k < 2**(N-1); k = k + 1) begin
                for(a = 0; a < 2**N-k; a=a+1) begin
                    for(b = 0; b < 2**N-k; b=b+1) begin
                        if(niepoprawne == 0) begin
                            spodziewany_wynik= (a + b) % (2**N-k);
                            #10;
                            $display("Expected: %d, Actual: %d, A: %d, B: %d, K: %d", spodziewany_wynik, SUM, a, b, k);
                            if(spodziewany_wynik != SUM) begin
                                niepoprawne = 1;
                            end
                        end
                    end
                end
            end
            #150;
        end
    
endmodule