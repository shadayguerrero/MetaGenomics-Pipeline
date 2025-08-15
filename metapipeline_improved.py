#!/usr/bin/env python3

#####################################################################
#                   IMPROVED METAPIPELINE SCRIPT                   #
#                       Enhanced Version                           #
#####################################################################

import argparse
import os
import sys
import logging
import subprocess
import time
import json
import configparser
from pathlib import Path
from datetime import datetime

class MetaPipeline:
    def __init__(self):
        self.script_dir = Path(__file__).parent.absolute()
        self.config_file = self.script_dir / "config" / "pipeline.conf"
        self.log_dir = self.script_dir / "logs"
        self.log_dir.mkdir(exist_ok=True)
        
        # Setup logging
        self.setup_logging()
        
        # Load configuration
        self.config = self.load_config()
        
        # Pipeline status
        self.status = {
            'start_time': None,
            'end_time': None,
            'steps_completed': [],
            'steps_failed': [],
            'current_step': None
        }
    
    def setup_logging(self):
        """Setup logging configuration"""
        log_file = self.log_dir / f"metapipeline_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log"
        
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(log_file),
                logging.StreamHandler(sys.stdout)
            ]
        )
        self.logger = logging.getLogger(__name__)
        self.logger.info(f"MetaPipeline started - Log file: {log_file}")
    
    def load_config(self):
        """Load pipeline configuration"""
        config = configparser.ConfigParser()
        if self.config_file.exists():
            config.read(self.config_file)
            self.logger.info(f"Configuration loaded from {self.config_file}")
        else:
            self.logger.warning(f"Configuration file not found: {self.config_file}")
        return config
    
    def get_threads(self, user_threads=None):
        """Get number of threads to use"""
        if user_threads:
            return str(user_threads)
        
        config_threads = self.config.get('DEFAULT', 'threads', fallback='0')
        if config_threads == '0':
            # Auto-detect
            import multiprocessing
            return str(multiprocessing.cpu_count())
        return config_threads
    
    def run_command(self, cmd, step_name, check_output=False):
        """Run a command with error handling and logging"""
        self.status['current_step'] = step_name
        self.logger.info(f"Starting step: {step_name}")
        self.logger.info(f"Command: {' '.join(cmd)}")
        
        start_time = time.time()
        
        try:
            if check_output:
                result = subprocess.run(cmd, capture_output=True, text=True, check=True)
                self.logger.info(f"Step completed: {step_name}")
                self.status['steps_completed'].append(step_name)
                return result.stdout
            else:
                result = subprocess.run(cmd, check=True)
                self.logger.info(f"Step completed: {step_name}")
                self.status['steps_completed'].append(step_name)
                return True
                
        except subprocess.CalledProcessError as e:
            error_msg = f"Step failed: {step_name} - Error: {e}"
            self.logger.error(error_msg)
            self.status['steps_failed'].append(step_name)
            raise RuntimeError(error_msg)
        except FileNotFoundError as e:
            error_msg = f"Command not found for step: {step_name} - {e}"
            self.logger.error(error_msg)
            self.status['steps_failed'].append(step_name)
            raise RuntimeError(error_msg)
        finally:
            elapsed = time.time() - start_time
            self.logger.info(f"Step {step_name} took {elapsed:.2f} seconds")
    
    def check_dependencies(self):
        """Check if required tools are available"""
        required_tools = [
            'fastqc', 'trimmomatic', 'bowtie2', 'samtools', 
            'kraken2', 'spades.py', 'checkm'
        ]
        
        missing_tools = []
        for tool in required_tools:
            try:
                subprocess.run(['which', tool], capture_output=True, check=True)
                self.logger.info(f"✓ {tool} is available")
            except subprocess.CalledProcessError:
                missing_tools.append(tool)
                self.logger.warning(f"✗ {tool} is not available")
        
        if missing_tools:
            error_msg = f"Missing required tools: {', '.join(missing_tools)}"
            self.logger.error(error_msg)
            raise RuntimeError(error_msg)
        
        self.logger.info("All required tools are available")
    
    def create_environment_info(self):
        """Create environment information file"""
        env_info = {
            'timestamp': datetime.now().isoformat(),
            'python_version': sys.version,
            'working_directory': str(Path.cwd()),
            'script_directory': str(self.script_dir),
            'tools': {}
        }
        
        # Get tool versions
        tools_version_cmd = {
            'fastqc': ['fastqc', '--version'],
            'trimmomatic': ['trimmomatic', '-version'],
            'bowtie2': ['bowtie2', '--version'],
            'samtools': ['samtools', '--version'],
            'kraken2': ['kraken2', '--version'],
            'spades': ['spades.py', '--version']
        }
        
        for tool, cmd in tools_version_cmd.items():
            try:
                result = subprocess.run(cmd, capture_output=True, text=True)
                env_info['tools'][tool] = result.stdout.strip() or result.stderr.strip()
            except:
                env_info['tools'][tool] = "Version not available"
        
        # Save environment info
        env_file = self.log_dir / f"environment_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        with open(env_file, 'w') as f:
            json.dump(env_info, f, indent=2)
        
        self.logger.info(f"Environment information saved to {env_file}")
    
    def quality_check(self, threads, pattern_f, pattern_r, extension):
        """Quality control step"""
        script_path = self.script_dir / "src" / "1_qualityCheck.sh"
        cmd = [str(script_path), threads, pattern_f, pattern_r, extension]
        return self.run_command(cmd, "Quality Check")
    
    def host_removal(self, threads, pattern_f, extension, bowtie_db):
        """Host removal step"""
        script_path = self.script_dir / "src" / "2_hostRemove.sh"
        cmd = [str(script_path), threads, pattern_f, extension, bowtie_db]
        return self.run_command(cmd, "Host Removal")
    
    def taxonomic_assignment(self, threads, pattern_f, extension, kraken_db):
        """Taxonomic assignment step"""
        script_path = self.script_dir / "src" / "3_taxonomicAssignmentHostRemoved.sh"
        cmd = [str(script_path), threads, pattern_f, extension, kraken_db]
        return self.run_command(cmd, "Taxonomic Assignment")
    
    def metagenome_assembly(self, threads, pattern_f, extension):
        """Metagenome assembly step"""
        script_path = self.script_dir / "src" / "4_metagenomeAssembly.sh"
        cmd = [str(script_path), threads, pattern_f, extension]
        return self.run_command(cmd, "Metagenome Assembly")
    
    def taxonomic_assignment_mags(self, threads, phylophlan_db, prefix, option):
        """Taxonomic assignment of MAGs step"""
        script_path = self.script_dir / "src" / "5_taxonomicAssignmentMAGs_Update.sh"
        cmd = [str(script_path), threads, phylophlan_db, prefix, option]
        return self.run_command(cmd, "Taxonomic Assignment MAGs")
    
    def gene_annotation(self, threads):
        """Gene annotation step"""
        script_path = self.script_dir / "src" / "6_geneAnnotation.sh"
        cmd = [str(script_path), threads]
        return self.run_command(cmd, "Gene Annotation")
    
    def functional_annotation(self, threads, prefix, eggnog_db, profile, ko_list):
        """Functional annotation step"""
        script_path = self.script_dir / "src" / "7_functionalAnnotation.sh"
        cmd = [str(script_path), threads, prefix, eggnog_db, profile, ko_list]
        return self.run_command(cmd, "Functional Annotation")
    
    def run_full_pipeline(self, args):
        """Run the complete pipeline"""
        self.status['start_time'] = datetime.now()
        
        try:
            self.logger.info("Starting complete MetaGenomics pipeline")
            self.check_dependencies()
            self.create_environment_info()
            
            threads = self.get_threads(args.cpus)
            
            # Run all steps
            self.quality_check(threads, args.pForward, args.pReverse, args.extension)
            self.host_removal(threads, args.pForward, args.extension, args.bowtieDB)
            self.taxonomic_assignment(threads, args.pForward, args.extension, args.krakenDB)
            self.metagenome_assembly(threads, args.pForward, args.extension)
            self.taxonomic_assignment_mags(threads, args.phylophlanDB, args.prefix, args.option)
            self.gene_annotation(threads)
            self.functional_annotation(threads, args.prefix, args.eggNOGDB, args.koProfiles, args.koList)
            
            self.status['end_time'] = datetime.now()
            elapsed = self.status['end_time'] - self.status['start_time']
            
            self.logger.info(f"Pipeline completed successfully in {elapsed}")
            self.logger.info(f"Steps completed: {len(self.status['steps_completed'])}")
            
        except Exception as e:
            self.status['end_time'] = datetime.now()
            self.logger.error(f"Pipeline failed: {e}")
            if self.status['steps_failed']:
                self.logger.error(f"Failed steps: {', '.join(self.status['steps_failed'])}")
            raise
    
    def setup_project(self, reads_dir, working_dir, pattern, extension, prefix=None):
        """Setup project directory structure"""
        script_path = self.script_dir / "src" / "setup3.sh"
        cmd = [str(script_path), reads_dir, working_dir, pattern, extension]
        if prefix:
            cmd.append(prefix)
        
        return self.run_command(cmd, "Project Setup")
    
    def md5_check(self, reads_dir, md5_file, extension, output):
        """Check MD5 sums of reads"""
        script_path = self.script_dir / "src" / "raw_readsCheck2.sh"
        cmd = [str(script_path), reads_dir, md5_file, extension, output]
        return self.run_command(cmd, "MD5 Check")

