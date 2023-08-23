module Valiant

include("GrammarTools.jl")
using .GrammarTools

include("CYKParser.jl")
using .CYKParser

using LinearAlgebra
using Random

const VALIANT_LEAF_SIZE = 2

function valiant_matrix(G::Grammar, sentence::String)::Matrix{Set{nonterminal}}
    tokens = split(sentence)
    words = [terminal(w) for w in tokens]
    n = length(words)
    B = [Set{nonterminal}() for i = 1:n+1, j = 1:n+1]
    for (i, t) in enumerate(words)
        T = producedby(G,t)
        B[i,i+1] = Set{nonterminal}(T)
    end
    return B
end

function construct_valiant_integer_matrix(G::Grammar, sentence::String)::Array{Integer}
    tokens = split(sentence);
    words = [terminal(w) for w in tokens];
    n = nextpow(2, length(words)+1);
    B = UpperTriangular(zeros(Integer, (n,n)));
    nonterminals = collect(G.nonterminals);

    M = zeros(Integer, (n, n, length(nonterminals)))
    for i in eachindex(words)
        T = GrammarTools.producedby(G, words[i]);
        js = Integer[]
        for sym in T
            js = [js; findall(==(sym), nonterminals)]
        end
        for j in js
            M[i,i+1,j] = 1
        end
    end

    return M
end

function naive_valiant_closure(G::Grammar, M::Matrix{Set{nonterminal}})::Matrix{Set{nonterminal}}
    (n,m) = size(M)
    closure_matrix = [Set{nonterminal}() for i = 1:n, j = 1:n]
    Closures = [copy(closure_matrix) for i = 1:n+1]
    Closures[1] = M
    for i = 2:n + 1
        C = [Set{nonterminal}() for i = 1:n, j = 1:n]
        for j = 1:i - 1
            A = Closures[j]
            B = Closures[i - j]
            U(C, grammarMM(G,A,B))
        end
        Closures[i] = C
    end
    trans_close = [Set{nonterminal}() for i = 1:n, j = 1:n]
    for close in Closures
        trans_close = U(trans_close, close)
        #display(trans_close)
    end
    return trans_close
end

function test()
    filename1 = "grammar/astroGrammar.txt"
    println("Loading grammar from $filename1")
    G = read_grammar(filename1)
    println(G)

    example_string = "saw stars with telescope"
    println("Verify example string: \"$example_string\"")
    
    
    B = valiant_matrix(G, example_string);

    display(B)

    display(naive_valiant_closure(G, B))

    M = construct_valiant_integer_matrix(G, example_string)
    #println("M:")
    #display(M)
end

test()

end
