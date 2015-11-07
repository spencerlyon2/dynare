module Dynare
##
 # Copyright (C) 2015 Dynare Team
 #
 # This file is part of Dynare.
 #
 # Dynare is free software: you can redistribute it and/or modify
 # it under the terms of the GNU General Public License as published by
 # the Free Software Foundation, either version 3 of the License, or
 # (at your option) any later version.
 #
 # Dynare is distributed in the hope that it will be useful,
 # but WITHOUT ANY WARRANTY; without even the implied warranty of
 # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 # GNU General Public License for more details.
 #
 # You should have received a copy of the GNU General Public License
 # along with Dynare.  If not, see <http://www.gnu.org/licenses/>.
##

export @dynare

function _dynare(modfile)
    # Process modfile
    println(string("Using ", WORD_SIZE, "-bit preprocessor"))
    preprocessor = string(dirname(@__FILE__()), "/preprocessor", WORD_SIZE, "/dynare_m")
    run(`$preprocessor $modfile language=julia output=dynamic`)

    # Load module created by preprocessor
    basename = split(modfile, ".mod"; keep=false)[1]
    Expr(:block, Expr(:call, :include, "$basename.jl"),
                 Expr(:import, symbol("."), symbol(basename)))
end


macro dynare(modelname)
    _dynare(modelname)
end

end  # module
