#!/usr/bin/env julia

#import Pkg
#Pkg.add("CSV")
using CSV

# Get parameters
if length(ARGS) != 2

	println("alamo_SnapPlot.jl - Program generating particles scatter plots for movie production")
	println()
	println("Usage:")
	println()
	println("    ./alamo_SnapPlot.jl <SnapDataPath> <SnapPlotPath>")
	println()
	println("This file is part of the pbl_met project.")
	exit(1)
	
end
sSnapPath = ARGS[1]
sOutPath  = ARGS[2]

# Get boundary information
line = open(sSnapPath * "/guide.txt") do f
	lines = readlines(f)
	(lines[1])
end
blocks = split(line)
xmin   = parse(Float64, blocks[1])
xmax   = parse(Float64, blocks[2])
ymin   = parse(Float64, blocks[3])
ymax   = parse(Float64, blocks[4])
zmin   = parse(Float64, blocks[5])
zmax   = parse(Float64, blocks[6])
dx     = parse(Float64, blocks[7])
dy     = parse(Float64, blocks[8])
tmax   = parse(Float64, blocks[9])
dt     = parse(Float32, blocks[10])
year   = parse(Int32, blocks[11])
month  = parse(Int32, blocks[12])
day    = parse(Int32, blocks[13])
hour   = parse(Int32, blocks[14])
minute = parse(Int32, blocks[15])
second = parse(Float64, blocks[16])

# Iterate over input path contents, and process them
files = readdir(sSnapPath)
for file in files
	sFileName = sSnapPath * "/" * file
	data = CSV.read(sFileName)
	println(sFileName)
end
