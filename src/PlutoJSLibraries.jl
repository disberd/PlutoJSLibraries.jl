module PlutoJSLibraries

using Bun_jll: Bun_jll, bun
using HypertextLiteral: HypertextLiteral, @htl
import AbstractPlutoDingetjes
using Scratch: Scratch


include("types.jl")
include("bun.jl")
include("utils.jl")

export create_bundle

function create_bundle(library::String; outfile, imports = nothing, exports = nothing, kwargs...)
    isabspath(outfile) || (outfile = joinpath(pwd(), outfile))
    mktempdir() do dir
        cd(dir) do
            run(`$(bun()) init -y`)
            filename = joinpath(dir, "entrypoint.js")
            create_entrypoint(library; filename, imports, exports)
            bun_build(;entrypoints = filename, outfile, kwargs...)
        end
    end
end

# Identify a remote JS ESM module to be imported when shown in a script. The `extract` argument, if non-empty, will be the name of the property of the remote module to extract
struct _ImportedRemoteJS
    src::String
    extract::String
end
_ImportedRemoteJS(src) = _ImportedRemoteJS(src, "")

function Base.show(io, m::MIME"text/javascript", i::_ImportedRemoteJS)
    write(io, 
        "(await import($(repr(i.src))))"
    )
    if !isempty(i.extract)
        # Extract specific field from the module
        write(io, ".$(i.extract)")
    end
end


# Identify a local (on filesystem) JS ESM module to be imported when shown in a script. The `extract` argument, if non-empty, will be the name of the property of the local module to extract
struct _ImportedLocalJS
    published
    extract::String
    function _ImportedLocalJS(published, extract::AbstractString = "")
        @nospecialize
        new(published, extract)
    end
end


function Base.show(io, m::MIME"text/javascript", i::_ImportedLocalJS)
    write(io, 
        """
        (await (() => {
        window.created_imports = window.created_imports ?? new Map();
        let code = """
    )
    Base.show(io, m, i.published)

    write(io,
        """;
        if(created_imports.has(code)){
            return created_imports.get(code);
        } else {
            let blob_promise = new Promise((resolve, reject) => {
                const reader = new FileReader();
                reader.onload = async () => {
                    try {
                        resolve(await import(reader.result));
                    } catch(e) {
                        reject();
                    }
                }
                reader.onerror = () => reject();
                reader.onabort = () => reject();
                reader.readAsDataURL(
                    new Blob([code], {type : "text/javascript"}))
                });
                created_imports.set(code, blob_promise);
                return blob_promise;
            }
        })())
        """
    )
    if !isempty(i.extract)
        # Extract specific field from the module
        write(io, ".$(i.extract)")
    end
    return nothing
end

function import_local_js(code::AbstractString, extract::AbstractString = "")
    code_js = 
        try
        AbstractPlutoDingetjes.Display.published_to_js(code)
    catch e
        @warn "published_to_js did not work" exception=(e,catch_backtrace()) maxlog=1
        repr(code)
    end

    _ImportedLocalJS(code_js, extract)
end

struct _ImportedHybridJS
    object::String
    key::String
    fallback::_ImportedRemoteJS
end


function Base.show(io::IO, m::MIME"text/javascript", i::_ImportedHybridJS)
    write(io, "window.$(i.object)?.['$(i.key)'] ??")
    show(io, m, i.fallback)
end

end # module PlutoJSLibraries