def create_parser():
    """Create argument parser"""
    parser = argparse.ArgumentParser(
        description="Enhanced MetaGenomics Pipeline",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Setup project
  python metapipeline_improved.py setup /path/to/reads /path/to/workdir _R1 fastq.gz --prefix sample

  # Run quality control only
  python metapipeline_improved.py metapipeline -m qc -t 8 -p1 _R1 -p2 _R2 -e fastq.gz

  # Run complete pipeline
  python metapipeline_improved.py metapipeline -m all -t 8 -p1 _R1 -p2 _R2 -e fastq.gz \\
    -bDB /path/to/bowtie_db -kDB /path/to/kraken_db -pDB /path/to/phylophlan_db \\
    -opt 1 -n sample_prefix -eDB /path/to/eggnog_db -profile /path/to/profiles -kL /path/to/ko_list
        """
    )
    
    subparsers = parser.add_subparsers(dest="subcommand", required=True)
    
    # Environment setup
    env_parser = subparsers.add_parser("env", help="Create conda environment")
    env_parser.add_argument("package_manager", nargs='?', default="micromamba",
                           help="Package manager (conda|mamba|micromamba)")
    env_parser.add_argument("config_file", nargs='?', default="config/environment-full.yml",
                           help="YAML configuration file")
    
    # MD5 check
    md5_parser = subparsers.add_parser("md5", help="Check MD5 sums of reads")
    md5_parser.add_argument("reads", help="Directory containing reads")
    md5_parser.add_argument("md5_file", help="MD5 sum file")
    md5_parser.add_argument("extension", help="File extension")
    md5_parser.add_argument("output", help="Output file name")
    
    # Project setup
    setup_parser = subparsers.add_parser("setup", help="Setup project directory")
    setup_parser.add_argument("reads", help="Directory containing reads")
    setup_parser.add_argument("working_dir", help="Working directory")
    setup_parser.add_argument("pattern", help="Read pattern (e.g., _R1)")
    setup_parser.add_argument("extension", help="File extension")
    setup_parser.add_argument("--prefix", help="Sample prefix")
    
    # Main pipeline
    pipeline_parser = subparsers.add_parser("metapipeline", help="Run MetaGenomics pipeline")
    pipeline_parser.add_argument("-m", "--mode", required=True,
                                choices=["all", "qc", "rmHost", "taxAssignment", "assembly", "taxMags", "geneAnnotation", "funcAnnotation"],
                                help="Pipeline mode")
    pipeline_parser.add_argument("-t", "--cpus", type=int, help="Number of threads")
    pipeline_parser.add_argument("-p1", "--pForward", help="Forward read pattern")
    pipeline_parser.add_argument("-p2", "--pReverse", help="Reverse read pattern")
    pipeline_parser.add_argument("-e", "--extension", help="File extension")
    pipeline_parser.add_argument("-bDB", "--bowtieDB", help="Bowtie2 database path")
    pipeline_parser.add_argument("-kDB", "--krakenDB", help="Kraken2 database path")
    pipeline_parser.add_argument("-pDB", "--phylophlanDB", help="PhyloPhlan database path")
    pipeline_parser.add_argument("-opt", "--option", help="Taxonomic assignment option")
    pipeline_parser.add_argument("-n", "--prefix", help="Sample prefix")
    pipeline_parser.add_argument("-eDB", "--eggNOGDB", help="eggNOG database path")
    pipeline_parser.add_argument("-profile", "--koProfiles", help="KofamDB profiles path")
    pipeline_parser.add_argument("-kL", "--koList", help="KofamDB list path")
    
    return parser

def main():
    """Main function"""
    parser = create_parser()
    args = parser.parse_args()
    
    pipeline = MetaPipeline()
    
    try:
        if args.subcommand == 'env':
            # Environment creation
            if args.package_manager in ["conda", "mamba"]:
                cmd = [args.package_manager, "env", "create", "-f", args.config_file]
            elif args.package_manager == "micromamba":
                cmd = [args.package_manager, "create", "-f", args.config_file]
            else:
                raise ValueError(f"Unknown package manager: {args.package_manager}")
            
            pipeline.run_command(cmd, "Environment Creation")
            
        elif args.subcommand == "md5":
            pipeline.md5_check(args.reads, args.md5_file, args.extension, args.output)
            
        elif args.subcommand == "setup":
            pipeline.setup_project(args.reads, args.working_dir, args.pattern, args.extension, args.prefix)
            
        elif args.subcommand == "metapipeline":
            threads = pipeline.get_threads(args.cpus)
            
            if args.mode == "qc":
                pipeline.quality_check(threads, args.pForward, args.pReverse, args.extension)
            elif args.mode == "rmHost":
                pipeline.host_removal(threads, args.pForward, args.extension, args.bowtieDB)
            elif args.mode == "taxAssignment":
                pipeline.taxonomic_assignment(threads, args.pForward, args.extension, args.krakenDB)
            elif args.mode == "assembly":
                pipeline.metagenome_assembly(threads, args.pForward, args.extension)
            elif args.mode == "taxMags":
                pipeline.taxonomic_assignment_mags(threads, args.phylophlanDB, args.prefix, args.option)
            elif args.mode == "geneAnnotation":
                pipeline.gene_annotation(threads)
            elif args.mode == "funcAnnotation":
                pipeline.functional_annotation(threads, args.prefix, args.eggNOGDB, args.koProfiles, args.koList)
            elif args.mode == "all":
                pipeline.run_full_pipeline(args)
            else:
                raise ValueError(f"Unknown mode: {args.mode}")
                
    except Exception as e:
        pipeline.logger.error(f"Pipeline execution failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()

