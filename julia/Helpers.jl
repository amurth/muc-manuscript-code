
__precompile__()

module Helpers

using DelimitedFiles, Dates

export readtsv, findone, hierarchical_order, remove_nans, only, parse_date, info, warn

info(msg::String) = println(stderr, msg)
warn(msg::String) = println(stderr, "WARNING: $msg")

# Allow logical operators on boolean arrays without the dot operator
Base.:!(a::AbstractArray{Bool}) = .!a
Base.:&(a::AbstractArray{Bool}, b::AbstractArray{Bool}) = a .& b
Base.:|(a::AbstractArray{Bool}, b::AbstractArray{Bool}) = a .| b

Base.findfirst(s::AbstractString, c::Char) = Base.findfirst(isequal(c), s)

function findone(predicate::Function, collection::AbstractVector)
	idx = 0
	for k in 1:length(collection)
		if predicate(collection[k])
			if idx > 0
				error("At least two elements $(collection[idx]) and $(collection[k]) fulfill the predicate.")
			end
			idx = k
		end
	end
	return idx == 0 ? nothing : idx
end

function findone(collection::AbstractVector, elem)
	idx = 0
	for k in 1:length(collection)
		if collection[k] == elem
			if idx > 0
				error("Element '$elem' is found in at least two positions $idx and $k.")
			end
			idx = k
		end
	end
	return idx == 0 ? nothing : idx
end

function only(predicate::Function, collection::AbstractVector)
	idx = findone(predicate, collection)
	if idx == 0; error("No elements fulfill the predicate."); end
	return collection[idx]
end

remove_nans(arr::AbstractArray) = filter(x -> !isnan(x), arr)

# FIXME: This is helpful because broadcasting does not work for Pair or Regex
# objects in Julia 1.0. Can be dropped after those limitations are lifted.
Base.replace(strings::AbstractArray, pattern, sub) =
	map(s -> replace(s, pattern => sub), strings)
Base.replace(s::AbstractString, pattern, sub) = replace(s, pattern => sub)

# These allow in() and the in-operator to be used to test if a string
# contains a pattern (where pattern can be a string or regular expression).
Base.in(pattern::String, s::AbstractString) = occursin(pattern, s)
Base.in(r::Regex, s::AbstractString) = occursin(r, s)
#Base.broadcastable(r::Regex) = Ref(r)  # Built into Julia-1.1.0

readtsv(tsv_file::IO; text=false) = readdlm(tsv_file, '\t', text ? String : Any)
readtsv(cmd::Base.AbstractCmd; kwargs...) =
	open(f -> readtsv(f; kwargs...), cmd)
readtsv(tsv_path::AbstractString; kwargs...) =
	tsv_path == "-" ? readtsv(STDIN; kwargs...) : open(f -> readtsv(f; kwargs...), expanduser(tsv_path))

function hierarchical_order(args...)
	for a in 2:length(args); @assert(length(args[a]) == length(args[1])); end
	function lt(a, b)
		for c in 1:length(args)
			if args[c][a] < args[c][b]; return true; end
			if args[c][a] > args[c][b]; return false; end
		end
		return false
	end
	return sortperm(1:length(args[1]), lt=lt)
end

function parse_date(x::AbstractString, century::Int)
	if x == "" || x == "."; return nothing; end
	if r"[0-9][0-9]-(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-[0-9]+" in x
		d = try Date(x, "d-u-y") catch; error("Invalid date: $(x)") end
	elseif r"\d+/\d+/\d+" in x
		d = try Date(x, "m/d/y") catch; error("Invalid date: $(x)") end
	else
		error("Invalid date: $(x)")
	end
	return d + Dates.Year(century)
end

end