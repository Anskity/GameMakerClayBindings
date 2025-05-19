#macro LIB_PATH "clay.so"


var init_handler = external_define(LIB_PATH, "clay_init", dll_cdecl, ty_string, 1, ty_string);

globalvar __ClayErrorOutput;
__ClayErrorOutput = buffer_create(1024, buffer_fixed, 1);
buffer_fill(__ClayErrorOutput, 0, buffer_u8, 0, 1024);

var args = buffer_create(1000, buffer_fixed, 8);
buffer_seek(args, buffer_seek_start, 0);
buffer_write(args, buffer_u64, addr64(__ClayErrorOutput));
buffer_write(args, buffer_u64, window_get_width());
buffer_write(args, buffer_u64, window_get_height());

var init_result = external_call(init_handler, buffer_get_address(args));

buffer_delete(args);
