include("GrammarTools.jl");
using .GrammarTools
include("CYKparser.jl");
using .CYKParser

import REPL.Terminals
REPLout = Terminals.TTYTerminal("", stdin, stdout, stderr)

function generate_word(G::Grammar)
    start_symbol = G.productions[1].rule[1]
    word = Vector{symbol}()
    append!(word, [start_symbol])
    while length(findall(w -> isa(w, nonterminal), word)) > 0
        i = findfirst(p -> isa(p, nonterminal), word)
        NT = word[i]
        prods = associated_productions(G, NT)
        P = rand(prods, 1)[1]
        RHS = applyrule(P)
        if RHS isa terminal
            RHS = [RHS]
        end
        splice!(word, i, RHS)
    end
    sentence = join(word, " ")
    return sentence
end

function generate_word(G::Grammar, min_length::Integer=0)
    start_symbol = G.productions[1].rule[1]
    word = Vector{symbol}()
    append!(word, [start_symbol])
    #print(join(word, " "))
    while length(findall(w -> isa(w, nonterminal), word)) > 0
        i = findfirst(p -> isa(p, nonterminal), word)
        NT = word[i]
        prods = associated_productions(G, NT)
        P = rand(prods, 1)[1]
        RHS = applyrule(P)
        if RHS isa terminal
            RHS = [RHS]
        end
        splice!(word, i, RHS)
        
        if length(findall(w -> isa(w, nonterminal), word)) == 0 && length(word) < min_length
            L = length(word) 
            t = 1
            while t <= L
                i = rand(1:length(word))
                if word[i] isa terminal
                    P = producedby(G, word[i])
                else 
                    try
                        P = producedby(G, word[i]=>word[i+1])
                    catch
                        try
                            P = producedby(G, word[i]=>word[i-1])
                        catch
                            continue
                        end
                    end
                end
                NT = rand(P, 1)
                splice!(word, i, NT)
                t += 1
            end
            
            #Terminals.clear_line(REPLout)
            #print(join(word, " "))
        end
    end
    sentence = join(word, " ")
    return sentence
end

function generate_words(G::Grammar, filename::String, i::Integer = 1, min_length::Integer=0)
    existing_sentences = String[]
    try
        existing_sentences = readlines(filename)
    catch
    end

    j = 1
    while j <= i 
        sentence = generate_word(G, min_length)
        open(filename, "a") do io
            if sentence ∉ existing_sentences
                append!(existing_sentences, [sentence])
                println(io, sentence)
                j += 1
            end
        end
    end
end

function CNFTest()
    G1 = read_grammar("CNF.txt")
    generate_words(G1, "LongCNFWords.txt", 5, 1000)
    G2 = read_grammar("grammar/astroGrammar.txt")
    generate_words(G2, "LongAstroWords.txt", 5, 1000)

    #Verify
    fails = 0
    println("Testing LongAstroWords")
    open("LongAstroWords.txt", "r") do io
        for sentence in eachline(io)
            T = CYKParse(G2, sentence)
            if T == false
                println("Failed to parse")
                fails += 1
            else
                println("Sentence in grammar")
            end
        end
    end
    print("Failed parses: $fails")

    fails = 0
    println("Testing LongCNFWords")
    open("LongCNFWords.txt", "r") do io
        for sentence in eachline(io)
            T = CYKParse(G1, sentence)
            if T == false
                println("Failed to parse")
                fails += 1
            else
                println("Sentence in grammar")
            end
        end
    end
    print("Failed parses: $fails")
end

CNFTest()





