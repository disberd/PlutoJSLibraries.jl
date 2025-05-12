# We explicitly put the UUID so it works easier with PlutoDevMacros
get_scratch!(key = "bundles_cache") = Scratch.get_scratch!(Base.UUID("d3c6423c-1175-4028-8bdf-41078ef7ce07"), key)

function create_entrypoint(library::String; filename = joinpath(pwd(), "entrypoint.js"), imports = nothing, exports = nothing)
    isnothing(imports) && (imports = "* as all")
    isnothing(exports) && (exports = "default all")
    
    imports isa AbstractString && (imports = [imports])
    exports isa AbstractString && (exports = [exports])

    open(filename, "w") do io
        for imprt in imports   
            println(io, "import $imprt from '$library';")
        end
        for exprt in exports
            println(io, "export $exprt;")
        end
    end
    return filename
end