function calc_Etot( pw::PWGrid, Vpot, psi::Array{Complex128,2} )

  Ω = pw.Ω
  Npoints = pw.Npoints
  Nstates = size(psi)[2]

  Kpsi = op_K( pw, psi )
  Ekin = 0.0
  for is = 1:Nstates
    Ekin = Ekin + real( dot( psi[:,is], Kpsi[:,is] ) )
  end

  # Calculate in real space
  rho = calc_rho( pw, psi )
  Epot = dot( rho, Vpot ) * Ω/Npoints

  Etot = Ekin + Epot
  return Etot
end
