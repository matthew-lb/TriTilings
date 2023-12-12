#################### TIKZ DRAWING ####################
include("AbstractCompositeTriTiling.jl")
using DelimitedFiles
using Luxor
using Printf

#################### TIKZ DRAWINGS ####################

function tikz_edimers()
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

function tikz_sedimers()
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

function tikz_swdimers()
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

function tikz_coors(i1, j1)
    return i1 - j1/2, -j1*sqrt(3)/2
end

function latex_preamble(;xscale = 1.0, yscale = 1.0)
    return "\\documentclass[12pt]{amsart}\n\\usepackage{tikz}\n\\begin{document}\n\\begin{tikzpicture}[xscale="*string(xscale)*", yscale ="*string(yscale)*"]"
end

function tikz_lattice(tiling; jump = 5, errors_only = true)
    if jump == -1
        return "\n"
    end
    s = ""
    for (i,j) in tiling.iterator_helper_array[1]
        x,y = tikz_coors(i,j)
        if !valid_tiling_at(tiling, i, j)
            s *= "\\filldraw[fill=red] ("*string(x)*","*string(y)*") circle (.2cm);\n"
        elseif !errors_only
            s *= "\\filldraw[fill=black] ("*string(x)*","*string(y)*") circle (.2cm);\n"
        end
    end
    return s
end

function tikz_line(i1,j1,i2,j2)
    x1, y1 = tikz_coors(i1, j1)
    x2, y2 = tikz_coors(i2, j2)
    start_node = "\\filldraw[fill=black] ("*string(x1)*","*string(y1)*") circle (.2cm);\n"
    end_node = "\\filldraw[fill=black] ("*string(x2)*","*string(y2)*") circle (.2cm);\n"
    line = "\\draw ("*string(x1)*","*string(y1)*") -- ("*string(x2)*","*string(y2)*");\n"
    return start_node*end_node*line
end

function tikz_dimer(i1,j1,i2,j2)
    x1, y1 = tikz_coors(i1, j1)
    x2, y2 = tikz_coors(i2, j2)
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

function save_matching_to_tex_file(tiling, tikz_func, filename; xscale = 1.0, yscale = 1.0, jump = 5)
    file_text = []
    filename = "img/"*filename
    open(filename, "w") do io
        write(io, latex_preamble(xscale = xscale, yscale = yscale))
        write(io, tikz_edimers()*"\n")
        write(io, tikz_sedimers()*"\n")
        write(io, tikz_swdimers()*"\n")
        l,w = tiling.domain_dimensions
        for (i,j) in tiling.iterator_helper_array[1]
            if tiling.get_up(tiling,i,j) == 1
                write(io,tikz_func(i,j,i+1,j+1)*"\n")
            elseif tiling.get_up(tiling,i,j) == 2
                write(io,tikz_func(i,j+1,i+1,j+1)*"\n")
            elseif tiling.get_up(tiling,i,j) == 3
                write(io,tikz_func(i,j,i,j+1)*"\n")
            end
            if tiling.get_down(tiling,i,j) == 1
                write(io,tikz_func(i,j,i+1,j+1)*"\n")
            elseif tiling.get_down(tiling,i,j) == 2
                write(io,tikz_func(i,j,i+1,j)*"\n")
            elseif tiling.get_down(tiling,i,j) == 3
                write(io,tikz_func(i+1,j,i+1,j+1)*"\n")
            end
        end
        write(io, tikz_lattice(tiling, jump = jump))
        write(io,"\\end{tikzpicture}\n\\end{document}")
    end
end

#################### LUXOR DRAWINGS ####################

function luxor_coors(i,j)
    return i - j/2, j*sqrt(3)/2
end

function luxor_hexagon()
    move(Point(cos(2*pi*(.5)/6)/sqrt(3), sin(2*pi*(.5)/6)/sqrt(3)))
    for i in 1:5
        line(Point(cos(2*pi*(i+.5)/6)/sqrt(3), sin(2*pi*(i+.5)/6)/sqrt(3)))
    end
    closepath()
    fillstroke()
end

function luxor_edimer(x,y;col ="aqua", border = false)
    Luxor.translate(Point(x,y))
    move(Point(cos(2*pi*(.5)/6)/sqrt(3), -sin(2*pi*(.5)/6)/sqrt(3)))
    for i in 1:5
        line(Point(cos(2*pi*(i+.5)/6)/sqrt(3), -sin(2*pi*(i+.5)/6)/sqrt(3)))
    end
    for i in 3:7
        line(Point(1+cos(2*pi*(i+.5)/6)/sqrt(3), -sin(2*pi*(i+.5)/6)/sqrt(3)))
    end
    closepath()
    setcolor(col)
    fillpreserve()
    if border
        setline(.2)
        setcolor("red")
    else
        setline(.1)
        setcolor("black")
    end
    strokepath()
