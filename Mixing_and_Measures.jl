using Plots

include("CompositeDomains.jl")
include("TriTiling_Markov_Chain.jl")
include("MoreDomains.jl")

#const lozenge_pair_1a = [(0,0),(1,1),(1,2),(1,0)]

#const lozenge_pair_1b = [(0,0),(1,1),(1,0),(2,0)]

#const lozenge_pair_1c = [(0,0),(1,1),(1,0),(2,0)]

#const lozenge_pair_2a = [(0,0),(1,0),(2,1),(2,2)]

#const lozenge_pair_2b = [(0,0),(0,1),(1,0),(2,1)]

#const up_triangle = [(0,0), (0, -1), (1,0), (0,1), (1,1), (2,1)]

function parallelogram_test(l, iterations, step, graphs, graphname)
    x = 1:step:iterations*step
    for graph in 1:graphs
        parallelogram = CompositeTriTiling(
                                  domain_dimensions = [l+3,l+3],
                                  composite_domains = [(add_parallelogram!, (l,l,2,2,1))])
        composite_initalizer!(parallelogram)
        type_two_counts = []
        type_three_counts = []
        for _ in 1:iterations
            type_counts = [0, 0, 0]
            for i in 0:(l)
                type_counts[lozenge_type_at(parallelogram, 2 + i, 2 + i)] += 1
            end
            push!(type_two_counts, type_counts[2]/(l+1))
            push!(type_three_counts, type_counts[3]/(l+1))
            for _ in 1:step 
                systematic_update!(parallelogram)
            end
        end
        plot!(x, type_two_counts, label = "Type 2 Graph "*string(graph))
        plot!(x, type_three_counts, label = "Type 3 Graph "*string(graph))    
    end
    xlabel!("Number of Updates")
    ylabel!("Percentage of Dominos Along Main Diagonal")
    title!("Measuring Mixing Time for a "*string(l)*" x "*string(l)*" Parallelogram")
    savefig(graphname)
end

function bibone_test(l, iterations, step, graphname)
    x = 1:step:iterations*step
    bibone = giant_bibone(l)
    composite_initalizer!(bibone)
    type_one_counts = []
    type_two_counts = []
    for _ in 1:iterations
        type_counts = [0, 0, 0]
        for i in 0:(l)
            type_counts[lozenge_type_at(bibone, 2 + 2*l, 2 + l + i)] += 1
        end
        push!(type_two_counts, type_counts[2]/(l+1))
        push!(type_one_counts, type_counts[1]/(l+1))
        for _ in 1:step 
            systematic_update!(bibone)
        end
    end
    plot(x, type_two_counts, label = "Type 2 Tile Count")
    plot!(x, type_one_counts, label = "Type 1 Tile Count")
    xlabel!("Number of Updates")
    ylabel!("Percentage of Dominos Along Short Diagonal")
    title!("Measuring Mixing Time for a "*string(l)*" Side Length Bibone Parallelogram")
    savefig("img/"*graphname)
end

function bibone_test_long(l, iterations, step, graphname)
    x = 1:step:iterations*step
    bibone = giant_bibone(l)
    composite_initalizer!(bibone)
    type_three_counts = []
    type_two_counts = []
    k = div(l, 2)
    for _ in 1:iterations
        type_counts = [0, 0, 0]
        for i in 0:(3*l-1)
            type_counts[lozenge_type_at(bibone, 2 + k + i, 2 + i)] += 1
            type_counts[lozenge_type_at(bibone, 2 + k + 1 + i, 2 + i)] += 1
        end
        push!(type_two_counts, type_counts[2]/(l+1))
        push!(type_three_counts, type_counts[3]/(l+1))
        for _ in 1:step 
            systematic_update!(bibone)
        end
    end
    plot(x, type_two_counts, label = "Type 2 Tile Count")
    plot!(x, type_three_counts, label = "Type 3 Tile Count")    
    xlabel!("Number of Updates")
    ylabel!("Percentage of Dominos Along Center Diagonals")
    title!("Measuring Mixing Time for a "*string(l)*" Side Length Bibone Parallelogram")
    savefig("img/"*graphname)
end

function trapezoid_test(l, iterations, step, graphname)
    x = 1:step:iterations*step
    bibone = giant_bibone(l)
    composite_initalizer!(bibone)
    type_one_counts = []
    type_two_counts = []
    for _ in 1:iterations
        type_counts = [0, 0, 0]
        for i in 0:(l)
            type_counts[lozenge_type_at(bibone, 2 + 2*l, 2 + l + i)] += 1
        end
        push!(type_two_counts, type_counts[2]/(l+1))
        push!(type_one_counts, type_counts[1]/(l+1))
        for _ in 1:step 
            systematic_update!(bibone)
        end
    end
    plot(x, type_two_counts, label = "Type 2 Tile Count")
    plot!(x, type_one_counts, label = "Type 1 Tile Count")
    xlabel!("Number of Updates")
    ylabel!("Percentage of Dominos Along Short Diagonal")
    title!("Measuring Mixing Time for a "*string(l)*" Side Length Bibone Parallelogram")
    savefig("img/"*graphname)
end

function local_ratios(tiling, p, q, radius = 20, subdomains = [])
    l,w = tiling.domain_dimensions
    x = Int64(round(p * w))
    y = Int64(round(q * l))
    type_counts = [0 for _ in 1:(length(subdomains))]
    for i in 0:2*radius
        for j in 0:2*radius
            for k in 1:length(subdomains)
                if is_subdomain_of(tiling, subdomains[k], x - radius + i, y - radius + j)
                    type_counts[k] += 1
                end
            end
        end
    end
    return type_counts
end

function count_butterflys(tiling, p, q, radius = 20, axis = 1)
    l,w = tiling.domain_dimensions
    x = Int64(round(p * w))
    y = Int64(round(q * l))
    count = 0
    for i in 0:2*radius
        for j in 0:2*radius
            if is_butterfly(tiling, x - radius + i, y - radius + j, axis)
                count += 1
            end
        end
    end
    return count
end

function count_triangles(tiling, p, q, radius = 20, is_up = false)
    l,w = tiling.domain_dimensions
    x = Int64(round(p * w))
    y = Int64(round(q * l))
    count = 0
    for i in 0:2*radius
        for j in 0:2*radius
            if is_triangle(tiling, x - radius + i, y - radius + j, is_up)
                count += 1
            end
        end
    end
    return count
end
