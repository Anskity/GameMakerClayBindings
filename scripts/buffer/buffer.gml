#macro KB (1024)
#macro MB (KB*1024)

global.extrn_output = buffer_create(KB, buffer_fixed, 1);

function addr64(buf) {
    gml_pragma("forceinline");
    return int64(buffer_get_address(buf));
}

/// @param {Pointer} address
/// @param {Real} length
function cstring_get_string(address, length) {
    static getter_handler = external_define(LIB_PATH, "cstring_get_string", dll_cdecl, ty_string, 2, ty_string, ty_real);
    
    return external_call(getter_handler, address, length);
}
