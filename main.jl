import BenchmarkTools
import Random
import Core

include("FastParsing.jl")
include("FMM.jl")
include("StrassenMM.jl")



function sanitycheck()
    Random.seed!(1234);
    T16A = rand(0:9, (16,16))
    T16B = rand(0:9, (16,16))
    T100A = rand(0:9, (100,100))
    T100B = rand(0:9, (100,100))
    T1000A = rand(0:9, (1000,1000))
    T1000B = rand(0:9, (1000,1000))
    #T10kA = rand(0:9, (10000,10000))
    #T10kB = rand(0:9, (10000,10000))


    C16 = T16A * T16B
    C100 = T100A * T100B
    C1000 = T1000A * T1000B
    #C10k = T10kA * T10kB

    NaiveC16 = NaiveMM(T16A, T16B)
    NaiveC100 = NaiveMM(T100A, T100B)
    NaiveC1000 = NaiveMM(T1000A, T1000B)
    #NaiveC10k = NaiveMM(T10kA, T10kB)


    StrC16 = StrassenMM(T16A, T16B)
    StrC100 = StrassenMM(T100A, T100B)
    StrC1000 = StrassenMM(T1000A, T1000B)
    #StrC10k = StrassenMM(T10kA, T10kB)


    # Sanity Checking these work correctly
    if C16 != NaiveC16
        println("Naive Failed on n=16")
    elseif C100 != NaiveC100
        println("Naive Failed on n=100")
    elseif C1000 != NaiveC1000
        println("Naive Failed on n=1000")
    #elseif C10k != NaiveC10k
    #   println("Naive Failed on n=10k")
    else
        println("Naive method passed")
    end

    if C16 != StrC16
        println("Strassen Failed on n=16")
        display(C16)
        display(StrC16)
    elseif C100 != StrC100
        println("Strassen Failed on n=100")
    elseif C1000 != StrC1000
        println("Strassen Failed on n=1000")
    #elseif C10k != StrC10k
    #    println("Strassen Failed on n=10k")
    else
        println("Strassen method passed")
    end
    return
end

function main()
    TestA = rand(0:10, (16,16))
    TestB = rand(0:10, (16,16))
    display(TestA)
    display(TestB)
    NativeC = TestA*TestB
    NaiveC = NaiveMM(TestA,TestB)

    println("Evaluating Naive MM")
    if NativeC==NaiveC
        println("MM Success")
        display(NaiveC)
    else
        display(NaiveC)
        display(NativeC)
    end

end

sanitycheck()

