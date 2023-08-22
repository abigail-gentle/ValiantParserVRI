include("GrammarTools.jl")
using .GrammarTools
include("CYKparser.jl")
using .CYKParser

import .GrammarTools: *

using Random

const VALIANT_LEAF_SIZE = 2

function bool_binary_op(G::Grammar, M::BitArray{3}, X::Integer)
    (n,n,x) = size(M)
    MX = 
    for (p, rule) in enumerate(G.productions)

        for i = 1:n
            for j = i:n
            end
        end
    end
end

function valiant_bool_matrices(G::Grammar, s::String)
    # Length of string
    n = length(s) + 1
    # Take to next power of two
    n2 = nextpow(2,n)
    
    # Create terminals for each terminal in string
    tokens = split(sentence)
    words = [terminal(w) for w in tokens]

    # Enumerate productions
    prod_rules = G.productions
    NTidx = 1:length(prod_rules)

    # Create 3D bitarray where x=nonterminal index, (y,z)=parse matrix
    M = falses(NTidx, n2,n2)

    # iterate over words to fill outside productions
    for (i, w) in enumerate(words)
        for (x, P) in enumerate(prod_rules)
            if P.rule[2] == w
                M[x,i,i+1] = true
            end
        end
    end


    
end

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

function lemma(b, r::Integer)
    (n,m) = size(M)
    if n == 1
        return
    elseif n == 2
        c = b * b
        b + c
        return
    end
    if 2*r < n
        error("lemma: r < n/2")
    end

    upper_left = @view b[0:r, 0:r]
    bottom_right = @view b[n-r:n, n-r:n]
    upper_middle = @view b[0:n-r, n-r,r]
    right_middle = @view b[n-r:r, r:n]
    top_right = @view b[0:n-r, r:n]

    c = upper_middle * right_middle
end

function recursive_valiant_closure(G::Grammar, M)::Matrix{Set{nonterminal}}
    
    (n,m) = size(M)
    n2 = nextpow(2,n)
    diff = n2-n
    if n2 != n
        newM = [Set{nonterminal}() for i = 1:n2, j = 1:n2]
        for i = 1:n
            for j = 1:n
                newM[diff + i, diff + j] = M[i,j]
            end
        end
        M = newM
    end
    display(M)
    r = n2 ÷ 2
    if n2 <= VALIANT_LEAF_SIZE
        return naive_valiant_closure(G,M)
    end
    
end

function valiant_parse(G::Grammar, s::String)::Bool
    parse_matrix = valiant_matrix(G, s)
    closure_matrix = naive_valiant_closure(G, parse_matrix)
    if length(closure_matrix[1,end]) > 0
        return true
    else
        return false
    end
end

function test_binary_op()
    filename1 = "grammar/astroGrammar.txt"
    println("Loading grammar from $filename1")
    G = read_grammar(filename1)
    println(G)

    example_string = "saw stars with telescope"
    println("Verify example string:")
    cyk_table = CYKParse(G, example_string)
    println("CYK Table:")
    display(permutedims(cyk_table))
    # generate valiant's Matrix
    parse_matrix = valiant_matrix(G, example_string)
    closure_matrix = naive_valiant_closure(G, parse_matrix)
    println("Valiant matrix closure:")
    display(closure_matrix)

end

function test_file(sentencefile::String, grammarfile::String)
    G = read_grammar(grammarfile)
    open(sentencefile, "r") do io
        for line in eachline(io)
            out = valiant_parse(G,line)
            if out
                println("Success: $line")
            else
                println("Failed: $line")
            end
        end
    end
end

test_binary_op()
#test_file("astroGrammarValid.txt", "grammar/astroGrammar.txt")
#test_file("LongCNFWords.txt", "CNF.txt")