end

function luxor_sedimer(x,y; col = "aquamarine2", border = false)
    Luxor.translate(Point(x,y))
    setline(.1)
    move(Point(cos(2*pi*(5.5)/6)/sqrt(3), -sin(2*pi*(5.5)/6)/sqrt(3)))
    for i in 6:10
        line(Point(cos(2*pi*(i+.5)/6)/sqrt(3), -sin(2*pi*(i+.5)/6)/sqrt(3)))
    end
    for i in 2:6
        line(Point(1/2+cos(2*pi*(i+.5)/6)/sqrt(3), sqrt(3)/2-sin(2*pi*(i+.5)/6)/sqrt(3)))
    end
    closepath()
    setcolor(col)
    fillpreserve()
    if border
        setline(.2)
        setcolor("red")
    else
        setline(.1)
        setcolor("black")
    end
    strokepath()
end

function luxor_swdimer(x,y; col = "blue", border = false)
    Luxor.translate(Point(x,y))
    setline(.1)
    move(Point(cos(2*pi*(4.5)/6)/sqrt(3), -sin(2*pi*(4.5)/6)/sqrt(3)))
    for i in 5:9
        line(Point(cos(2*pi*(i+.5)/6)/sqrt(3), -sin(2*pi*(i+.5)/6)/sqrt(3)))
    end
    for i in 1:5
        line(Point(-1/2+cos(2*pi*(i+.5)/6)/sqrt(3), sqrt(3)/2-sin(2*pi*(i+.5)/6)/sqrt(3)))
    end
    closepath()
    setcolor(col)
    fillpreserve()
    if border
        setline(.2)
        setcolor("red")
    else
        setline(.1)
        setcolor("black")
    end
    strokepath()
end

function luxor_dimer(i1,j1,i2,j2; border = false, e_col = "lightblue", se_col = "blue", sw_col = "darkblue")
    border = border && (i1 == 1 || j1 == 1)
    x1, y1 = luxor_coors(i1, j1)
    x2, y2 = luxor_coors(i2, j2)
    if (y1 == y2) && (x1 < x2)
        luxor_edimer(x1, y1, col = e_col, border = border)
    elseif (y1 == y2) && (x2 < x1)
        luxor_edimer(x2, y2, col = e_col, border = border)
    elseif (x1 < x2) && (y1 < y2)
        luxor_sedimer(x1, y1, col = se_col, border = border)
    elseif (x1 > x2) && (y1 > y2)
        luxor_sedimer(x2, y2, col = se_col, border = border)
    elseif (x1 > x2) && (y1 < y2)
        luxor_swdimer(x1, y1, col = sw_col, border = border)
    else
        luxor_swdimer(x2, y2, col = sw_col)
    end
end

function full_matching_luxor(tiling::AbstractCompositeTriTiling, luxor_func; xshift = 0, yshift = 0)
    border = (typeof(tiling) == PeriodicCompositeTriTiling)
    xshift,yshift = luxor_coors(xshift, yshift)
    for (i,j) in tiling.iterator_helper_array[1]
        gsave()
        Luxor.translate(Point(xshift, yshift))
        if tiling.get_up(tiling,i,j) == 1
            luxor_func(i,j,i+1,j+1, border = border)
        elseif tiling.get_up(tiling,i,j) == 2
            luxor_func(i,j+1,i+1,j+1, border = border)
        elseif tiling.get_up(tiling,i,j) == 3
            luxor_func(i,j,i,j+1, border = border)
        end
        grestore()
        gsave()
        Luxor.translate(Point(xshift, yshift))
        if tiling.get_down(tiling,i,j) == 1
            luxor_func(i,j,i+1,j+1, border = border)
        elseif tiling.get_down(tiling,i,j) == 2
            luxor_func(i,j,i+1,j, border = border)
        elseif tiling.get_down(tiling,i,j) == 3
            luxor_func(i+1,j,i+1,j+1, border = border)
        end
        grestore()
    end
end

function save_matching_to_luxor_file(tiling::CompositeTriTiling, luxor_func, filename; xdim = 500, ydim = 500)
    Drawing(xdim, ydim, "img/"*filename)
    full_matching_luxor(tiling, luxor_func)
    finish()
end

function save_matching_to_luxor_file(tiling::PeriodicCompositeTriTiling, luxor_func, filename; xdim = 500, ydim = 500)
    xbound = tiling.domain_dimensions[1] - tiling.shift[1]
    ybound = tiling.domain_dimensions[2] - tiling.shift[2]
    Drawing(xdim, ydim, "img/"*filename)
    origin()
    for xshift in [-xbound, 0, xbound]
        for yshift in [-ybound, 0, ybound]
            full_matching_luxor(tiling, luxor_func, xshift = xshift, yshift = yshift)
        end
    end
    finish()
end