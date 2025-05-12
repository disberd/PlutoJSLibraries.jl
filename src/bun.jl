# --entrypoints
function add_flag!(bin::Cmd, ::Val{:entrypoints}, vals::Union{AbstractString, Vector{<:AbstractString}})
    f(s) = let
        isfile(s) || throw(ArgumentError("Entrypoint $s is not a file"))
        abspath(s)
    end
    push!(bin.exec, "--entrypoints")
    vs = vals isa AbstractString ? [vals] : vals
    for v in vs
        push!(bin.exec, f(v))
    end
    nothing
end

# --outfile
function add_flag!(bin::Cmd, ::Val{:outfile}, val::AbstractString)
    push!(bin.exec, "--outfile", abspath(val))
    nothing
end

# --target
function add_flag!(bin::Cmd, ::Val{:target}, val::AbstractString)
    val in ("browser", "bun", "node") || throw(ArgumentError("Invalid target: $val.\nValid targets are: `browser`, `bun`, `node`."))
    push!(bin.exec, "--target", val)
    nothing
end

# --minify
function add_flag!(bin::Cmd, ::Val{:minify}, val)
    val isa Bool || throw(ArgumentError("Only boolean values are accepted for the `minify` option."))
    if val
        push!(bin.exec, "--minify")
    end
    nothing
end

# --sourcemap
function add_flag!(bin::Cmd, ::Val{:sourcemap}, val)
    val in ("inline", "external", "both", "none") || throw(ArgumentError("Invalid sourcemap: $val.\nValid sourcemaps are: `inline`, `external`, `both`, `none`."))
    push!(bin.exec, "--sourcemap", val)
    nothing
end

# --root
function add_flag!(bin::Cmd, ::Val{:root}, val)
    isdir(val) || throw(ArgumentError("Root directory $val is not a directory."))
    push!(bin.exec, "--root", abspath(val))
    nothing
end

# --outdir
function add_flag!(bin::Cmd, ::Val{:outdir}, val)
    isdir(val) || throw(ArgumentError("Output directory $val is not a directory."))
    push!(bin.exec, "--outdir", abspath(val))
    nothing
end

const SUPPORTED_BUILD_FLAGS = (
    :entrypoints,
    :outfile,
    :target,
    :minify,
    :sourcemap,
    :root,
    :outdir
)
function bun_build(; kwargs...)
    BIN = `$(bun()) build`
    for (k, v) in kwargs
        k in SUPPORTED_BUILD_FLAGS || throw(ArgumentError("Unsupported flag provided as keyword argument: $k."))
        isnothing(v) && continue
        add_flag!(BIN, Val(k), v)
        push!(BIN.exec, "--no-external")
    end
    @info BIN
    run(BIN)
end

