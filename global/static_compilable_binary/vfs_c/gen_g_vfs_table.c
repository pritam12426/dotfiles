#include "vfs.h"

const unsigned char temp_txt_start[] = {
    #embed "temp.txt"
};


vfs_entry __G_vfs_table[] = {
    {
        .file_path = "temp.txt",
        .file_start = temp_txt_start,
        .file_len = sizeof temp_txt_start,
    },
    {0}
};
