struct GAPPerm{T<:Union{UInt16, UInt32}}
    data::Vector{T}

    function GAPPerm{T}(n::Integer) where T<:Union{UInt16, UInt32}
        @assert 0 < n <= typemax(T)
        data = Vector{T}(undef, n + gaph_s(T) + ptr_s(T))
        data[1 : gaph_s(T)] = reinterpret(T, [gap_header(T(n))])
        data[1+gaph_s(T) : gaph_s(T)+ptr_s(T)] = reinterpret(T, [C_NULL]) # void pointer
        data[1+data_offset(GAPPerm{T}):end] .= T(1):T(n)

        return new{T}(data)
    end

    function GAPPerm{T}(d::AbstractVector{<:Integer}) where T<:Union{UInt16, UInt32}
        n = length(d)

        @assert 0 < n <= typemax(T)
        data = Vector{T}(undef, n + gaph_s(T) + ptr_s(T))
        data[1 : gaph_s(T)] = reinterpret(T, [gap_header(T(n))])
        data[1+gaph_s(T) : gaph_s(T)+ptr_s(T)] = reinterpret(T, [C_NULL]) # void pointer

        data[1+data_offset(GAPPerm{T}):end] .= d

        return new(data)
    end
end

GAPPerm(n::Integer) = GAPPerm{UInt32}(n)
GAPPerm(d::AbstractVector{<:Integer}) = GAPPerm{UInt32}(d)
function gap_header(size::Integer, flags::UInt8, type::UInt8)
    @assert 0 <= size <= 2^48
    return (UInt64(size)<<16) | (UInt64(flags) << 8) | UInt64(type)
end

perm_header(size_inbytes::T) where T<:Union{UInt16, UInt32} =
    gap_header(size_inbytes, 0x00, (sizeof(T) == 4 ? 0x08 : 0x07))

gaph_s(::Type{T}) where T = sizeof(UInt64) ÷ sizeof(T) # 2 or 4
ptr_s(::Type{T}) where T = sizeof(Ptr) ÷ sizeof(T) # 2 or 4
data_offset(::Type{GAPPerm{T}}) where T = gaph_s(T) + ptr_s(T)

function Base.getindex(p::T, n::Integer) where T<:GAPPerm
    @boundscheck 0 < n
    return (n > degree(p) ? Int(n) : Int(p.data[n+data_offset(T)]))
end

function Base.setindex!(p::T, v::Integer, n::Integer) where T<:GAPPerm
    @boundscheck 0 < n <= degree(p)
    return p.data[n+data_offset(T)] = v
end

function gap_header(p::GAPPerm{T}) where T
    gaph_s = div(sizeof(UInt64), sizeof(T))
    return reinterpret(UInt64, view(p.data, 1:gaph_s))[1]
end

gap_flags(p::GAPPerm) = reinterpret(UInt8, p.data[1:1])[2]
gap_type(p::GAPPerm)  = reinterpret(UInt8, p.data[1:1])[1]

function Generic.degree(p::GAPPerm{T}) where T
    shift = sizeof(T) == 4 ? 16 : 32
    return Int(gap_header(p) >> shift)
end

### Generic stuff below

Base.iterate(p::GAPPerm, s=1) = (s > degree(p) ? nothing : (p[s], s+1))
Base.eltype(::Type{<:GAPPerm}) = Int64
Base.length(p::GAPPerm) = degree(p)
Base.size(p::GAPPerm) = (degree(p),)

Base.similar(p::GAPPerm{T}) where T = GAPPerm{T}(degree(p))

Base.firstindex(p::GAPPerm) = 1
Base.lastindex(p::GAPPerm) = degree(p)

function Base.:(==)(p::GAPPerm, q::GAPPerm)
    last_idx = max(degree(p), degree(q))
    for i in 1:last_idx
        p[i] == q[i] || return false
    end
    return true
end

Base.hash(p::GAPPerm, h::UInt) = hash(GAPPerm, hash(view(p, 1, degree(p)), h))

function Generic.mul!(out::GAPPerm, p::GAPPerm, q::GAPPerm)
    @boundscheck degree(out) >= max(degree(p), degree(q))
    out = (out === p || out === q ? similar(out) : out)

    @inbounds for i in 1:degree(out)
      out[i] = q[p[i]]
   end
   return out
end

function Generic.inv!(out::GAPPerm, p::GAPPerm)
    @boundscheck degree(p) == degree(out)
    out = (out === p ? similar(out) : out)

    @inbounds for i in 1:degree(p)
      out[p[i]] = i
   end
   return out
end

function Base.:*(p::GAPPerm, q::GAPPerm)
    out = (degree(p) >= degree(q) ? similar(p) : similar(q))
    @inbounds out = mul!(out, p, q)
    return out
end

Base.inv(g::GAPPerm) = @inbounds inv!(similar(g), g)
