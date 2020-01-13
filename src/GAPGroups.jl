module GAPGroups

using GAP
using GAPTypes

import Base.*
import Base.^
import Base.inv
import Base.==
import Base.hash
import Base.<
import Base.>
import Base.isless
# export symmetric_group, hash, order, rand, *, ==, identity, inv, ^, >, <, perm

export symmetric_group, order

struct GAPGroup
   X::GapObj
end

struct GAPGroupElem
   X::GapObj
end

function symmetric_group(n::Int64)
   if n<1
     throw(ArgumentError("it must be a positive integer"))
   else
      return GAPGroup(GAP.Globals.SymmetricGroup(n))
   end
end

# to be fixed later
function hash(x::GAPGroupElem)
   return 0
end

function order(x::GAPGroup)
   return GAP.Globals.Size(x.X)
end

function order(x::GAPGroupElem)
   return GAP.Globals.Order(x.X)
end

function rand(x::GAPGroup)
   s=GAP.Globals.Random(x.X)
   return GAPGroupElem(s)
end

function *(x::GAPGroupElem, y::GAPGroupElem)
   return GAPGroupElem(x.X * y.X)
end

function ==(x::GAPGroupElem, y::GAPGroupElem)
   return x.X == y.X
end

function identity(x::GAPGroup)
   return GAPGroupElem(GAP.Globals.Identity(x.X))
end

function inv(x::GAPGroupElem)
   return GAPGroupElem(GAP.Globals.Inverse(x.X))
end


function ^(x::GAPGroupElem, y::Int64)
   return GAPGroupElem(x.X ^ y)
end

function ^(x::GAPGroupElem, y::GAPGroupElem)
   return GAPGroupElem(x.X ^ y.X)
end

function <(x::GAPGroupElem, y::GAPGroupElem)
   return x.X < y.X
end

function >(x::GAPGroupElem, y::GAPGroupElem)
   return x.X > y.X
end

function perm(L::Array{Int64,1})
   z=GAP.Globals.CycleFromList(GAP.julia_to_gap(L))
   return GAPGroupElem(z)
end

function isless(x::GAPGroupElem, y::GAPGroupElem)
   return x<y
end

end
