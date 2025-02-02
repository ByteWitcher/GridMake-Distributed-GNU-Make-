using PyPlot

# Function to read and process data
function read_data(file_path::String)
    data = Dict()

    # Open and read the file
    open(file_path, "r") do file
        for line in eachline(file)
            # Split the line by commas
            split_line = split(line, ",")
            
            # Clean up the parts by trimming spaces
            split_line = [strip(part) for part in split_line]

            # Check if the line contains the required data (Machines, Execution, Acceleration, Efficiency)
            if length(split_line) >= 4
                # Extract the number of machines, execution time, acceleration, and efficiency
                machines_str = split_line[1]
                execution_time_str = split_line[2]
                acceleration_str = split_line[3]
                efficiency_str = split_line[4]

                # Remove the non-numeric parts and parse the numbers
                machines = parse(Int, strip(replace(machines_str, r"[^0-9]" => "")))
                execution_time = parse(Float64, strip(replace(execution_time_str, r"[^0-9\.]" => "")))
                acceleration = parse(Float64, strip(replace(acceleration_str, r"[^0-9\.]" => "")))
                efficiency = parse(Float64, strip(replace(efficiency_str, r"[^0-9\.]" => "")))

                # Store the parsed data in the dictionary
                data[machines] = Dict(:execution_time => execution_time, :acceleration => acceleration, :efficiency => efficiency)
            end
        end
    end

    return data
end



# Function to plot the data (Execution Time, Acceleration, or Efficiency)
function plot_data(data, save_path::String, plot_type::String)
    save_path = save_path * "/" * "$(plot_type).png"
    # Prepare data for plotting
    machines = sort(collect(keys(data)))  # List of machines

    fig, ax1 = subplots(figsize=(8, 6))  # Set figure size

    if plot_type == "execution"
        values = [data[machine][:execution_time] for machine in machines] 
        ylabel = "Execution Time (seconds)"
        color = "tab:red"
    elseif plot_type == "acceleration"
        values = [data[machine][:acceleration] for machine in machines] 
        ylabel = "Acceleration"
        color = "tab:blue"
    elseif plot_type == "efficiency"
        values = [data[machine][:efficiency] for machine in machines] 
        ylabel = "Efficiency"
        color = "tab:green"
    else
        println("Invalid plot type: $plot_type. Please choose 'execution', 'acceleration' or 'efficiency'.")
        return
    end

    # Plotting
    ax1.set_xlabel("Machines")
    xticks(machines, machines)
    ax1.set_ylabel(ylabel, color=color)
    ax1.plot(machines, values, color=color, marker="o", label="$(uppercasefirst(plot_type)) vs Machines")
    ax1.tick_params(axis="y", labelcolor=color)

    ax1.legend()
    ax1.set_title("$(uppercasefirst(plot_type)) vs Machines")
    grid(true)

    # Save the figure
    savefig(save_path)
    println("Plot saved as $save_path")
end

# Function to plot comparison between real and theoretical data
function plot_comparison(real_data, theoretical_data, save_path::String, plot_type::String)
    save_path = save_path * "/" * "$(plot_type).png"

    # Prepare data for plotting
    machines = sort(collect(keys(real_data)))  # Assumes both datasets have the same machines
    fig, ax1 = subplots(figsize=(8, 6))  # Set figure size

    ylabel = ""
    if plot_type == "execution"
        real_values = [real_data[machine][:execution_time] for machine in machines]
        theoretical_values = [theoretical_data[machine][:execution_time] for machine in machines]
        ylabel = "Execution Time (seconds)"
    elseif plot_type == "acceleration"
        real_values = [real_data[machine][:acceleration] for machine in machines]
        theoretical_values = [theoretical_data[machine][:acceleration] for machine in machines]
        ylabel = "Acceleration"
    elseif plot_type == "efficiency"
        real_values = [real_data[machine][:efficiency] for machine in machines]
        theoretical_values = [theoretical_data[machine][:efficiency] for machine in machines]
        ylabel = "Efficiency"
    else
        println("Invalid plot type: $plot_type. Please choose 'execution', 'acceleration' or 'efficiency'.")
        return
    end

    # Plotting both datasets
    ax1.set_xlabel("Machines")
    xticks(machines, machines)
    ax1.set_ylabel(ylabel)

    ax1.plot(machines, real_values, color="tab:blue", marker="o", label="Real $(uppercasefirst(plot_type))")
    ax1.plot(machines, theoretical_values, color="tab:orange", marker="x", label="Theoretical $(uppercasefirst(plot_type))")

    ax1.legend()
    ax1.set_title("$(uppercasefirst(plot_type)) comparison: Real vs Theoretical")
    grid(true)

    # Save the figure
    savefig(save_path)
    println("Comparison plot saved as $save_path")
