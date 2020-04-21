struct LaggedVector{T, M, P, S <: AbstractVector, U <: AbstractVector} <: AbstractVector{Union{T, M}} 
  parent::S
  times::U
  period::P
  default::M
end

function LaggedVector(parent::AbstractVector, times::AbstractVector, period = oneunit(eltype(times)); default = missing)
  length(parent) == length(times) || error("Values and times must have the same length")
  is_sorted_and_unique(times)
  LaggedVector{eltype(parent), typeof(default), typeof(period), typeof(parent), typeof(times)}(parent, times, period, default)
end

function is_sorted_and_unique(times::AbstractVector)
  t, rest = Iterators.peel(times)
  for r in rest
    t < r || error("Times must be sorted and distinct")
    t = r
  end
end

parent(s::LaggedVector) = s.parent

Base.size(s::LaggedVector) = size(parent(s))

@inline function getindex(s::LaggedVector, i::Integer)
  t = s.times[i] - s.period
  incr = (s.times[i] >= t) ? 1 : -1
  while checkbounds(Bool, s.times, i) && ((incr == 1) ? (@inbounds s.times[i] > t) : (@inbounds s.times[i] < t))
    i -= incr
  end
  if checkbounds(Bool, s.times, i) && (@inbounds s.times[i] == t)
    return s.parent[i]
  else
    return s.default
  end
end
