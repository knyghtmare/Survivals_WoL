-- math functions
local lib = {}

function lib.normalized_gaussian_function(x,sigma,mu)
    return 1/((sigma * math.sqrt(2*math.pi)) * math.exp(-(((x-mu)^2)/(2*sigma^2))))
end

function lib.gaussian_function(x,a,b,c) 
    return a * math.exp(-(((x-b)^2)/(2*c^2)))
end

function lib.nested_radical_constant(n) 
    local response = 0
    for i=0,n do
        response = math.sqrt(response + n - i)
    end
    return response
end

function lib.weighted_random(odds)
    local total = sum_array_values(odds)
    local normalized = map(odds, function(i,v) return v / total end)   
    local target = wesnoth.random()
    local sum = 0.0
    local counter = 1
    for index=1, #odds do
        sum = sum + normalized[counter]
        if target < sum then
            break
        end
        counter = counter + 1 
    end
    return counter
end

return lib