end

function main()
    println("Do you want to run all combinations or a specific combination? ('all' or 'specific')")
    combination_choice = string(strip(readline()))

    # Data and save paths
    real_file_path = "src/Scripts/Results/make-performance-results.txt"
    theoretical_file_path = "src/Scripts/Results/make-performance-results-theoretical.txt"

    real_save_path = "src/Scripts/Results/MakePerformancePlots"
    theoretical_save_path = "src/Scripts/Results/MakePerformanceTheoreticalPlots"
    comparison_save_path = "src/Scripts/Results/MakePerformanceComparisonPlots"

    if combination_choice == "all"
        println("Running all combinations for real, theoretical, and comparison.")

        # Real data
        real_data = read_data(real_file_path)
        if !isdir(real_save_path)
            mkdir(real_save_path)
        end
        plot_data(real_data, real_save_path, "execution")
        plot_data(real_data, real_save_path, "acceleration")
        plot_data(real_data, real_save_path, "efficiency")

        # Theoretical data
        theoretical_data = read_data(theoretical_file_path)
        if !isdir(theoretical_save_path)
            mkdir(theoretical_save_path)
        end
        plot_data(theoretical_data, theoretical_save_path, "execution")
        plot_data(theoretical_data, theoretical_save_path, "acceleration")
        plot_data(theoretical_data, theoretical_save_path, "efficiency")

        # Comparison plots
        if !isdir(comparison_save_path)
            mkdir(comparison_save_path)
        end
        plot_comparison(real_data, theoretical_data, comparison_save_path, "execution")
        plot_comparison(real_data, theoretical_data, comparison_save_path, "acceleration")
        plot_comparison(real_data, theoretical_data, comparison_save_path, "efficiency")

    elseif combination_choice == "specific"
        println("Which operation would you like to perform? ('real', 'theoretical', 'comparison')")
        operation_choice = string(strip(readline()))

        if operation_choice == "real"
            file_path = real_file_path
            save_path_base = real_save_path

            data = read_data(file_path)

            if !isdir(save_path_base)
                mkdir(save_path_base)
            end

            println("Enter the type of plot you want ('execution', 'acceleration', or 'efficiency'): ")
            plot_type = string(strip(readline()))
            plot_data(data, save_path_base, plot_type)

        elseif operation_choice == "theoretical"
            file_path = theoretical_file_path
            save_path_base = theoretical_save_path

            data = read_data(file_path)

            if !isdir(save_path_base)
                mkdir(save_path_base)
            end

            println("Enter the type of plot you want ('execution', 'acceleration', or 'efficiency'): ")
            plot_type = string(strip(readline()))
            plot_data(data, save_path_base, plot_type)

        elseif operation_choice == "comparison"
            real_data = read_data(real_file_path)
            theoretical_data = read_data(theoretical_file_path)

            if !isdir(comparison_save_path)
                mkdir(comparison_save_path)
            end

            println("Enter the type of comparison you want ('execution', 'acceleration', or 'efficiency'): ")
            plot_type = string(strip(readline()))
            plot_comparison(real_data, theoretical_data, comparison_save_path, plot_type)

        else
            println("Invalid operation. Please choose 'real', 'theoretical', or 'comparison'.")
        end

    else
        println("Invalid choice. Please enter 'all' or 'specific'.")
    end
end

main()

