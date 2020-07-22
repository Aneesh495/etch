/*
 * Etch EDA: Native C11 Grid Implementation
 *
 * Implements high-throughput bitset operations and linear-time
 * parabolic envelope distance transforms for obstacle clearance fields.
 */

#include "fast_grid.h"
#include <stdlib.h>
#include <string.h>
#include <math.h>

#define INF 1e20f

FastGrid* fast_grid_create(int cols, int rows, int layers) {
    if (cols <= 0 || rows <= 0 || layers <= 0) return NULL;

    FastGrid* g = (FastGrid*)malloc(sizeof(FastGrid));
    if (!g) return NULL;

    g->cols = cols;
    g->rows = rows;
    g->layers = layers;

    size_t total_cells = (size_t)cols * rows * layers;
    size_t bitset_words = (total_cells + 31) / 32;

    g->bitset = (uint32_t*)calloc(bitset_words, sizeof(uint32_t));
    g->distance_field = (float*)malloc(total_cells * sizeof(float));

    if (!g->bitset || !g->distance_field) {
        fast_grid_free(g);
        return NULL;
    }

    /* Initialize distances to zero */
    for (size_t i = 0; i < total_cells; ++i) {
        g->distance_field[i] = 0.0f;
    }

    return g;
}

void fast_grid_free(FastGrid* g) {
    if (!g) return;
    if (g->bitset) free(g->bitset);
    if (g->distance_field) free(g->distance_field);
    free(g);
}

static inline size_t get_index(const FastGrid* g, int layer, int col, int row) {
    return ((size_t)layer * g->rows + row) * g->cols + col;
}

void fast_grid_block_cell(FastGrid* g, int layer, int col, int row) {
    if (!g || col < 0 || col >= g->cols || row < 0 || row >= g->rows || layer < 0 || layer >= g->layers) {
        return;
    }
    size_t idx = get_index(g, layer, col, row);
    g->bitset[idx / 32] |= (1U << (idx % 32));
}

void fast_grid_block_rect(FastGrid* g, int layer, int min_col, int min_row, int max_col, int max_row) {
    if (!g) return;
    if (min_col < 0) min_col = 0;
    if (min_row < 0) min_row = 0;
    if (max_col >= g->cols) max_col = g->cols - 1;
    if (max_row >= g->rows) max_row = g->rows - 1;

    for (int r = min_row; r <= max_row; ++r) {
        for (int c = min_col; c <= max_col; ++c) {
            fast_grid_block_cell(g, layer, c, r);
        }
    }
}

bool fast_grid_is_blocked(const FastGrid* g, int layer, int col, int row) {
    if (!g || col < 0 || col >= g->cols || row < 0 || row >= g->rows || layer < 0 || layer >= g->layers) {
        return true;
    }
    size_t idx = get_index(g, layer, col, row);
    return (g->bitset[idx / 32] & (1U << (idx % 32))) != 0;
}

/* 1D squared Euclidean distance transform sub-routine */
static void dt1d(const float* f, float* d, int* v, float* z, int n) {
    int k = 0;
    v[0] = 0;
    z[0] = -INF;
    z[1] = +INF;

    for (int q = 1; q < n; ++q) {
        float s = ((f[q] + q * q) - (f[v[k]] + v[k] * v[k])) / (2 * q - 2 * v[k]);
        while (s <= z[k]) {
            k--;
            s = ((f[q] + q * q) - (f[v[k]] + v[k] * v[k])) / (2 * q - 2 * v[k]);
        }
        k++;
        v[k] = q;
        z[k] = s;
        z[k + 1] = +INF;
    }

    k = 0;
    for (int q = 0; q < n; ++q) {
        while (z[k + 1] < q) k++;
        d[q] = (q - v[k]) * (q - v[k]) + f[v[k]];
    }
}

void fast_grid_compute_distance_transform(FastGrid* g, int layer) {
    if (!g || layer < 0 || layer >= g->layers) return;

    int cols = g->cols;
    int rows = g->rows;
    size_t layer_offset = (size_t)layer * rows * cols;

    float* grid_f = (float*)malloc(cols * rows * sizeof(float));
    float* grid_d = (float*)malloc(cols * rows * sizeof(float));
    int max_dim = (cols > rows) ? cols : rows;
    int* v = (int*)malloc(max_dim * sizeof(int));
    float* z = (float*)malloc((max_dim + 1) * sizeof(float));

    if (!grid_f || !grid_d || !v || !z) {
        if (grid_f) free(grid_f);
        if (grid_d) free(grid_d);
        if (v) free(v);
        if (z) free(z);
        return;
    }

    /* Initialize: 0 at obstacle cells, INF at free cells */
    for (int r = 0; r < rows; ++r) {
        for (int c = 0; c < cols; ++c) {
            bool blocked = fast_grid_is_blocked(g, layer, c, r);
            grid_f[r * cols + c] = blocked ? 0.0f : INF;
        }
    }

    /* Transform along columns */
    float* col_in = (float*)malloc(rows * sizeof(float));
    float* col_out = (float*)malloc(rows * sizeof(float));

    for (int c = 0; c < cols; ++c) {
        for (int r = 0; r < rows; ++r) {
            col_in[r] = grid_f[r * cols + c];
        }
        dt1d(col_in, col_out, v, z, rows);
        for (int r = 0; r < rows; ++r) {
            grid_d[r * cols + c] = col_out[r];
        }
    }
    free(col_in);
    free(col_out);

    /* Transform along rows */
    float* row_in = (float*)malloc(cols * sizeof(float));
    float* row_out = (float*)malloc(cols * sizeof(float));

    for (int r = 0; r < rows; ++r) {
        for (int c = 0; c < cols; ++c) {
            row_in[c] = grid_d[r * cols + c];
        }
        dt1d(row_in, row_out, v, z, cols);
        for (int c = 0; c < cols; ++c) {
            g->distance_field[layer_offset + r * cols + c] = sqrtf(row_out[c]);
        }
    }
    free(row_in);
    free(row_out);

    free(grid_f);
    free(grid_d);
    free(v);
    free(z);
}

float fast_grid_get_distance(const FastGrid* g, int layer, int col, int row) {
    if (!g || col < 0 || col >= g->cols || row < 0 || row >= g->rows || layer < 0 || layer >= g->layers) {
        return 0.0f;
    }
    size_t idx = get_index(g, layer, col, row);
    return g->distance_field[idx];
}
