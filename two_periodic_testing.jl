include("TriTiling_Markov_Chain.jl")
include("TriTiling_Graphics.jl")
include("Mixing_and_Measures.jl")
include("MoreDomains.jl")
include("WeightedIterators.jl")
include("ConformalLoopEnsemble.jl")
#=
l = 201
w = 201
alpha = .7


para = CompositeTriTiling(iterate = weighted_composite_iterator,
                          domain_dimensions = [l+3,w+3],
                          composite_domains = [(add_parallelogram!, (l,w,2,2,1))],
                          weight = (i,j,axis) -> color_weight(alpha, alpha, 1, alpha, alpha, alpha,i,j,axis))

reference = deepcopy(para)

composite_initalizer!(para)
composite_initalizer!(reference)

for i in 1:100
    systematic_update!(para)
end

cle = construct_ensemble(reference, rtiling = para)
ht = construct_heights(para, cle)

save_loops_to_luxor_file(cle, "large_desired_horizontal,5.svg", ht = ht, fill_ht = true)

=#

function produce_samples(l, w, alpha)

    #=

    para = PeriodicCompositeTriTiling(iterate = weighted_periodic_iterator,
                            domain_dimensions = [l+3,w+1],
                            composite_domains = [(add_parallelogram!, (l,w,2,1,1))],
                            weight = (i,j,axis) -> color_weight(alpha, alpha, 1, alpha, alpha, alpha,i,j,axis))

    =#

    para = CompositeTriTiling(iterate = weighted_composite_iterator,
                                      domain_dimensions = [l+3,w+3],
                                      composite_domains = [(add_parallelogram!, (l,w,2,2,1))],
                                      weight = (i,j,axis) -> one_periodic_weight(alpha, 1, alpha, i,j,axis))


    reference = deepcopy(para)

    composite_initalizer!(para)

    #=
    for i in 1:82
        #para.set_up!(para, i,11, 2 - para.get_up(para, i,11))
        #para.set_down!(para, i, 12, 2 - para.get_down(para, i,12))
        para.set_up!(para, i,41, 2 - para.get_up(para, i,41))
        para.set_down!(para, i, 42, 2 - para.get_down(para, i,42))
        #para.set_up!(para, i,71, 2 - para.get_up(para, i,71))
        #para.set_down!(para, i, 72, 2 - para.get_down(para, i,72))
    end
    =#
    composite_initalizer!(reference)
    return para, reference
end

xvals = 16:65
interactions = []
magnetizations = []
#=
for i in 1:50
    global rng_seeds
    rng_seeds[1] = Future.randjump(Random.MersenneTwister(0), i*big(10)^20)
    para, reference = produce_samples(81, 81, .15 + i/100)
    for j in 1:50
        systematic_update!(para)
    end
    push!(interactions, interaction(para, reference))
    cle = construct_ensemble(reference, rtiling = para)
    ht = construct_heights(para, cle)
    push!(magnetizations, magnetization(ht))
    save_loops_to_luxor_file(cle, "ht_testing/doubly_periodic_criticality_temperature_test"*string(i)*".svg", ht = ht, fill_ht = true)
    println(i)
end
=#

#the color weight produces criticality for singly periodic

#the alpha, 1, alpha produces criticality for singly periodic

#Let's try double periodicity

