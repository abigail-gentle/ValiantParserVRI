# ----- Data Structures -----
module GrammarTools

import Base: *, ∘, +

using AutoHashEquals

export symbol, terminal, nonterminal, production, insideprod, outsideprod, lhs, Grammar, generates, read_grammar, readword
export binary_op, U, producedby, grammarMM, associated_productions, applyrule, producedby, ∘



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

function lhs(P::production)::nonterminal
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

function Base.show(io::IO, S::Set{symbol})
    n = length(S)
    if n == 0
        print(io,"∅")
        return
    end

    print(io, "{")
    for (i,s) in enumerate(S)
        print(io, s)
        if i < n
            print(io, ", ")
        end
    end
    print(io, "}")
end

function Base.show(io::IO, ::MIME"text/plain", S::Set{nonterminal})
    n = length(S)
    if n == 0
        print(io,"∅")
        return
    end

    print(io, "{")
    for (i,s) in enumerate(S)
        print(io, s)
        if i < n
            print(io, ", ")
        end
    end
    print(io, "}")
end


@auto_hash_equals mutable struct Grammar
    nonterminals::Set{nonterminal}
    terminals::Set{terminal}
    productions::Vector{production}
    function Grammar()
        return new(Set{nonterminal}(),Set{terminal}(),Vector{production}())
    end
end
const GLOBAL_GRAMMAR = Ref{Grammar}()

U(A::Set{<:symbol},B::Set{<:symbol}) = union!(A,B)

function U(A::AbstractArray{Set{nonterminal},2}, B::AbstractArray{Set{nonterminal},2})
    n = size(A,1)
    m = size(A,2)
    m2 = size(B,1)
    p = size(B,2)
    if !(n == m == m2 == p)
        print("Non square Matrices")
        return nothing
    end
    for i = 1:n
        for j=1:n
            U(A[i,j],B[i,j])
        end
    end
    return A
end

+(A::AbstractArray{Set{nonterminal}}, B::AbstractArray{Set{nonterminal}}) = U(A,B)
    
function applyrule(P::production)::Union{terminal, Pair{nonterminal,nonterminal}}
    return P.rule[2]
end

function associated_productions(G::Grammar, NT::nonterminal)
    prods = filter((p -> p.rule[1] == NT), G.productions)
    return prods
end

function generates(G::Grammar, t::String)::Union{Nothing,Vector{production}}
    s = terminal(t)
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

function generates(G::Grammar, s::terminal)::Union{Nothing,Vector{production}}
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

function generates(G::Grammar, s::Pair{nonterminal,nonterminal})::Union{Nothing,Vector{production}}
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

function producedby(G::Grammar, s::Union{String, terminal, Pair{nonterminal, nonterminal}})::Vector{nonterminal}
    gens = generates(G,s)
    Ps = map(p->lhs(p), gens)
    return Ps
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
            linesplit = collect(eachsplit(line, "->"))
            if length(linesplit) != 2
                println("$linesplit too many arrows")
                continue
            end
            lhs, right = strip(linesplit[1]), linesplit[2]
            right = eachsplit(right, "|")
            NT = nonterminal(lhs)
            push!(G.nonterminals, NT)
            for rhs in right
                rhs = collect(eachsplit(rhs))
                if length(rhs) == 1
                    term = terminal(strip(rhs[1]))
                    prod = production(NT, term)
                    push!(G.terminals, term)
                    push!(G.productions, prod)
                elseif length(rhs) == 2
                    r1 = nonterminal(strip(rhs[1]))
                    r2 = nonterminal(strip(rhs[2]))
                    prod = production(NT, (r1 => r2))
                    push!(G.productions, prod)
                else
                    error("Incorrect RHS length of rule")
                end
            end
        end
    end
    GLOBAL_GRAMMAR[] = G
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

function grammarMM(G::Grammar, A::Matrix{Set{nonterminal}}, B::Matrix{Set{nonterminal}})::Union{Nothing,Matrix{Set{nonterminal}}}
    n = size(A,1)
    m = size(A,2)
    m2 = size(B,1)
    p = size(B,2)

    C = [Set{nonterminal}() for i = 1:n, j = 1:p]
    if m != m2
        print("Incompatible Matrices")
        return nothing
    end
    for i = 1:n
        for k = 1:m
            S = Set{nonterminal}()
            for j = 1:p
                cik = binary_op(G, A[i,j], B[j,k])
                union!(S,cik)
            end
            C[i,k] = S
        end
    end
    return C
end

function grammarMM(A::AbstractArray{Set{nonterminal},2}, B::AbstractArray{Set{nonterminal},2})::Union{Nothing,AbstractArray{Set{nonterminal},2}}
    n = size(A,1)
    m = size(A,2)
    m2 = size(B,1)
    p = size(B,2)

    C = [Set{nonterminal}() for i = 1:n, j = 1:p]
    if m != m2
        print("Incompatible Matrices")
        return nothing
    end
    for i = 1:n
        for k = 1:m
            S = Set{nonterminal}()
            for j = 1:p
                cik = A[i,j] ∘ B[j,k]
                union!(S,cik)
            end
            C[i,k] = S
        end
    end
    return C
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

*(A::AbstractArray{Set{symbol},2},B::AbstractArray{Set{symbol},2}) = grammarMM(A,B)




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
            union!(out, Ai)
        end
    end
    return out
end

function binary_op(A::Set{nonterminal}, B::Set{nonterminal})
    G = GLOBAL_GRAMMAR[]
    out = Set{nonterminal}()
    for Aj in A
        for Ak in B
            Rs = generates(G, Aj=>Ak)
            if isnothing(Rs)
                continue
            end
            Ai = map(p->lhs(p), Rs)
            union!(out, Ai)
        end
    end
    return out
end

∘(A::Set{nonterminal}, B::Set{nonterminal}) = binary_op(A,B)


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

end
