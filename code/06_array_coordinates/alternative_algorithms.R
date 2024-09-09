.construct_array = function(coords, inter_spot_dist_px) {
    MIN_ROW <- min(coords$pxl_col_in_fullres)
    MAX_ROW <- max(coords$pxl_col_in_fullres)
    INTERVAL_ROW <- inter_spot_dist_px * cos(pi / 6)
    NUM_ROWS = (MAX_ROW - MIN_ROW) / INTERVAL_ROW

    MIN_COL <- min(coords$pxl_row_in_fullres)
    MAX_COL <- max(coords$pxl_row_in_fullres)
    INTERVAL_COL <- inter_spot_dist_px / 2
    NUM_COLS = (MAX_COL - MIN_COL) / INTERVAL_COL

    #   First the even rows and even cols
    row_indices = 2 * seq(floor(NUM_ROWS / 2)) - 2
    col_indices = 2 * seq(floor(NUM_COLS / 2)) - 2
    row_coords = MIN_ROW + row_indices * INTERVAL_ROW
    col_coords = MAX_COL - col_indices * INTERVAL_COL
    new_array = tibble(
        array_row = rep(row_indices, times = length(col_coords)),
        pxl_col_in_fullres = rep(row_coords, times = length(col_coords)),
        array_col = rep(col_indices, each = length(row_coords)),
        pxl_row_in_fullres = rep(col_coords, each = length(row_coords))
    )

    #   Next the odd rows and odd cols
    row_indices = 2 * seq(floor(NUM_ROWS / 2)) - 1
    col_indices = 2 * seq(floor(NUM_COLS / 2)) - 1
    row_coords = MIN_ROW + row_indices * INTERVAL_ROW
    col_coords = MAX_COL - col_indices * INTERVAL_COL
    new_array = rbind(
        new_array,
        tibble(
            array_row = rep(row_indices, times = length(col_coords)),
            pxl_col_in_fullres = rep(row_coords, times = length(col_coords)),
            array_col = rep(col_indices, each = length(row_coords)),
            pxl_row_in_fullres = rep(col_coords, each = length(row_coords))
        )
    )

    #   Oddity of Visium array: (0, 0) does not exist
    new_array = new_array |>
        filter(!(array_row == 0 & array_col == 0))

    return(new_array)
}

#   Fit 'coords' to a new hexagonal array by looping through spots, mapping to
#   the nearest location by Euclidean distance, then reserving the destination
#   spot to prevent duplicate mappings
fit_euclidean = function(
        coords, inter_spot_dist_px, no_duplicates = TRUE,
        ideal_coords = .construct_array(coords, inter_spot_dist_px)
    ) {
    coords_list = list()
    err_list_big = list()
    for (this_capture_area in unique(coords$capture_area)) {
        this_ideal_coords = ideal_coords |>
            select(
                array_row, array_col, pxl_row_in_fullres, pxl_col_in_fullres
            ) |>
            as.matrix()
        this_coords = coords |>
            filter(capture_area == this_capture_area) |>
            select(c('pxl_row_in_fullres', 'pxl_col_in_fullres')) |>
            arrange(pxl_row_in_fullres, pxl_col_in_fullres) |>
            as.matrix()
        
        array_list = list()
        err_list = list()
        for (i in seq(nrow(this_coords))) {
            #   Calculate the squared distance to all possible destination spots
            sq_err = rowSums(
                sweep(
                    this_ideal_coords[
                        , c('pxl_row_in_fullres', 'pxl_col_in_fullres')
                    ],
                    2,
                    this_coords[i, ],
                    "-"
                ) ** 2
            )

            #   Grab the array coords of the closest spot
            min_index = which.min(sq_err)
            array_list[[i]] = this_ideal_coords[
                min_index, c("array_row", "array_col")
            ]
            err_list[[i]] = sq_err[min_index]

            if (no_duplicates) {
                #   Don't allow matching to these array coordinates in the
                #   future for this capture area
                this_ideal_coords = this_ideal_coords[-min_index,]
            }
        }

        coords_list[[this_capture_area]] = coords |>
            filter(capture_area == this_capture_area) |>
            select(-c(array_row, array_col)) |>
            arrange(pxl_row_in_fullres, pxl_col_in_fullres) |>
            cbind(do.call(rbind, array_list)) |>
            as_tibble()
        err_list_big[[this_capture_area]] = unlist(err_list)
    }

    coords_new = do.call(rbind, coords_list) |>
        mutate(
            pxl_col_in_fullres_rounded = min(pxl_col_in_fullres) + 
                array_row * inter_spot_dist_px * cos(pi / 6),
            pxl_row_in_fullres_rounded = max(pxl_row_in_fullres) - 
                array_col * inter_spot_dist_px / 2,
            err = unlist(err_list_big) ** 0.5 / inter_spot_dist_px
        )
    
    return(coords_new)
}

serialize_coords = function(coords, inter_spot_dist_px) {
    coords = coords |>
        group_by(array_row, capture_area) |>
        arrange(desc(pxl_row_in_fullres)) |>
        mutate(
            start = mean(array_col) - n(),
            array_col_temp = start - 2 + # start at the right column for this capture area
                    2 * seq_len(n()) +       # make serial and adjacent
                    ((start + array_row) %% 2 == 1) # get even or odd correct
        ) |>
        ungroup() |>
        mutate(
            pxl_row_in_fullres_rounded_temp = max(pxl_row_in_fullres) -
                array_col_temp * inter_spot_dist_px / 2,
            err = (
                (pxl_col_in_fullres - pxl_col_in_fullres_rounded) ** 2 +
                (pxl_row_in_fullres - pxl_row_in_fullres_rounded_temp) ** 2
            ) ** 0.5 / inter_spot_dist_px,
            array_col = ifelse(
                err > 5, array_col, array_col_temp
            ),
            pxl_row_in_fullres_rounded = max(pxl_row_in_fullres) -
                array_col * inter_spot_dist_px / 2,
            err = (
                (pxl_col_in_fullres - pxl_col_in_fullres_rounded) ** 2 +
                (pxl_row_in_fullres - pxl_row_in_fullres_rounded) ** 2
            ) ** 0.5 / inter_spot_dist_px
        ) |>
        select(-c(array_col_temp, pxl_row_in_fullres_rounded_temp))
    
    return(coords)
}

get_neighbors = function(i, coords) {
    this_array_row = coords[[i, 'array_row']]
    this_array_col = coords[[i, 'array_col']]
    this_capture_area = coords[[i, 'capture_area']]
    temp = coords |>
        filter(
            capture_area == this_capture_area,
            (array_row == this_array_row & array_col == this_array_col - 2) |
            (array_row == this_array_row & array_col == this_array_col + 2) |
            (array_row == this_array_row - 1 & array_col == this_array_col - 1) |
            (array_row == this_array_row - 1 & array_col == this_array_col + 1) |
            (array_row == this_array_row + 1 & array_col == this_array_col - 1) |
            (array_row == this_array_row + 1 & array_col == this_array_col + 1)
        ) |>
        pull(key)
    return(temp)
}

get_shared_neighbors = function(coords_new, coords) {
    coords_new$shared_neighbors = sapply(
        seq_len(nrow(coords)),
        function(i) {
            n_before = get_neighbors(i, coords)
            n_after = get_neighbors(i, coords_new)
            return(mean(n_before %in% n_after))
        }
    )

    return(coords_new)
}
