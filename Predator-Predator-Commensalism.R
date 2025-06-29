# --- Load Required Packages ---
library(sf)
library(trajr)
library(dplyr)
library(lubridate)
library(zoo)
library(ggplot2)
library(ggspatial)
library(cowplot)

# --- Set Metadata ---
transect_id <- "CF"
gpx_file <- "Apr-26th-2025-09-41AM-Flight-Airdata.gpx"
start_time <- ymd_hms("2025-04-26 09:56:00")
end_time   <- ymd_hms("2025-04-26 10:02:00")

# --- Step 1: Load and Filter GPX Track Points ---
track_points <- st_read(gpx_file, layer = "track_points", quiet = TRUE) %>%
  mutate(time = ymd_hms(time)) %>%
  filter(!is.na(time), time >= start_time, time <= end_time) %>%
  arrange(time)

# --- Step 2: Project to UTM Zone 17N (for distance accuracy) ---
track_projected <- st_transform(track_points, crs = 32617)
coords_utm <- st_coordinates(track_projected)

# --- Step 3: Create DataFrame with Time and Projected Coordinates ---
track_df <- track_projected %>%
  mutate(
    x = coords_utm[, 1],
    y = coords_utm[, 2],
    time_sec = as.numeric(difftime(time, min(time), units = "secs"))
  ) %>%
  select(time, time_sec, x, y)

# --- Step 4: Compute Trajectory Metrics ---
traj <- TrajFromCoords(track_df[, c("x", "y")], fps = 10)
traj_smooth <- TrajSmoothSG(traj)
metrics <- TrajDerivatives(traj_smooth)

# --- Step 5: Combine Metrics with Time and Coordinates ---
n <- nrow(track_df) - 1
metrics_df <- data.frame(
  time = track_df$time[2:(n + 1)],
  time_sec = track_df$time_sec[2:(n + 1)],
  x = track_df$x[2:(n + 1)],
  y = track_df$y[2:(n + 1)],
  step_length = metrics$speed * diff(traj_smooth$time),
  speed_mps = metrics$speed
) %>%
  mutate(
    speed_kph = speed_mps * 3.6,
    speed_mph = speed_mps * 2.23694,
    smoothed_speed_mps = rollmean(speed_mps, k = 100, fill = NA, align = "center")
  )

# --- Step 6: Convert UTM Back to Lat/Lon ---
utm_points <- st_as_sf(metrics_df, coords = c("x", "y"), crs = 32617)
wgs84_points <- st_transform(utm_points, crs = 4326)
coords_latlon <- st_coordinates(wgs84_points)

metrics_df$longitude <- coords_latlon[, 1]
metrics_df$latitude  <- coords_latlon[, 2]

# --- Step 7: Export as CSV ---
output_file <- paste0(transect_id, "_metrics_export.csv")
write.csv(metrics_df, output_file, row.names = FALSE)
cat("✅ Export complete:", output_file, "\n")

# --- Step 8: Visualizations ---

# Figure 1: Smoothed Speed Profile
ggplot(metrics_df, aes(x = time)) +
  geom_line(aes(y = smoothed_speed_mps), color = "darkblue", linewidth = 1.2) +
  labs(x = "Time", y = "Speed (m/s)") +
  theme_classic()

# Figure 2: Step Length Distribution
ggplot(metrics_df, aes(x = step_length)) +
  geom_histogram(fill = "steelblue", bins = 30) +
  labs(
    title = paste("Step Length Distribution for", transect_id),
    x = "Step Length (m)", y = "Frequency"
  ) +
  theme_minimal()

# Figure 3: UTM Path Plot
ggplot(metrics_df, aes(x = x, y = y)) +
  geom_path(color = "darkgreen", linewidth = 1.2) +
  geom_point(color = "darkgreen", size = 0.8) +
  labs(x = "Longitude", y = "Latitude") +
  theme_classic()

# --- Step 9: Map Setup ---

# Deering Point (sf object in WGS84)
deering_point <- st_sf(name = "Deering Point",
                       geometry = st_sfc(st_point(c(-80.306967, 25.610949))),
                       crs = 4326)
deering_point_utm <- st_transform(deering_point, crs = st_crs(fl_boundary_crop))
deering_coords <- st_coordinates(deering_point_utm)

# Biscayne Bay location for labeling
biscayne_point <- st_sf(name = "Biscayne Bay",
                        geometry = st_sfc(st_point(c(-80.3065, 25.612))),
                        crs = 4326)
biscayne_point_utm <- st_transform(biscayne_point, crs = st_crs(fl_boundary_crop))
biscayne_coords <- st_coordinates(biscayne_point_utm)

# --- Step 10: Main Map with Deering Point Path ---
main_map <- ggplot() +
  geom_sf(data = fl_boundary_crop, fill = "gray95", color = "black") +
  geom_path(data = metrics_df, aes(x = x, y = y), color = "darkgreen", linewidth = 1.2) +
  geom_point(data = metrics_df, aes(x = x, y = y), color = "darkgreen", size = 0.8) +
  annotate("text",
           x = deering_coords[1], y = deering_coords[2],
           label = "Deering Point", size = 4, fontface = "bold", hjust = -0.1) +
  annotate("point",
           x = deering_coords[1], y = deering_coords[2],
           color = "black", size = 2) +
  annotate("text",
           x = biscayne_coords[1], y = biscayne_coords[2],
           label = "Biscayne Bay", size = 4, fontface = "italic", hjust = -0.1) +
  annotation_scale(location = "bl", width_hint = 0.3) +
  annotation_north_arrow(location = "tl", which_north = "true",
                         style = north_arrow_fancy_orienteering()) +
  labs(x = "Latitude", y = "Longitude") +
  theme_classic(base_size = 14) +
  theme(
    axis.title = element_text(size = 14, face = "bold"),
    axis.text.x = element_text(size = 12),
    axis.text.y = element_text(size = 12, angle = 45)
  )

# --- Step 11: Create Florida Locator Map with Dot on Biscayne Bay ---
fl_outline <- st_transform(fl_outline, crs = 4326)
biscayne_point <- st_sf(name = "Biscayne Bay",
                        geometry = st_sfc(st_point(c(-80.3, 25.6))),
                        crs = 4326)

locator_map <- ggplot() +
  geom_sf(data = fl_outline, fill = "grey90", color = "black", linewidth = 0.5) +
  geom_sf(data = biscayne_point, color = "red", size = 4) +
  annotate("text",
           x = -80.3, y = 26.1,
           label = "Biscayne Bay", size = 3.5, fontface = "italic", hjust = 0.5) +
  coord_sf(xlim = c(-87.5, -79.5), ylim = c(24, 31), expand = FALSE) +
  theme_void() +
  theme(
    plot.background = element_rect(fill = "white", color = NA),
    plot.margin = margin(2, 2, 2, 2)
  )

# --- Step 12: Combine Main Map + Inset Locator Map ---
combined_map <- ggdraw() +
  draw_plot(main_map) +
  draw_plot(locator_map, x = 0.65, y = 0.65, width = 0.3, height = 0.3)

# --- Final Step: Render or Save ---
print(combined_map)
# ggsave("final_map_combined.png", combined_map, width = 8, height = 6, dpi = 300)
