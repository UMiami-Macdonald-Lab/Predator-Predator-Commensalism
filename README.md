# Predator-Predator-Commensalism
# README: Cobia–Stingray Commensal Foraging Analysis

## Manuscript Title
**Behavioral Evidence of Predator–Predator Commensalism: Cobia Track and Feed on Prey Disturbed by Southern Stingrays**  
*Saltzman et al., 2025*  

## Overview

This repository contains the R code and data processing pipeline used to analyze Unmanned Aerial Vehicle (UAV) survey footage supporting the manuscript. The study documents a novel predator–predator commensal foraging interaction between a southern stingray (*Hypanus americanus*) and a cobia (*Rachycentron canadum*) in a shallow, nearshore habitat in Biscayne Bay, Florida.

## Objectives

- Extract and filter GPS flight path data from UAV tracks
- Generate high-resolution, time-matched behavioral trajectories
- Calculate step length and smoothed speed of drone path to validate observation duration and tracking effort
- Create spatial and behavioral visualizations for manuscript figures
- Annotate key ecological behaviors identified during commensal interaction

## Data Summary

- **Input File**: `Apr-26th-2025-09-41AM-Flight-Airdata.gpx`  
  - GPS flight data exported from DJI Mavic 2 Zoom via AirData platform.
- **Observation Metadata**:  
  - Site: Deering Point, Biscayne Bay, Florida  
  - Timeframe: 7 min 13 sec continuous observation  
  - Coordinates: ~25.611°N, -80.307°W

## Code Pipeline

###  1. Load and Filter GPS Data
The GPX file is loaded using `sf` and filtered to include only timestamps within the window of behavioral observation.

### 2. Project Coordinates
Lat/lon coordinates are projected to UTM Zone 17N to calculate accurate distances and movement metrics.

###  3. Calculate Trajectory Metrics
Using `trajr`, the script computes:
- Step lengths (inter-frame movement)
- Speed in m/s, kph, and mph
- Smoothed velocity using a rolling mean (Savitzky-Golay filter)

### 4. Spatial Visualization
Plots include:
- Flight path overlaid on a Florida base map
- Annotated Deering Point and Biscayne Bay labels
- Inset locator map for state-level context

###  5. Output
- CSV: `CF_metrics_export.csv` — Trajectory and smoothed speed data
- PNG: `final_map_combined.png` — Figure of spatial path with inset
- Behavioral time stamps aligned to drone-derived video

## Visual Outputs

- **Figure 1**: UAV flight track over Deering Point (main + inset locator map)

## Raw Video Data

- Available via [Figshare](https://figshare.com/s/d40deeff8dddad67654b)

For questions or collaborations, contact:  
**Julia Saltzman**  
📧 juliasaltzman@miami.edu  
🌐 [juliasaltzmanscience.com](http://juliasaltzmanscience.com)

---
