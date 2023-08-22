# ----- Data Structures -----
# TURNED INTO MODULE IN MAIN FOLDER Grammar.jl
# Variable: A
# Terminal: a
# ProdRule: L -> R
# VarRule: A -> B C 
# TermRule: A -> a
# EmptyRule: A -> ε
using AutoHashEquals
abstract type symbol end

@auto_hash_equals struct terminal <: symbol
    identifier::String
end

@auto_hash_equals struct nonterminal <: symbol
    identifier::String
end

function Base.:(==)(S::Symbol, str::String)
    return S.identifier == str
end
function Base.:(==)(str::String, S::Symbol)
    return S.identifier == str
end

function Base.String(sym::symbol)
    return sym.identifier
end

abstract type production end

@auto_hash_equals struct insideprod <: production
    rule::Pair{nonterminal, Pair{nonterminal, nonterminal}}
end

@auto_hash_equals struct outsideprod <: production
    rule::Pair{nonterminal, terminal}
end

function production(A::nonterminal, B::terminal)
    return outsideprod(A=>B)
end

function production(A::nonterminal, B::Pair{nonterminal,nonterminal})
    return insideprod(A=>B)
end

function lhs(P::production)
    return P.rule[1]
end

function Base.show(io::IO, S::symbol)
    print(io, "$(S.identifier)")
end

function Base.show(io::IO, P::outsideprod)
    print(io, "$(P.rule[1]) --> $(P.rule[2])")
end

function Base.show(io::IO, P::insideprod)
    print(io, "$(P.rule[1]) --> $(P.rule[2][1]) $(P.rule[2][2])")
end

@auto_hash_equals mutable struct Grammar
    nonterminals::Set{nonterminal}
    terminals::Set{terminal}
    productions::Vector{production}
    function Grammar()
        return new(Set{nonterminal}(),Set{terminal}(),Vector{production}())
    end
end

function generates(G::Grammar, s::terminal)
    gens = production[]
    for rule in G.productions
        if s == rule.rule[2]
            append!(gens, [rule])
        end
    end
    if length(gens) == 0
        return nothing
    end
    return gens
end

function generates(G::Grammar, s::Pair{nonterminal,nonterminal})
    gens = production[]
    for rule in G.productions
        if s == rule.rule[2]
            append!(gens, [rule])
        end
    end
    if length(gens) == 0
        return nothing
    end
    return gens
end

function read_grammar(filename::String)
    if isnothing(filename)
        println("No file supplied!")
        return nothing
    end

    # Build grammar struct
    G = Grammar()
    open(filename, "r") do grammar
        for line in eachline(grammar)
            linesplit = collect(eachsplit(line, " -> "))
            if length(linesplit) != 2
                println("$linesplit too many arrows")
                continue
            end
            lhs, right = linesplit[1], linesplit[2]
            right = eachsplit(right, " | ")
            NT = nonterminal(lhs)
            push!(G.nonterminals, NT)
            for rhs in right
                rhs = collect(eachsplit(rhs))
                if length(rhs) == 1
                    term = terminal(rhs[1])
                    prod = production(NT, term)
                    push!(G.terminals, term)
                    push!(G.productions, prod)
                elseif length(rhs) == 2
                    r1 = nonterminal(rhs[1])
                    r2 = nonterminal(rhs[2])
                    prod = production(NT, (r1 => r2))
                    push!(G.productions, prod)
                else
                    error("Incorrect RHS length of rule")
                end
            end
        end
    end
    return G
end

function readword(filename)
    if isnothing(filename)
        println("No file supplied!")
        return nothing
    end
    rewords = Set{String}()
    open(filename, read) do input
        words = readlines(input)
        for word in words
            push!(rewords, word)
        end
        return rewords
    end
end




function grammarMM(P::Set{production}, A::Matrix{Set{symbol}},B::Matrix{Set{symbol}})
    n = size(A)[1]
    C = Array{Set{symbol}, 2}()
    for i = 1:n
        for j = i:n
            c = Set{symbol}()
            for k = 1:n
                o = binary_op(P, A[i,k],B[k,j])
                union(c, o)
            end
            C[i,j] = c
        end
    end
    return C

end

function Base.show(io::IO,G::Grammar)
    println(io, "NonTerminals:")
    for NT in G.nonterminals
        print(io, "$NT, ")
        
    end
    println(io)

    println(io, "Terminals:")
    for T in G.terminals
        print(io, "$T, ")
    end
    println(io)

    println(io, "Production rules:")
    for P in filter(p->isa(p, insideprod),G.productions)
        println(io, P)
    end
    for P in filter(p->isa(p,outsideprod),G.productions)
        println(io, P)
    end
end

function binary_op(G::Grammar, A::Set{nonterminal}, B::Set{nonterminal})
    out = Set{nonterminal}()
    for Aj in A
        for Ak in B
            Rs = generates(G, Aj=>Ak)
            if isnothing(Rs)
                continue
            end
            Ai = map(p->lhs(p), Rs)
            push!(out, Ai)
        end
    end
    if length(out) < 1
        return nothing
    end
    return out
end

function test()
    filename1 = "grammar/astroGrammar.txt"
    println("Loading grammar from $filename1")
    G1 = read_grammar(filename1)
    println(G1)

    filename2 = "grammar/astroGrammarRuleDupe.txt"
    println("Loading grammar from $filename2")
    G2 = read_grammar(filename2)
    println(G2)

    langequiv = G1 == G2
    println("G1 == G2: $langequiv")
end



