using DelimitedFiles
using Printf
using Statistics

#Aim for 2 million nodes per region

num_domain = 16

num_shapes = 19

num_tries = 3

#iters = num_domain*num_tries*num_shapes

updates = 25

radius = 30

sample_size = (2*radius + 1)^2

all_values = [[[] for j in 1:num_domain] for k in 1:num_shapes]
just_ratios = [[] for k in 1:num_shapes]

for i in 0:911
	open("full_output/"*string(i)*".out") do io
		x = read(io, String)
		shape, domain, p, q, num_try, ratio = split(x, "_")
		domain = parse(Int64, domain)
		shape = parse(Int64, shape)
		num_try = parse(Int64, num_try)
		ratio = parse(Float64, ratio)
		push!(just_ratios[shape], ratio)
		push!(all_values[shape][domain], p*"_"*q*"_"*string(num_try)*"_"*string(ratio))
	end
end

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

save_values_to_file()


#save_values_to_file()
