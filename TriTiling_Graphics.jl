#################### TIKZ DRAWING ####################
include("TriTilings.jl")
using DelimitedFiles
using Printf

function define_edimers()
    s = "\\def\\edimer{"
    for i in 0:5
        s *= "+("
        s*= string(cos(2*pi*(i+.5)/6)/sqrt(3))
        s*= ","
        s*= string(sin(2*pi*(i+.5)/6)/sqrt(3))
        s*= ") -- "
    end
    for i in 3:7
        s*= "+("
        s*= string(1 + cos(2*pi*(i+.5)/6)/sqrt(3))
        s*= ","
        s*= string(sin(2*pi*(i+.5)/6)/sqrt(3))
        s*= ") -- "
    end
    s *= " cycle}"
    return s
end

function define_sedimers()
    s = "\\def\\sedimer{"
    for i in 5:10
        s *= "+("
        s*= string(cos(2*pi*(i+.5)/6)/sqrt(3))
        s*= ","
        s*= string(sin(2*pi*(i+.5)/6)/sqrt(3))
        s*= ") -- "
    end
    for i in 2:6
        s*= "+("
        s*= string(1/2 + cos(2*pi*(i+.5)/6)/sqrt(3))
        s*= ","
        s*= string(-sqrt(3)/2+sin(2*pi*(i+.5)/6)/sqrt(3))
        s*= ") -- "
    end
    s *= " cycle}"
    return s
end

function define_swdimers()
    s = "\\def\\swdimer{"
    for i in 4:9
        s *= "+("
        s*= string(cos(2*pi*(i+.5)/6)/sqrt(3))
        s*= ","
        s*= string(sin(2*pi*(i+.5)/6)/sqrt(3))
        s*= ") -- "
    end
    for i in 1:5
        s*= "+("
        s*= string(-1/2 + cos(2*pi*(i+.5)/6)/sqrt(3))
        s*= ","
        s*= string(-sqrt(3)/2+sin(2*pi*(i+.5)/6)/sqrt(3))
        s*= ") -- "
    end
    s *= " cycle}"
    return s
end

function latex_preamble(;xscale = 1.0, yscale = 1.0)
    return "\\documentclass[12pt]{amsart}\n\\usepackage{tikz}\n\\begin{document}\n\\begin{tikzpicture}[xscale="*string(xscale)*", yscale ="*string(yscale)*"]"
end

function convert_coors(i1, j1)
    return i1 - j1/2, -j1*sqrt(3)/2
end

function tikz_lattice(tiling; jump = 5, errors_only = true)
    if jump == -1
        return "\n"
    end
    s = ""
    for (i,j) in tiling.iterator_helper_array[1]
        x,y = convert_coors(i,j)
        if !valid_tiling_at(tiling, i, j)
            s *= "\\filldraw[fill=red] ("*string(x)*","*string(y)*") circle (.2cm);\n"
        elseif !errors_only
            s *= "\\filldraw[fill=black] ("*string(x)*","*string(y)*") circle (.2cm);\n"
        end
    end
    return s
end

function tikz_line(i1,j1,i2,j2)
    x1, y1 = convert_coors(i1, j1)
    x2, y2 = convert_coors(i2, j2)
    start_node = "\\filldraw[fill=black] ("*string(x1)*","*string(y1)*") circle (.2cm);\n"
    end_node = "\\filldraw[fill=black] ("*string(x2)*","*string(y2)*") circle (.2cm);\n"
    line = "\\draw ("*string(x1)*","*string(y1)*") -- ("*string(x2)*","*string(y2)*");\n"
    return start_node*end_node*line
end

function tikz_dimer(i1,j1,i2,j2)
    x1, y1 = convert_coors(i1, j1)
    x2, y2 = convert_coors(i2, j2)
    if (y1 == y2) && (x1 < x2)
        return "\\filldraw[fill=blue!20] ("*string(x1)*","*string(y1)*") \\edimer;"
    elseif (y1 == y2) && (x2 < x1)
        return "\\filldraw[fill=blue!20] ("*string(x2)*","*string(y2)*")\\edimer;"
    elseif (x1 < x2) && (y1 > y2)
        return "\\filldraw[fill=blue!50] ("*string(x1)*","*string(y1)*") \\sedimer;"
    elseif (x1 > x2) && (y1 < y2)
        return "\\filldraw[fill=blue!50] ("*string(x2)*","*string(y2)*")\\sedimer;"
    elseif (x1 > x2) && (y1 > y2)
        return "\\filldraw[fill=blue!80] ("*string(x1)*","*string(y1)*")\\swdimer;"
    else
        return "\\filldraw[fill=blue!80] ("*string(x2)*","*string(y2)*")\\swdimer;"
    end
end

function save_matching_to_file(tiling, tikz_func, filename; xscale = 1.0, yscale = 1.0, jump = 5)
    file_text = []
    open(filename, "w") do io
        write(io, latex_preamble(xscale = xscale, yscale = yscale))
        write(io, define_edimers()*"\n")
        write(io, define_sedimers()*"\n")
        write(io, define_swdimers()*"\n")
        l,w = tiling.domain_dimensions
        for (i,j) in tiling.iterator_helper_array[1]
            if get_up(tiling,i,j) == 1
                write(io,tikz_func(i,j,i+1,j+1)*"\n")
            elseif get_up(tiling,i,j) == 2
                write(io,tikz_func(i,j+1,i+1,j+1)*"\n")
            elseif get_up(tiling,i,j) == 3
                write(io,tikz_func(i,j,i,j+1)*"\n")
            end
            if get_down(tiling,i,j) == 1
                write(io,tikz_func(i,j,i+1,j+1)*"\n")
            elseif get_down(tiling,i,j) == 2
                write(io,tikz_func(i,j,i+1,j)*"\n")
            elseif get_down(tiling,i,j) == 3
                write(io,tikz_func(i+1,j,i+1,j+1)*"\n")
            end
        end
        write(io, tikz_lattice(tiling, jump = jump))
        write(io,"\\end{tikzpicture}\n\\end{document}")
    end
end