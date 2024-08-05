#####
# load in some necessary functions

hex_to_raw <- function(x) {
  chars <- strsplit(x, "")[[1]]
  as.raw(strtoi(paste0(chars[c(TRUE, FALSE)], chars[c(FALSE, TRUE)]), base=16L))
}

dec_to_hex <- function(decimal_num) {
  hexadecimal_num <- character(0)
  hex_digits <- c(0:9, "A", "B", "C", "D", "E", "F")
  while (decimal_num > 0) {
    remainder <- decimal_num %% 16
    hexadecimal_num <- c(hex_digits[remainder + 1], hexadecimal_num)
    decimal_num <- decimal_num %/% 16
  }
  return(paste(hexadecimal_num, collapse = ""))
}

get_add <- function(drop_index){
  # if the number of characters returned is odd, prepend a 0 so hex values don't
  # cause anything downstream to crap itself
  if(nchar(dec_to_hex((drop_index)*8)) %% 2 == 1){
    return(as.raw(rev(hex_to_raw(paste0("0", dec_to_hex((drop_index)*8))))))
  }else{
    return(as.raw(rev(hex_to_raw(dec_to_hex((drop_index)*8)))))
  }
}

encode30 <- function(data_pair, mem_add){
  if(data_pair < 65535){
    c(raw(4), rev(hex_to_raw(as.character(as.hexmode(data_pair)))), as.raw(as.hexmode(c("00", "18"))), raw(14), mem_add, raw((8 - length(mem_add))))
  }else{
    c(raw(4), as.raw(as.hexmode(substr(rev(sprintf("%06X", data_pair)), start = 5, stop = 6))), as.raw(as.hexmode(substr(rev(sprintf("%06X", data_pair)), start = 3, stop = 4))), as.raw(as.hexmode(substr(rev(sprintf("%06X", data_pair)), start = 1, stop = 2))), as.raw(as.hexmode("18")), raw(14), mem_add, raw(8 - length(mem_add)))
  }
}

library(data.table)

#####

folder_path <- "C:/Users/eatmo/Desktop/check/elmeri/2024_05_28_Colorectal_617F_30um_10Hz.raw/"
file_path <- paste0(folder_path, "_FUNC001.DAT")

file_conn <- file(file_path, "rb")
# read in your binary file
byte <- readBin(file_conn, what = "raw", n = file.size(file_path))

ndata <- file.size(file_path)
close(file_conn)
# make an index of the positions of the data pair bytes
positions <- seq(8, ndata, by = 8)
# subset your giant file to only those positions
byte <- byte[positions]
# remove gigantic positions vector
rm(positions)
# do some garbage collection
gc()
# convert raw hex to integers, this process will likely take forever
byte <- strtoi(as.character(byte), 16)
# hopefully make subsequent processes quicker using data table format
dt <- data.table(index = seq_along(byte), value = byte)
# perform some kind of necessary magic
dt[, diff := c(NA, diff(value))]
# find the indices of value drops corresponding to the change from 1200-50 m/z
drop_indices <- dt[diff < -36, .(index)]
# and subtract by one
drop_indices <- drop_indices-1
drop_indices <- as.vector(unlist(drop_indices))

# construct the index of data pair values per scan
data_pairs <- drop_indices[1]
for(i in 2:length(drop_indices)){
  data_pairs[i] <- drop_indices[i] - drop_indices[(i-1)]
}

data_pairs <- c(data_pairs, (nrow(dt) - drop_indices[length(drop_indices)]))

# construct the index of memory addresses for the offset bytes
memadds <- as.raw(0)
memadds <- c(memadds, sapply(drop_indices, get_add))

idx <- mapply(encode30, data_pairs, memadds, SIMPLIFY = FALSE)

idx <- do.call(c, idx)
writeBin(idx, paste0(folder_path, "reconstructed.IDX"))
close(file_conn)