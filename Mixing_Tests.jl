using Plots

include("TriTilings.jl")
include("CompositeDomains.jl")
include("TriTiling_Markov_Chain.jl")

function parallelogram_test(l, iterations, step, graphs, graphname)
    x = 1:step:iterations*step
    for graph in 1:graphs
        parallelogram = TriTiling(iterate = composite_iterator,
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

#parallelogram_test(99, 300, 40, 5, "Testing_Mixing_Times_99x99_Parallelogram.pdf")
#parallelogram_test(351, 80, 30, 3, "Testing_Mixing_Times_351x351_Parallelogram.pdf") #250ish updates to reach 1/3-1/3-1/3
parallelogram_test(537, 40, 20, 3, "Testing_Mixing_Times_537x537_Parallelogram.pdf") #400ish updates to reach 1/3-1/3-1/3