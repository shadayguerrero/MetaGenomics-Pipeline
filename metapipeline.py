#####################################################################
#                   MAIN SCRIPT METAPIPELINE                        #
#                       Augusto Franco                              #  
#####################################################################


#Libraries used
import argparse
from subprocess import run

#Define arguments

parser = argparse.ArgumentParser(description="Metapipeline")
subparser = parser.add_subparsers(dest="subcommand", required=True)

#-----------------------Create environment mode---------------------------------
en = subparser.add_parser("env",help="Create environment.",
                           usage= "metapipeline.py env [package_manager] [config_file]")
en.add_argument("package_manager", 
                   type=str,
                   nargs='?', 
                   help="Package manager prefered [conda|mamba|micromamba]")

en.add_argument("config_file", 
                   type=str, 
                   nargs='?',  
                   help="YAML file")

#----------------------- m5dsum check mode---------------------------------
md = subparser.add_parser("md5",  help="Check md5sum from the reads that will be use for the analysis.",
                          usage="metapipeline.py md5 [reads] [md5_file] [e] [output]")
md.add_argument("reads", 
                   type=str,
                   nargs='?', 
                   help="Folder where the reads are available")

md.add_argument("md5_file", 
                   type=str, 
                   nargs='?',  
                   help="Text file with md5sum info")

md.add_argument("e", 
                   type=str, 
                   nargs='?',  
                   help="File extension [fastq|fq|fastq.gz|fq.gz]")

md.add_argument("output", 
                   type=str, 
                   nargs='?',  
                   help="Output file name")

# #----------------------- Concatenate mode---------------------------------
# ct = subparser.add_parser("concat",  help="Concatenate reads.",
#                           usage="metapipeline.py concat")

# ct.add_argument("reads", 
#                 type=str,
#                 nargs='?', 
#                 help="Folder where the reads are available")

# ct.add_argument("prefix", 
#                 type=str,
#                 nargs='?', 
#                 help="Prefix of the samples that you will use (e.g. SRR*)")
# ct.add_argument("output", 
#                 type=str,
#                 nargs='?', 
#                 help="Output folder")
# ct.add_argument("ext", 
#                    type=str, 
#                    nargs='?',  
#                    help="Input File extension [fastq|fq|fastq.gz|fq.gz]")

#---------------------------------Setup------------------------------------
setup = subparser.add_parser("setup",  help="Setup folders for results.",
                             usage= "usage: metapipeline.py setup [reads] [working_dir] [prefix] [pattern] [extension]")

setup.add_argument("reads", 
                type=str,
                nargs='?', 
                help="Folder where the reads are available")

setup.add_argument("working_dir", 
                type=str,
                nargs='?', 
                help="Working directory path")

setup.add_argument("pattern", 
                type=str,
                nargs='?', 
                help="Read pattern (E.g. _R1, _L1, _F, etc)")

setup.add_argument("extension", 
                type=str,
                nargs='?', 
                help="Read file extension")

setup.add_argument("-prefix", 
                type=str,
                nargs='?', 
                help="Sample prefix")
#----------------------- metapipeline mode---------------------------------
met = subparser.add_parser("metapipeline",  help="Metapipeline.",
                          usage='''metapipeline.py metapipeline -m [mode]
        metapipeline.py metapipeline -m all  -t [threads] -p1 [patternForward] -p2 [patternReverse] -e [file_extension] -bDB [bowtieDB] -kDB [krakenDB] -pDB [phylophlanDB] -opt [option] -eDB [eggNOGDB] -profile [kofamDB profiles] -kL [kofamDB ko_list]
        metapipeline.py metapipeline -m qc -t [threads] -p1 [patternForward] -p2 [patternReverse] -e [file_extension]
        metapipeline.py metapipeline -m rmHost -t [threads] -p1 [patternForward -e [file_extension] -bDB [bowtieDB]
        metapipeline.py metapipeline -m taxAssignment -t [threads] -p1 [patternForward -e [file_extension] -kDB [krakenDB]
        metapipeline.py metapipeline -m assembly -t [threads] -p1 [patternForward -e [file_extension]
        metapipeline.py metapipeline -m taxMags -t [threads] -pDB [phylophlanDB] -n [sample_prefix]
        metapipeline.py metapipeline -m geneAnnotation -t [threads] ''')
met.add_argument("-m","--mode",
                   type=str,
                   nargs='?', 
                   help='''usage: [all] complete pipeline,[qc] quality control,
                   [rmHost] remove host,[taxAssignment] taxonomy assignment, 
                   [assembly] Metagenome assembly, [taxMags] Taxonomy assigment MAGs, 
                   [geneAnnotation] Gene annotation''')

