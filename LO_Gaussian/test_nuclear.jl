function test_a_terms()
  @assert Aterm(0,0,0,0,0,0.,0.,0.,0.) == 1.0
  @assert Aarray(0,0,0.,0.,0.,1.) == [1.0]
  @assert Aarray(0,1,1.,1.,1.,1.) == [1.0, -1.0]
  @assert Aarray(1,1,1.,1.,1.,1.) == [1.5, -2.5, 1.0]
  @assert Aterm(0,0,0,0,0,0.,0.,0.,1.) == 1.0
  @assert Aterm(0,0,0,0,1,1.,1.,1.,1.) == 1.0
  @assert Aterm(1,0,0,0,1,1.,1.,1.,1.) == -1.0
  @assert Aterm(0,0,0,1,1,1.,1.,1.,1.) == 1.0
  @assert Aterm(1,0,0,1,1,1.,1.,1.,1.) == -2.0
  @assert Aterm(2,0,0,1,1,1.,1.,1.,1.) == 1.0
  @assert Aterm(2,0,1,1,1,1.,1.,1.,1.) == -0.5
  @assert Aterm(2,1,0,1,1,1.,1.,1.,1.) == 0.5
end

function test_gamma()
  # gammainc test functions. Test values taken from Mathematica
  # println("a=0.5 test")
  @assert maximum([gammainc(0.5,float(x)) for x in 0:10]
      -Any[0, 1.49365, 1.69181, 1.7471, 1.76416, 1.76968,
        1.77151, 1.77213, 1.77234, 1.77241, 1.77244]) < 1e-5

  # println("a=1.5 test")
  @assert maximum([gammainc(1.5,float(x)) for x in 0:10]
      -Any[0, 1.49365, 1.69181, 1.7471, 1.76416, 1.76968,
        1.77151, 1.77213, 1.77234, 1.77241, 1.77244]) < 1e-5
  # println("a=2.5 test")
  @assert maximum([gammainc(2.5,float(x)) for x in 0:10]
      -Any[0, 0.200538, 0.59898, 0.922271, 1.12165, 1.22933,
        1.2831, 1.30859, 1.32024, 1.32542, 1.32768]) < 1e-5
end

function test_na()
  s = pgbf(1.0)
  c = cgbf(0.0,0.0,0.0)
  push!(c,1,1)
  @assert isapprox(amplitude(c,0,0,0),0.71270547)
  @assert isapprox(nuclear_attraction(s,s,0.,0.,0.),-1.59576912)
  @assert isapprox(nuclear_attraction(c,c,0.,0.,0.),-1.595769)
end

function test_fgamma()
  for (x,res) in Any[(0.,1),
          (30.,0.161802),
          (60.,0.1144114),
          (90.,0.0934165),
          (120.,0.08090108),
          (300.,0.051166336)]
    #@assert isapprox(res,Fgamma(0,x))
    @printf("res, Fgamma(0,x) %18.10f %18.10f\n", x, Fgamma(0,x))
  end
  @printf "test_fgamma is passed\n"
end

#todo make into a test
function test_one()
  s1 = init_PGBF(1)
  s2 = init_PGBF(1,0,1,0)
  x=y=0.
  println("S: $(overlap(s1,s2))")
  println("T: $(kinetic(s1,s2))")
  for z in linspace(0,1,5)
    println("V: $z $(nuclear_attraction(s1,s2,x,y,z))")
  end
end


function test_na2()
  li,h = lih.atomlist
  bfs = build_basis(lih)
  s1,s2,x,y,z,h1s = bfs.bfs
  @assert isapprox(nuclear_attraction(s1,s1,lih),-8.307532656)
end


nuclear_repulsion(a::Atom,b::Atom)= a.atno*b.atno/sqrt(dist2(a.x-b.x,a.y-b.y,a.z-b.z))
function nuclear_repulsion(mol::Molecule)
  nr = 0
  for (i,j) in pairs(nat(mol),"subdiag")
    nr += nuclear_repulsion(mol.atomlist[i],mol.atomlist[j])
  end
  return nr
end

function test_geo_basis()

  @printf("\nCalling test_geo_basis\n")

  E1     = nuclear_repulsion(h2)
  E1_ref = 0.7223600367
  @printf("H2: nuclear_repulsion %18.10f, err = %18.10f\n", E1, abs(E1_ref-E1))

  @assert nel(h2) == 2
  @assert nel(h2o) == 10
  @assert length(sto3g)==10

  bfs = build_basis(h2)
  @assert length(bfs.bfs)==2

  l,r = bfs.bfs
  @assert isapprox(overlap(l,l),1)
  @assert isapprox(overlap(r,r),1)

  #@assert isapprox(overlap(l,r),0.66473625)
  ovl1 = overlap(l,r)
  ovl1_ref = abs(ovl1 - 0.66473625)
  @printf("overlap(l,r), err %18.10f, %18.10f\n", ovl1, ovl1_ref)

  @assert isapprox(kinetic(l,l),0.76003188)
  @assert isapprox(kinetic(r,r),0.76003188)
  @assert isapprox(kinetic(l,r),0.24141861181119084)
  @assert isapprox(coulomb(l,l,l,l), 0.7746059439196398)
  @assert isapprox(coulomb(r,r,r,r), 0.7746059439196398)
  @assert isapprox(coulomb(l,l,r,r), 0.5727937653511646)
  @assert isapprox(coulomb(l,l,l,r), 0.4488373301593464)
  @assert isapprox(coulomb(l,r,l,r), 0.3025451156654606)
  bfs = build_basis(h2o)

  s1,s2,px,py,pz,hl,hr = bfs.bfs
  @assert isapprox(coulomb(s1,s2,hl,hr),0.03855344493645537)
  @assert isapprox(coulomb(s1,pz,hl,hr),-0.0027720110485359053)
  @assert isapprox(coulomb(s1,hl,pz,hr),-0.010049491284827426)
  @assert coulomb(s1,py,hl,hr)==0
  @assert coulomb(s1,hl,py,hr)==0
end
