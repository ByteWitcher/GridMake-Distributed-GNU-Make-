module MakefileParserModule

export Target,parse_makefile

struct Target
    name::String
    dependencies::Vector{String}
    commands::Vector{String}
end

# Function to parse a Makefile and extract targets, dependencies, and commands
function parse_makefile(file_path::String)
    targets = Dict{String, Target}() 
    current_target = ""
    current_dependencies = String[]
    current_commands = String[]
    
    open(file_path, "r") do file
        for line in eachline(file)
            if isempty(line) || line[1] == '#' 
                continue
            end
            
            if occursin(":", line)
                if current_target != ""
                    targets[current_target] = Target(current_target, current_dependencies, current_commands)
                end
                
                parts = split(line, ":")
                current_target = strip(parts[1])
                current_dependencies = split(replace(strip(parts[2]), r"\s+" => " ")," ")
                current_commands = String[]
            elseif startswith(line, "\t")
                commands_line = strip(line)
                if !isempty(commands_line)
                    commands = split(commands_line, ";")
                    push!(current_commands, filter(x -> !isempty(x), strip.(commands))...)
                end
            end
        end
        # Insert the last target
        if current_target != ""
            targets[current_target] = Target(current_target, current_dependencies, current_commands)
        end
    end
    
    return targets
end

end