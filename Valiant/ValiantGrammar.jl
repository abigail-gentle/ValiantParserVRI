module ValiantGrammar

using AutoHashEquals

import Base: +

BOOLEAN_MM = false

# symbol type for terminals and nonterminals
abstract type Symbol end

@auto_hash_equals struct Terminal <: Symbol
    identifier::String
end

@auto_hash_equals struct NonTerminal <: Symbol
    identifier::String
end

function Base.:(==)(S::Symbol, str::String)::Bool
    return S.identifier == str
end

function Base.:(==)(str::String, S::Symbol)::Bool
    return S.identifier == str
end

function Base.String(S::Symbol)
    return S.identifier
end

@auto_hash_equals mutable struct Clause
    disjuncts::Set{NonTerminal}
end

function Clause()::Clause
    return Clause(Set{NonTerminal}())
end

function set_symbol(clause::Clause, S::NonTerminal)::Nothing
    push!(clause.disjuncts, S)
    return nothing
end

function in_sym_set(clause::Clause, S::NonTerminal)::Bool
    return (S ∈ clause.disjuncts)
end

function +(a::Clause, b::Clause)::Clause
    D = a.disjuncts ∪ b.disjuncts
    return Clause(D)
end

@auto_hash_equals struct Production
    left::NonTerminal
    right::Union{Pair{NonTerminal,NonTerminal},Pair{Terminal, Nothing}}
end

function Production(L::NonTerminal, R::Terminal)
    return Production(L, R=>nothing)
end

@auto_hash_equals struct Grammar
    nonterminals::Vector{NonTerminal}
    terminals::Vector{Terminal}
    productions::Vector{Production}
    nt_idxs::Dict{NonTerminal, Integer}
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
    for P in G.productions
        println(io, P)
    end

end

function Base.show(io::IO, S::Symbol)
    print(io, "$(S.identifier)")
end

function Base.show(io::IO, P::Production)
    print(io, P.left)
    print(io, " -> ")
    print(io, P.right[1])
    if !(isnothing(P.right[2]))
        print(io, " ", P.right[2])
    end
    println(io)
end

function Base.show(io::IO, S::Clause)
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

function read_grammar(filename::String)
    if isnothing(filename)
        println("No file supplied!")
        return nothing
    end

    # Build grammar struct
    terminals = Vector{Terminal}()
    nonterminals = Vector{NonTerminal}()
    productions = Vector{Production}()
    nt_idxs = Dict{NonTerminal, Integer}()
    open(filename, "r") do grammar
        for line in eachline(grammar)
            linesplit = collect(eachsplit(line, "->"))
            if length(linesplit) != 2
                println("$linesplit too many arrows")
                continue
            end
            lhs, right = strip(linesplit[1]), linesplit[2]
            right = eachsplit(right, "|")
            NT = NonTerminal(lhs)
            push!(nonterminals, NT)
            for rhs in right
                rhs = collect(eachsplit(rhs))
                if length(rhs) == 1
                    term = Terminal(strip(rhs[1]))
                    prod = Production(NT, term)
                    push!(terminals, term)
                    push!(productions, prod)
                elseif length(rhs) == 2
                    r1 = NonTerminal(strip(rhs[1]))
                    r2 = NonTerminal(strip(rhs[2]))
                    prod = Production(NT, (r1 => r2))
                    push!(productions, prod)
                else
                    error("Incorrect RHS length of rule")
                end
            end
        end
    end
    unique!(nonterminals)
    for (i,nt) in enumerate(nonterminals)
        nt_idxs[nt] = i
    end
    unique!(terminals)
    unique!(productions)
    G = Grammar(nonterminals, terminals, productions, nt_idxs)
    global GLOBAL_GRAMMAR = G
    return G
end

function produced_by(s::Terminal, G::Grammar=GLOBAL_GRAMMAR)::Clause
    nts = Clause()
    rhs = s=>nothing
    for P in G.productions
        if P.right == rhs
            nts += P.left
        end
    end
    return nts
end

function Base.:(*)(A::Clause, B::Clause, G::Grammar=GLOBAL_GRAMMAR)
    Ai = Clause()
    for Aj in A
        for Ak in B
            Ajk = (Aj=>Ak)
            for P in G.productions
                if P.right == Ajk
                    set_symbol(Ai, P.left)
                end
            end
        end
    end
    return Ai
end

function Base.:(*)(A::AbstractArray{Clause,2}, B::AbstractArray{Clause,2})::AbstractArray{Clause,2}
    if BOOLEAN_MM
        error("Boolean Matrix multiplication not implemented")
        return
    end
    (n,m) = size(A)
    (m2,p) = size(B)
    if !(n==m==m2==p)
        error("Square matrices please")
        return
    end

    C = Array{Clause, 2}(undef,n,n)
    for i = 1:n
        for j = 1:m
            s = Clause()
            for k = 1:p
                s += A[i,k]*B[k,j]
            end
            C[i,j] = s
        end
    end
    return C
end

function generate_parse_matrix(sentence::String, G::Grammar=GLOBAL_GRAMMAR)
    n = length(sentence)
    words = split(sentence)
    tokens = [Terminal(w) for w in words]
    b = [Clause() for i=1:n+1, j=1:n+1]
    for i = i:n
        b[i,i+1] += produced_by(tokens[i])
    end
    return b
end