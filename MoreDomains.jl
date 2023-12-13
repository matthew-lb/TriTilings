include("CompositeDomains.jl")

function curve_boundaries(num_rows::Int64, left_curve::Function, right_curve::Function)
    composite_domains = []
    max_left = 0
    max_right = 1
    for i in 1:num_rows
        center = div(i,2) + 1
        l = Int64(round((num_rows+1) * left_curve(i/(num_rows + 1))))
        r = Int64(round((num_rows+1) * right_curve(i/(num_rows + 1))))
        if l > r
            throw(ArgumentError(left_curve, "left curve should never exceed right curve"))
        end
        if (r - l)%2 == 0
            r += 1
        end
        if center + r > max_right
            max_right = center + r
        end
        if center + l < max_left
            max_left = center + l
        end
        push!(composite_domains, (add_axis_two_line!, r-l, center+l, i))
    end
    for i in 1:length(composite_domains)
        func, len, x, y = composite_domains[i]
        composite_domains[i] = (func, (len, x + 2 - max_left, y + 1))
    end
    return CompositeTriTiling(iterate = composite_iterator,
                              domain_dimensions = [num_rows + 2, 2 + max_right - max_left],
                              composite_domains = composite_domains)
end

