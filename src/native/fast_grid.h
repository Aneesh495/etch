/*
 * Etch EDA: Native C11 Grid Rasterization & Distance Transform Engine
 *
 * Provides SIMD-friendly bitset collision checks and O(N) 2D parabolic
 * Euclidean distance transform (Felzenszwalb-Huttenlocher algorithm).
 */

#ifndef ETCH_FAST_GRID_H
#define ETCH_FAST_GRID_H

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    int cols;
    int rows;
    int layers;
    uint32_t* bitset;     /* 1 bit per cell: 1 = blocked, 0 = free */
    float* distance_field; /* Euclidean distance to nearest obstacle */
} FastGrid;

/* Lifecycle */
FastGrid* fast_grid_create(int cols, int rows, int layers);
void fast_grid_free(FastGrid* g);

/* Obstacle operations */
void fast_grid_block_cell(FastGrid* g, int layer, int col, int row);
void fast_grid_block_rect(FastGrid* g, int layer, int min_col, int min_row, int max_col, int max_row);
bool fast_grid_is_blocked(const FastGrid* g, int layer, int col, int row);

/* O(N) Euclidean Distance Transform */
void fast_grid_compute_distance_transform(FastGrid* g, int layer);
float fast_grid_get_distance(const FastGrid* g, int layer, int col, int row);

#ifdef __cplusplus
}
#endif

#endif /* ETCH_FAST_GRID_H */
