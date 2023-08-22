function NaiveMM(A,B)
    n = size(A,1)
    m = size(A,2)
    m2 = size(B,1)
    p = size(B,2)

    C = zeros(Int64,(n,p))
    if m != m2
        print("Incompatible Matrices")
        return nothing
    end
    for i = 1:n
        for j = 1:m
            s = 0
            for k = 1:p
                s += A[i,k]*B[k,j]
            end
            C[i,j] = s
        end
    end
    return C
end

function CWMM(A,B)

end


function HarrisMM(A,B)
    return
end