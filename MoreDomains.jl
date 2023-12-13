include("CompositeDomains.jl")

#Implement circular

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

function ice_cream(num_rows::Int64)
    return curve_boundaries(num_rows, x->-sqrt(3)/4*sqrt(1-(2x-1)^2), x-> .5 - abs(.5 - x))
end #TEST IT

function circle(num_rows::Int64)
    return curve_boundaries(num_rows, x->-sqrt(3)/4*sqrt(1-(2x-1)^2), x->sqrt(3)/4*sqrt(1-(2x-1)^2))
end #COMPLETE

function any_parallelogram(l::Int64, w::Int64; x_periodic = false, y_periodic = false)
    if (l%2 == 0) && (w%2 == 0)
        throw(DomainError((l,w), "No tiling of the domain with such side lengths exists"))
    end
    if x_periodic || y_periodic
        constructor = PeriodicCompositeTriTiling
    else
        constructor = CompositeTriTiling
    end
    lstart, rstart = 1, 1
    lbound, rbound = l+1, w+1
    if x_periodic
        lstart += 1
        lbound += 2
    end
    if y_periodic
        rstart += 1
        rbound += 1
    end
    return constructor(domain_dimensions = [lbound, rbound],
                       composite_domains = (add_parallelogram!, (l, w, lstart, rstart)))
end #TEST IT

function giant_bibone(l::Int64; singly_periodic = false)
    if l%4 != 1
        throw(DomainError(l, "Tiling of this domain either doesn't exist or is yet to be implemented"))
    end
    #x goes from 2 to 4l + 2 
    #y goes from 1 to 4l + 1 if periodic and 2 to 4l + 2 otherwise
    domain_dimensions = [4l + 3, 4l + 3]
    x,y = 2, 2
    if singly_periodic
        domain_dimensions[1] = 4l + 1
        y = 1
    end
    composite_domains = []
    push!(composite_domains, (add_up_trapezoid!, (l-1, l, x, y)))
    push!(composite_domains, (add_parallelogram!, (l, 3*l, x, y + l, 3)))
    push!(composite_domains, (add_down_trapezoid!, (l-1, l, x + 2*l + 1, y + 2*l + 1)))
    if singly_periodic
        return PeriodicCompositeTriTiling(domain_dimensions = domain_dimensions,
                                          composite_domains = composite_domains,
                                          shift = (0, 2*l + 1))
    end
    return CompositeTriTiling(domain_dimensions = domain_dimensions,
                              composite_domains = composite_domains)
end  #TEST IT

#= TO IMPLEMENT 
function giant_E(approx_num_rows::Int64)
    num_rows = 
    return CompositeTriTiling(domain_dimensions = [72, 120],
                              composite_domains = [(add_rectangle!, (16, 40, 2, 2)),
                                                   (add_rectangle!, (12, 14, 10, 18)),
                                                   (add_rectangle!, (12, 28, 16, 30)),
                                                   (add_rectangle!, (12, 14, 22, 42)),
                                                   (add_rectangle!, (16, 40, 28, 54))]
)
end

function parallelogram_bridge(l1::Int64, w1::Int64, l2::Int64, w2::Int64, l3::Int64, w3::Int64)
end

function any_rectangle(l::Int64, w::Int64; singly_periodic = false)
    if (l%4) != 2
        throw(DomainError(l, "Tiling of this domain does not exist or has not been implemented"))
    end
    push!(composite_domains, (add_))
end 

=#


