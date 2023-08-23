module CYKParser

include("./GrammarTools.jl");
using .GrammarTools

using Random

export CYKParse

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

function cykgenerate()
    filename1 = "grammar/astroGrammar.txt"
    println("Loading grammar from $filename1")
    G1 = read_grammar(filename1)
    println(G1)
    terminals = G1.terminals
    potentialwords = [String(x) for x in terminals]
    l = 10
    successes = String[]
    while true
        randsentence = join(rand(potentialwords, l), ' ')
        if CYKParse(G1, randsentence)
            push!(successes, randsentence)
            open("grammar/astrogrammarAccepted.txt", "a") do io
                println(io, randsentence)
            end
        end
    end
    println("Found accepted strings:")
    println(join(successes, '\n'))
end

#cykgenerate()
end
