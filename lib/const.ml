let max_prop_len = 1024 (* 1024 on FreeBSD, 4096 on Linux *)
let max_name_len = 256
let max_comment_len = 32
let origin_dir_name = "$ORIGIN"
let spa_minblockshift = 9
let spa_minblocksize = Int64.shift_left 1L spa_minblockshift
let spa_old_maxblockshift = 17
let spa_old_maxblocksize = Int64.shift_left 1L spa_old_maxblockshift
let spa_maxblockshift = 24
let spa_maxblocksize = Int64.shift_left 1L spa_maxblockshift