met.add_argument("-t","--cpus",
                   type=str,
                   nargs='?', 
                   help="Threads")

met.add_argument("-p1","--pForward",
                   type=str,
                   nargs='?', 
                   help="Pattern read forward")

met.add_argument("-p2","--pReverse",
                   type=str,
                   nargs='?', 
                   help="Pattern read reverse")

met.add_argument("-e","--extension", 
                type=str,
                nargs='?', 
                help="Read file extension")

met.add_argument("-bDB","--bowtieDB", 
                type=str,
                nargs='?', 
                help="Bowtie2 database path")

met.add_argument("-kDB","--krakenDB", 
                type=str,
                nargs='?', 
                help="Kraken2 database path")

met.add_argument("-pDB","--phylophlanDB", 
                type=str,
                nargs='?', 
                help="Phylophlan database path")

met.add_argument("-opt","--option", 
                type=str,
                nargs='?', 
                help="Option to select the taxonomic assignment mode: 1) MAGS; 2) reads; 3) contigs")

met.add_argument("-n", "--prefix",
                type=str,
                nargs='?', 
                help="Sample prefix")

met.add_argument("-eDB","--eggNOGDB", 
                type=str,
                nargs='?', 
                help="eggNOG database path")
met.add_argument("-profile","--koProfiles", 
                type=str,
                nargs='?', 
                help="kofam Profiles path")
met.add_argument("-kL","--koList", 
                type=str,
                nargs='?', 
                help="kofam List path")


# Parse the arguments
args = parser.parse_args()
#print(args)

# Access the arguments based on the subcommand
if args.subcommand == 'env':
#---------------------------------Environment config ------------------------
    if args.package_manager == "conda" or args.package_manager == "mamba":
        run([args.package_manager, "env", "create", "-f", args.config_file])
    elif args.package_manager == "micromamba":
        run([args.package_manager,"create", "-f", args.config_file])
    else:
        print('usage = metapipeline.py env [package_manager] [config_file]')
#---------------------------------md5Sum checking-----------------------------
elif args.subcommand == "md5":
    if args.reads is not None:
        run(["./src/raw_readsCheck2.sh", args.reads, args.md5_file, args.e, args.output])
        print("CSV created :) ")
    else: 
        print("usage = metapipeline.py md5 [reads] [md5_file] [e] [output]")

#---------------------------------Setup------------------------------------
elif args.subcommand =="setup":
    if args.reads is not None and args.prefix is not None:
        run(["./src/setup3.sh", args.reads, args.working_dir, args.pattern, args.extension, args.prefix])
        print("Setup done :)")
    elif args.reads is not None and args.prefix is None:
        run(["./src/setup3.sh", args.reads, args.working_dir, args.pattern, args.extension])
        print("Setup done :)")
    else: 
        print("usage = metapipeline.py setup [reads] [working_dir] [prefix] [pattern] -prefix [extension]")
#---------------------------------Metapipeline-----------------------------
elif args.subcommand=="metapipeline":
    if args.mode =="qc":
        run(["./src/1_qualityCheck.sh", args.cpus, args.pForward, args.pReverse, args.extension,">>","metagenomics.log"])
    elif args.mode == "rmHost":
        run(["./src/2_hostRemove.sh", args.cpus, args.pForward, args.extension, args.bowtieDB,">>","metagenomics.log"])
    elif args.mode == "taxAssignment":
        run(["./src/3_taxonomicAssignmentHostRemoved.sh", args.cpus, args.pForward, args.extension, args.krakenDB,">>","metagenomics.log"])
    elif args.mode == "assembly":
        run(["./src/4_metagenomeAssembly.sh", args.cpus, args.pForward, args.extension,">>","metagenomics.log"])
    elif args.mode == "taxMags":
        run(["./src/5_taxonomicAssignmentMAGs_Update.sh", args.cpus, args.phylophlanDB, args.prefix, args.option,">>","metagenomics.log"])
    elif args.mode == "geneAnnotation":
        run(["./src/6_geneAnnotation.sh", args.cpus,">>","metagenomics.log"])
    elif args.mode == "all":
        run(["./src/metagenomics.sh", args.cpus, args.pForward, args.pReverse, args.extension, args.bowtieDB, args.krakenDB, args.phylophlanDB, args.option, args.prefix, args.eggNOGDB, args.koProfiles,args.koList])
    else:
        print("HELP = metapipeline.py metapipeline -h")

else:
    # Handle cases where no subcommand is provided
    parser.print_help()

