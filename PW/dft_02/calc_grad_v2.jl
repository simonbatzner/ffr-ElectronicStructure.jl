function calc_grad( pw::PWGrid, Potentials, Focc, W::Array{Complex128,2} )
    Ngwx    = size(W)[1]
    Nstates = size(W)[2]
    Ω = pw.Ω
    Ns = pw.Ns
    #
    grad = zeros( Complex128, Ngwx, Nstates )

    H_psi = op_H( pw, Potentials, W )
    for i = 1:Nstates
        grad[:,i] = H_psi[:,i]
        for j = 1:Nstates
            grad[:,i] = grad[:,i] - dot( W[:,j], H_psi[:,i] ) * W[:,j]
        end
        grad[:,i] = Focc[i]*grad[:,i]
    end

    #println("Pass here ...")

    F = diagm(Focc)
    HW = op_H( pw, Potentials, W )
    ℍ = W' * HW
    HFH = ℍ*F - F*ℍ
    #denom = ones(Nstates,Nstates)*2.0
    #ℚ = HFH ./ denom
    ℚ = 0.5*HFH
    grad[:,:] = grad[:,:] + W*ℚ

    return grad
end

#function calc_grad( pw::PWGrid, Potentials, Focc, W::Array{Complex128,2} )
#  Ngwx    = size(W)[1]
#  Nstates = size(W)[2]
#  Ω = pw.Ω
#  Ns = pw.Ns
#  #
#  grad = zeros( Complex128, Ngwx, Nstates )
#
#  F = diagm(Focc)
#  HW = op_H( pw, Potentials, W )
#  ℍ = W' * HW
#  HFH = ℍ*F - F*ℍ
#  denom = ones(Nstates,Nstates)*2.0
#  ℚ = HFH ./ denom
#  grad = (HW - W * ℍ)*F + W*ℚ
#
#  return grad
#end
#
