LEAF_SIZE = 2

function StrassenR(A,B)
    n = size(A,1)

    if n <= LEAF_SIZE
        # Smallest size matrix to use default matrix multiplication
        return A*B
    end

    new_size = Int(n/2)
    a11 = zeros(Int64, (new_size,new_size))
    a12 = zeros(Int64, (new_size,new_size))
    a21 = zeros(Int64, (new_size,new_size))
    a22 = zeros(Int64, (new_size,new_size))

    b11 = zeros(Int64, (new_size,new_size))
    b12 = zeros(Int64, (new_size,new_size))
    b21 = zeros(Int64, (new_size,new_size))
    b22 = zeros(Int64, (new_size,new_size))

    aTemp = zeros(Int64, (new_size,new_size))
    bTemp = zeros(Int64, (new_size,new_size))

    for i in range(1, new_size)
        for j in range(1, new_size)
            a11[i,j] = A[i, j]
            a12[i,j] = A[i, j + new_size]
            a21[i,j] = A[i + new_size, j]
            a22[i,j] = A[i + new_size, j + new_size]

            b11[i,j] = B[i, j]
            b12[i,j] = B[i, j + new_size]
            b21[i,j] = B[i + new_size, j]
            b22[i,j] = B[i + new_size, j + new_size]
        end
    end

    # Perhaps don't use native implementations for full control of imp.
    aTemp = a11 + a22
    bTemp = b11 + b22
    p1 = StrassenR(aTemp, bTemp) 

    aTemp = a21 + a22
    p2 = StrassenR(aTemp, b11)

    bTemp = b12 - b22
    p3 = StrassenR(a11, bTemp)

    bTemp = b21 - b11
    p4 = StrassenR(a22, bTemp)

    aTemp = a11 + a12
    p5 = StrassenR(aTemp, b22)

    aTemp = a21 - a11
    bTemp = b11 + b12
    p6 = StrassenR(aTemp, bTemp)
    
    aTemp = a12 - a22
    bTemp = b21 + b22
    p7 = StrassenR(aTemp, bTemp)

    c12 = p3 + p5
    c21 = p2 + p4
    c11 = p1 + p4 - p5 + p7
    c22 = p1 + p3 - p2 + p6

    C = zeros(Int64, (n,n))
    for i = 1:new_size
        for j = 1:new_size
            C[i,j] = c11[i,j]
            C[i, j + new_size] = c12[i,j]
            C[i + new_size] = c21[i,j]
            C[i + new_size, j + new_size] = c22[i,j]
        end
    end
    return C
end

function StrassenMM(A,B)

    # Copy matrix into matrix of larger power of two
    # This could be sped up at small sizes by making the matrix smaller and
    # and performing naive MM with the remainder
    n = size(A,1)
    m = nextpow(2,n)
    
    ATemp = zeros(Int64, (m,m))
    BTemp = zeros(Int64, (m,m))

    for i = 1:n
        for j = 1:n
            ATemp[i,j] = A[i,j]
            BTemp[i,j] = B[i,j]
        end
    end

    CTemp = StrassenR(ATemp, BTemp)
    C = zeros(Int64, (n,n))
    for i = 1:n
        for j = 1:n
            C[i,j] = CTemp[i,j]
        end
    end
    return C
end
