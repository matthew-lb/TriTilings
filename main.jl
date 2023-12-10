include("TriTilings.jl")
include("TriTiling_Markov_Chain.jl")
include("CompositeDomains.jl")
include("TriTiling_Graphics.jl")
include("Mixing_and_Measures.jl")

#=
################# MIXING TESTS ##################

#parallelogram_test(99, 300, 40, 5, "Testing_Mixing_Times_99x99_Parallelogram.pdf")
#parallelogram_test(351, 80, 30, 3, "Testing_Mixing_Times_351x351_Parallelogram.pdf") #250ish updates to reach 1/3-1/3-1/3
#parallelogram_test(537, 40, 20, 3, "Testing_Mixing_Times_537x537_Parallelogram.pdf") #400ish updates to reach 1/3-1/3-1/3


################# TILING + COMPOSITE DOMAIN TESTS ##################


k = 30
rectangle = TriTiling(
    iterate = composite_iterator,
    domain_dimensions = [2*k+4, 3*k+4],
    composite_domains = [(add_rectangle!, (2*k, 2*k, 2, 2))]
)

composite_initalizer!(rectangle)

for i in 1:5000
    random_update!(rectangle)
end

save_matching_to_file(rectangle, tikz_dimer, "Random_Rectangle.tex", xscale = .15, yscale = .15, jump = -1)


E = TriTiling(
    iterate = composite_iterator,
    domain_dimensions = [72, 120],
    composite_domains = [(add_rectangle!, (16, 40, 2, 2)),
                         (add_rectangle!, (12, 14, 10, 18)),
                         (add_rectangle!, (12, 28, 16, 30)),
                         (add_rectangle!, (12, 14, 22, 42)),
                         (add_rectangle!, (16, 40, 28, 54))]
)
composite_initalizer!(E)

for i in 1:200
    systematic_update!(E)
end

save_matching_to_file(E, tikz_dimer, "E_Shape.tex", xscale = .15, yscale = .15, jump = -1)



=#

################## MEASURE TESTS ##################

#=

l = 501
parallelogram = TriTiling(iterate = composite_iterator,
                                  domain_dimensions = [l+3,l+3],
                                  composite_domains = [(add_parallelogram!, (l,l,2,2,1))])
composite_initalizer!(parallelogram)

for i in 1:450
    systematic_update!(parallelogram)
end

println(local_ratios(tiling, .1, .2))
println(local_ratios(tiling, .5, .5))
println(local_ratios(tiling, .5, .9))
println(local_ratios(tiling, .8, .6))
=#