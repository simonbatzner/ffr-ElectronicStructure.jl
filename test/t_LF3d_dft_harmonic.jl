using ElectronicStructure
using ElectronicStructure.LagrangeFunction

include("init_pot_harm_3d.jl")

function test_main( ; method = "Emin_cg" )
  # LF parameters
  NN = [25, 25, 25]
  AA = [0.0, 0.0, 0.0]
  BB = [6.0, 6.0, 6.0]

  Npoints = prod(NN)

  # Initialize LF
  LF = init_LF3d_p( NN, AA, BB )
  ΔV = LF.LFx.h * LF.LFy.h * LF.LFz.h

  # Initialize G-vectors
  L = BB - AA
  Gv = GvectorsT( NN, diagm(L) )

  # Parameter for potential
  center = AA + 0.5*(BB-AA)
  # Potential
  ω = 2.0
  V_ionic = init_pot_harm_3d( LF, ω, center )

  Ncols = 4
  Focc = 2.0*ones(Ncols)

  if method == "Emin_cg_sparse"
    #
    ∇2 = get_Laplacian3d_kron(LF)
    precH = prec_mkl_ilu0( -0.5*∇2 + spdiagm(V_ionic) )
    #precH = speye(Npoints)  # for testing unpreconditioned code
    Energies, evecs, Potentials = KS_solve_Emin_pcg( LF, Gv, ∇2, precH,
                                    V_ionic, Focc, Ncols, verbose=true )
    evals = calc_evals( LF, ∇2, Potentials, evecs )
    #
  elseif method == "SCF"
    ∇2 = get_Laplacian3d_kron(LF)
    precH = prec_mkl_ilu0( -0.5*∇2 + spdiagm(V_ionic) )
    #precH = speye(Npoints)
    Energies, evals, evecs, Potentials =
          KS_solve_scf( LF, Gv, ∇2, precH, V_ionic, Focc, Ncols, verbose=true )
    #
  else
    #
    Energies, evecs, Potentials = KS_solve_Emin_cg( LF, Gv, V_ionic, Focc, Ncols, verbose=true )
    evals = calc_evals( LF, Potentials, evecs )
  end

  @printf("\nEigenvalues:\n")
  for i = 1:Ncols
    @printf("%8d %f\n", i, evals[i])
  end

  rho = calc_rho( Focc, evecs )
  @printf( "\nintegRho = %lf\n", sum(rho)*ΔV )

end

@code_native test_main()
#@time test_main(method="Emin_cg_sparse")
@time test_main(method="Emin_cg")
#@time test_main(method="SCF")
