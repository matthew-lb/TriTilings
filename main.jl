using DelimitedFiles
using Printf
using Statistics

include("TriTiling_Markov_Chain.jl")
include("Mixing_and_Measures.jl")
include("MoreDomains.jl")

#Aim for 2 million nodes per region

const domains = [(circle_boundary, (1600)),
           (any_parallelogram, (1399, 1399)),
           (any_parallelogram, (1399, 1399, true)),
           (any_parallelogram, (1399, 1399, true, true)),
           (any_parallelogram, (1600, 1241, false, false)),
           (any_parallelogram, (1600, 1241, true, false)),
           (any_parallelogram, (1600, 1241, false, true)),
           (any_parallelogram, (1600, 1241, true, true)),
           (giant_bibone,      (577)),
           (giant_bibone,      (577, true)),
           (giant_E,           (2000)),
           (ice_cream,         (1600)),
           (up_trapezoid,      (1000, 1401)),
           (up_trapezoid,      (1000, 1401, true)),
           (any_rectangle,     (1000, 1800)),
           (any_rectangle,     (1000, 1800, true))]

const local_points = [[(.5, .5), (.4, .75), (.3, .15), (.85, .7)],
                [(.5, .5), (.1,.6), (.9, .7), (.8, .45)],
                [(.5, .5), (.1,.6), (.9, .7), (.8, .45)],
                [(.5, .5), (.1,.6), (.9, .7), (.8, .45)],
                [(.5, .5), (.1,.6), (.9, .7), (.8, .45)],
                [(.5, .5), (.1,.6), (.9, .7), (.8, .45)],
                [(.5, .5), (.1,.6), (.9, .7), (.8, .45)],
                [(.5, .5), (.1,.6), (.9, .7), (.8, .45)],
                [(.5, .5), (.25, .333), (.75, .666), (.3, .6)],
                [(.5, .5), (.25, .333), (.75, .666), (.3, .6)],
                [(.5, .5), (.3, .12), (.8, .9), (.43, .7)],
                [(.5, .5), (.4, .5), (.3, .15), (.7, .5)],
                [(.5, .5), (.2, .2), (.7, .9), (.5, .9)],
                [(.5, .5), (.2, .2), (.7, .9), (.5, .9)],
                [(.5, .5), (.4, .75), (.12, .15), (.65, .5)],
                [(.5, .5), (.4, .75), (.12, .15), (.65, .5)]]

const lozenge1 = [(0,0), (1,1)]

const lozenge2 = [(0,0), (1,0)]

const lozenge3 = [(0,0), (0,1)]

const lozenge_pair_1a = [(0,0),(1,1),(1,2),(1,0)]

const lozenge_pair_1b = [(0,0),(1,1),(1,0),(2,0)]
                
const lozenge_pair_1c = [(0,0),(1,1),(1,0),(2,0)]
                
const lozenge_pair_2 = [(0,0),(1,0),(2,1),(2,2)]
                
const lozenge_pair_3 = [(0,0),(0,1),(1,0),(2,1)]
                
const lozenge_line_1 = [(i,i) for i in 0:3]

const lozenge_line_2 = [(i,0) for i in 0:3]

const lozenge_line_3 = [(0,i) for i in 0:3]

const lozenge_move_1 = [(0,0), (1,0), (0,1), (1,1)]

const lozenge_move_2 = [(0,0), (0,-1), (1,0), (1,1)]

const lozenge_move_3 = [(0,0), (1,1), (1,0), (2,1)]

shapes = [lozenge1, lozenge2, lozenge3, lozenge_pair_1a, lozenge_pair_1b, lozenge_pair_1c, lozenge_pair_2, lozenge_pair_3, lozenge_line_1, lozenge_line_2, lozenge_line_3, lozenge_move_1, lozenge_move_2, lozenge_move_3]

functions = [is_butterfly, is_triangle]

num_domain = length(domains)

num_shapes = length(shapes) + 5

num_tries = 6

#iters = num_domain*num_tries*num_shapes

updates = 60

radius = 30

sample_size = (2*radius + 1)^2

#all_values = [[["" for i in 1:(4*num_tries)] for j in 1:num_domain] for k in 1:num_shapes]
#just_ratios = [[0.0 for i in 1:(4*num_tries*num_domain)] for k in 1:num_shapes]

function save_result(indic)
    global rng_seeds
    rng_seeds[1] = Future.randjump(Random.MersenneTwister(0), indic*big(10)^20)
    domain_indic = mod(indic, 1:num_domain)
    constructor = domains[domain_indic][1]
    domain = constructor(domains[domain_indic][2]...)
    composite_initalizer!(domain)
    for _ in 1:updates
        systematic_update!(domain)
    end
    indic_rem = div(indic, num_domain)
    shape_indic = mod(indic_rem, 1:num_shapes)
    indic_rem = div(indic_rem, num_shapes)
    num_try = mod(indic_rem, 1:6)
    global all_values
    global just_ratios
    outputs = []
    for j in 1:4
        p,q = local_points[domain_indic][j]
       #println(p,q)
        if shape_indic <= length(shapes)
            ratio = local_ratios(domain, p, q, radius, [shapes[shape_indic]])[1]/sample_size
        elseif shape_indic <= length(shapes) + 3
            ratio = count_butterflys(domain, p, q, radius, shape_indic - length(shapes))/sample_size
        else
            ratio = count_triangles(domain, p, q, radius, (shape_indic - length(shapes) == 4))/sample_size
        end
	push!(outputs, string(shape_indic)*"_"*string(domain_indic)*"_"*string(p)*"_"*string(q)*"_"*string(num_try)*"_"*string(ratio))
        #just_ratios[shape_indic][(domain_indic - 1)*(num_tries * 4) + 4*(num_try-1) + j] = ratio
        #all_values[shape_indic][domain_indic][4*(num_try-1) + j] = string(p)*"-"*string(q)*":"*string(ratio)
    end
    return outputs
end

#=
function save_values_to_file()
    global all_values
    global just_ratios
    ratio_file = "local_ratios.csv"
    values_file = "full_test_results.csv"
    stats_file = "local_ratios_statistics.csv"
    open(ratio_file, "w") do io
        writedlm(io, just_ratios, ",")
    end
    open(values_file, "w") do io
        for i in 1:num_shapes
            writedlm(io, all_values[i], ", ")
        end
    end
    open(stats_file, "w") do io
        writedlm(io, [["min", "max", "upper quantile", "lower quantile", "median", "mean", "std"]])
        stats = [[minimum(just_ratios[i]), maximum(just_ratios[i]), quantile(just_ratios[i], .25), quantile(just_ratios[i], .75), median(just_ratios[i]), mean(just_ratios[i]), std(just_ratios[i])] for i in 1:num_shapes]
        writedlm(io, stats, ", ")
    end
end
=#

outputs = save_result(parse(Int64, ARGS[1]))

for output in outputs
	println(output)
end

#save_values_to_file()
