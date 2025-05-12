abstract type JSLibrarySource end

struct NPMLibrary <: JSLibrarySource
    name::String
    version::Union{String, Nothing}
    function NPMLibrary(;name, version = nothing)
        new(name, version)
    end
end

struct LocalLibrary <: JSLibrarySource
    path::String
    name::String
    version::String
    function LocalLibrary(path; name, version)
        name = string(name)
        version = string(version)
        new(path, name, version)
    end
end

struct OfflineLibrary{S <: JSLibrarySource}
    "Source used to download and/or build the library."
    source::S
    "Unique identifier for the library, used as key to store the library in the scratchspace"
    id::String
    "Version of the stored library, also used to store the library in the scratchspace"
    version::VersionNumber
    "Path to the bundled library inside the scratchspace"
    path::String
    function OfflineLibrary(source; id = get_id(source), version = get_version(source))
    end
end