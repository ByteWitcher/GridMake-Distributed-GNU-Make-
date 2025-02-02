module MasterModule

export get_worker_hosts

function get_worker_hosts()
    worker_hosts = []
    all_hosts = ENV["OAR_NODE_FILE"] # Contains the name of a file which lists all reserved hosts
    master_host = strip(read(`hostname`, String)) # Read the hostname as a String from the master host

    open(all_hosts, "r") do f
        for line in eachline(f)
            worker_host = strip(line)
            if worker_host != master_host
                push!(worker_hosts, worker_host)
            end
        end
    end
    return unique(worker_hosts)
end

end