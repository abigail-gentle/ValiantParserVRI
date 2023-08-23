module Valiant

include("./GrammarTools.jl");
using .GrammarTools

using LinearAlgebra
using Random

const VALIANT_LEAF_SIZE = 2

function CYKParse(G::Grammar, sentence::String)
    #println("Parsing sentence: \"$sentence\"")
    words = split(sentence)
    tokens = [terminal(word) for word in words]

    # n = length of parse word
    n = length(tokens)

    # Parse table that holds production rules
    parsetable = [Vector{production}() for i=1:n,j=1:n]
    #display(parsetable)

    # Fill terminal Rules
    for (x,t) in enumerate(tokens)
        r = generates(G,t)
        if isnothing(r)
            error("The word $t is not in the grammar")
        else
            for w in r
                push!(parsetable[1,x], w)
            end
        end
    end

    # Fill remaining table
    for l = 2:n
        for s = 1:n - l + 1
            for p = 1:l - 1
                t1 = map(x->lhs(x), parsetable[p,s])
                t2 = map(x->lhs(x), parsetable[l-p,s+p])

                for a in t1
                    for b in t2
                        r = generates(G,a=>b)
                        if !isnothing(r)
                            for w in r
                                # println("Applied rule $w [$l,$s] --> $a[$p,$s] $b[$(l-p),$(s+p)]")
                                push!(parsetable[l,s],w)
                            end
                        end
                    end
                end
            end
        end
    end
    trees = length(parsetable[end,1])
    if trees > 0
        println("--------------------------------------------")
        println("The sentence \"$sentence\" is accepted in the language")
        println("$trees possible parse trees")
        println("--------------------------------------------")
        return parsetable
    else
        # Suppressing printing
        return false
        println("--------------------------------------------")
        println("The sentence is NOT accepted in the language")
        println("--------------------------------------------")
        return false
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
    (n,_) = size(M)
    closure_matrix = [Set{nonterminal}() for _ = 1:n, _ = 1:n]
    Closures = [copy(closure_matrix) for _ = 1:n+1]
    Closures[1] = M
    for i = 2:n + 1
        C = [Set{nonterminal}() for _ = 1:n, _ = 1:n]
        for j = 1:i - 1
            A = Closures[j]
            B = Closures[i - j]
            U(C, grammarMM(G,A,B))
        end
        Closures[i] = C
    end
    trans_close = [Set{nonterminal}() for _ = 1:n, _ = 1:n]
    for close in Closures
        trans_close = U(trans_close, close)
    end
    return trans_close
end

function test()
    filename1 = "grammar/astroGrammar.txt"
    println("Loading grammar from $filename1")
    G = GrammarTools.read_grammar(filename1)
    println(G)

    example_string = "saw stars with telescope"
    println("Verify example string: \"$example_string\"")
    
    println("CYK Parser: ")
    CYKParse(G, example_string)

    println("Naive Valiant Parser: ")
    B = valiant_matrix(G, example_string);

    display(B)

    display(naive_valiant_closure(G, B))

    M = construct_valiant_integer_matrix(G, example_string)
end

test()

end
