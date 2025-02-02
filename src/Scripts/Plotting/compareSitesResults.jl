using PyPlot

# Function to read the data from a text file and parse it into a dictionary
function read_data(file_path)
    data = Dict()
    site = ""
    open(file_path, "r") do f
        for line in eachline(f)
            line = strip(line)

            if occursin(r"\w", line) && !occursin("RTT", line) && !occursin("Throughput", line)
                site = line
                data[site] = Dict(:rtt => 0.0, :throughput => 0.0)  # Initialize rtt and throughput
            elseif occursin("RTT", line)
                data[site][:rtt] = parse(Float64, split(line)[2])
            elseif occursin("Throughput", line)
                data[site][:throughput] = parse(Float64, split(line)[2])
            end
        end
    end
    return data
end

# Function to plot the data and save the figure
function plot_comparison(data, save_path)
    sites = collect(keys(data))  # Ensure sites are in a list (string type)
    latencies = [data[site][:rtt] for site in sites]
    throughputs = [data[site][:throughput] for site in sites]

    # Number of sites
    n = length(sites)

    # Bar width
    bar_width = 0.35

    # Create the figure and axis
    fig, ax1 = subplots(figsize=(10, 6))  # Increase figure width

    # Positions for the bars (side-by-side)
    indices = 1:n
    ax1.bar(indices .- bar_width / 2, latencies, bar_width, label="RTT", color="tab:blue")
    
    # Set x-axis labels
    ax1.set_xticks(indices)
    capitalized_sites = [uppercasefirst(site) for site in sites]
    ax1.set_xticklabels(capitalized_sites)

    # Set left y-axis for RTT (in ms)
    ax1.set_xlabel("Sites")
    ax1.set_ylabel("RTT (ms)", color="tab:blue")
    ax1.tick_params(axis="y", labelcolor="tab:blue")

    # Create a second y-axis for Throughput (in Mbytes/s)
    ax2 = ax1.twinx()
    ax2.bar(indices .+ bar_width / 2, throughputs, bar_width, label="Throughput", color="tab:orange")

    # Set right y-axis for Throughput
    ax2.set_ylabel("Throughput (Mbytes/s)", color="tab:orange")
    ax2.tick_params(axis="y", labelcolor="tab:orange")

    # Title
    title("RTT and Throughput comparison of Grid5000 sites")
    
    grid(true)

    # Create the legend and move it outside the plot
    ax1.legend(loc="upper left", bbox_to_anchor=(1.07, 1))
    ax2.legend(loc="upper left", bbox_to_anchor=(1.07, 0.9))

    # Adjust layout for better fit (with increased margins to accommodate legends)
    fig.subplots_adjust(right=0.8)

    # Save the figure
    savefig(save_path)
    close(fig)
end

# Data and save paths
file_path = "src/Scripts/Results/sites-comparison-results.txt"
save_path = "src/Scripts/Results/SitesComparisonPlot"
if !isdir(save_path)
    mkdir(save_path)
end

save_path = save_path * "/sites-comparison.png"


# Read the data from the file
data = read_data(file_path)

# Plot and save the figure
plot_comparison(data, save_path)

println("Plot saved to $save_path")
