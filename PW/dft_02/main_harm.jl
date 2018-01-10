include("../common/PWGrid_v02.jl")
include("../common/ortho_gram_schmidt.jl")
include("../common/wrappers_fft.jl")

include("EnergiesT.jl")
include("PotentialsT.jl")
include("gen_dr.jl")
include("init_pot_harm_3d.jl")
include("op_K.jl")
include("op_V_loc.jl")
include("op_H.jl")
include("calc_rho.jl")
include("calc_grad.jl")
include("calc_Energies.jl")
include("KS_solve_Emin_sd.jl")
include("KS_solve_Emin_cg.jl")
include("Poisson_solve.jl")
include("LDA_VWN.jl")
include("Kprec.jl")

include("diag_lobpcg.jl")
include("KS_solve_SCF.jl")

include("andersonmix.jl")
include("KS_solve_SCF_andersonmix.jl")

include("get_ub_lb_lanczos.jl")
include("KS_solve_ChebySCF.jl")
include("chebyfilt.jl")
include("norm_matrix_induced.jl")

function test_main( Ns; method="SCF" )

    const LatVecs = 6.0*diagm( ones(3) )

    pw = PWGrid( Ns, LatVecs )

    const Ω  = pw.Ω
    const r  = pw.r
    const G  = pw.gvec.G
    const G2 = pw.gvec.G2
    const Npoints = prod(Ns)
    const Ngwx = pw.gvecw.Ngwx

    @printf("Ns   = (%d,%d,%d)\n", Ns[1], Ns[2], Ns[3])
    @printf("Ngwx = %d\n", Ngwx)

    const actual = Npoints/Ngwx
    const theor = 1/(4*pi*0.25^3/3)
    @printf("Compression: actual, theor: %f , %f\n", actual, theor)

    #
    # Generate array of distances
    #
    center = sum(LatVecs,2)/2
    dr = gen_dr( r, center )
    #
    # Setup potential
    #
    V_ionic = init_pot_harm_3d( pw, dr )
    print("sum(Vpot)*Ω/Npoints = $(sum(V_ionic)*Ω/Npoints)\n");
    #
    const Nstates = 4
    Focc = 2.0*ones(Nstates)
    
    if method == "SD"
        # This will need a lot of optimization steps
        psi, Energies, Potentials = KS_solve_Emin_sd( pw, V_ionic, Focc, Nstates, NiterMax=10 )
    elseif method == "CG"
        psi, Energies, Potentials = KS_solve_Emin_cg( pw, V_ionic, Focc, Nstates, NiterMax=1000 )
    elseif method == "SCF"
        Energies, Potentials, psi, evals = KS_solve_SCF( pw, V_ionic, Focc, Nstates, β=0.5 )
    elseif method == "SCF_andersonmix"
        Energies, Potentials, psi, evals = KS_solve_SCF_andersonmix( pw, V_ionic, Focc, Nstates, β=0.5 )        
    elseif method == "ChebySCF"
        Energies, Potentials, psi, evals = KS_solve_ChebySCF( pw, V_ionic, Focc, Nstates, β=0.1 )
    else
        println("ERROR: unknown method: ", method)
        exit()
    end

    #psi, Energies, Potentials = KS_solve_Emin_cg( pw, V_ionic, Focc, Nstates, NiterMax=1000 )

    if method == "SD" || method == "CG"
        Y = ortho_gram_schmidt(psi)
        mu = Y' * op_H( pw, Potentials, Y )
        evals, evecs = eig(mu)
        Psi = Y*evecs
    end

    print_Energies(Energies)
    for st = 1:Nstates
        @printf("=== State # %d, Energy = %f ===\n", st, real(evals[st]))
    end
end

#@time test_main( [30, 30, 30], method="SD" )
#@time test_main( [30, 30, 30], method="CG" )
@time test_main( [30, 30, 30], method="SCF" )
@time test_main( [30, 30, 30], method="SCF_andersonmix" )
#@time test_main( [30, 30, 30], method="ChebySCF" )
