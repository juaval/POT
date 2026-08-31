import os

#os.chdir("../../../logs/concoct_suffering")
n_file = 0
for file in os.scandir(os.getcwd()):
    n_file += 1
    if file.is_file():
        current_file = open(file, "r")
        # I need to differentiate when a sample appears for the first time. As I have no way of knowing
        # how many different samples a file contains, I'm making a dictionary which is automatically updated
        first_status = {}
        n_line = 1
        print("Working on the ", n_file, "st file")
        # I want to go line by line to stop big files from destroying the computer's RAM'.
        for line in current_file:
            #print( "Working on the ", n_line, "st sequence of the ", n_file, "st file")
            n_line += 1
            # Only header lines will start with ">". So by doing this we are making sure of only getting them
            # It's crucial to keep in mind that the first line of the file is ALWAYS a header
            if line.startswith(">"):
                current_entry = line
                current_sample = current_entry[1:4] #check me! I'm hardcoded!
                # to stop the script from printing infinite lines every time a sample reappears
                if current_sample not in first_status.keys():
                    try:
                        os.makedirs(current_sample, exist_ok=True)
                        first_status[current_sample] = "first"
                    except OSError as error:
                        print("Directory ", current_sample, " already exists")
                        first_status[current_sample] = "first"

                # Generate the fname and header strings
                fname = current_sample + "/" + current_sample +"_"+ str(os.path.basename(file))# + ".txt"
                fname = os.path.join(os.getcwd(), fname)
                header = ">"+current_entry[13:] # This is hardcoded!!! CHANGE ME!!!! (after checking what it should be first)

                # The first time I encounter a header of a specific sample I want to create a new file for that sample's entries. The next times I want to append to said file, and I need to add a newline before writing anything otherwise the formatting goes to heck
                if first_status[current_sample] == "first":
                    with open(fname, "w") as f:
                        f.write(header)
                    first_status[current_sample] = "NotFirst"
                else:
                    with open(fname, "a") as f:
                        f.write("\n")
                        f.write(header)
            # The only lines that do not start with ">" are sequence lines. We want to remove the newline ("\n") from them and then write them to file. Also, a header should always preceed a sequence line, so files should always exist for these lines. And the value inside current_sample should be the same as well
            else:
                fixed_line = line.replace("\n", "") # get rid of the newline
                with open(fname, "a") as f:
                        f.write(fixed_line)
        current_file.close()

#>S01B_contigs:NODE_6800_length_4647_cov_2.871951
#>S13_contigs:NODE_9_length_41589_cov_12.852627


