globalvar __LayoutBuffer;
__LayoutBuffer = buffer_create(3*MB, buffer_fixed, 1);

globalvar __LayoutPos;
__LayoutPos = 0;

globalvar __StackDepth;
__StackDepth = 0;

globalvar __ElementAmount;
__ElementAmount = 0;

globalvar __ClayLayoutHasBegun;
__ClayLayoutHasBegun = false;

function __clay_assert_layout_has_begun() {
    if !__ClayLayoutHasBegun {
        show_error("Calling clay layout function, but Clay_BeginLayout wasn't called", true);
    }
}

function Clay_BeginLayout() {
    __LayoutPos = -__ClayStruct.Size;
    __StackDepth = 0;
    __ElementAmount = 0;
    __ClayLayoutHasBegun = true;
}
function Clay_EndLayout() {
    __ClayLayoutHasBegun = false;
}

enum ClaySizing {
    Fit,
    Grow,
    Percent,
    Fixed,
}

enum ClayLayoutDirection {
    LeftToRight,
    TopToBottom,
}

enum __ClayStruct {
    StackDepth = 0, //u16
    ClayID = 2, //u64 Pointer to ID
    WidthType = 10, //u8
    WidthValue = 11, //u32
    HeightType = 15, //u8
    HeightValue = 16, //u32
    PaddingLeft = 20, //u16
    PaddingRight = 22, //u16
    PaddingTop = 24, //u16
    PaddingBottom = 26, //u16
    ChildGap = 28, //u16
    BackgroundColorRed = 30, //f32
    BackgroundColorGreen = 34, //f32
    BackgroundColorBlue = 38, //f32
    BackgroundColorAlpha = 42, //f32
    Direction = 46, //u8
    Halign = 47, //u8
    Valign = 48, //u8
    Data = 49, // u64 Its a string pointer, if its NULL then this is not text
    FontID = 57, // u16
    FontSize = 59, // u16
    FontColorRed = 61, // u32
    FontColorGreen = 65, // u32
    FontColorBlue = 69, // u32
    FontColorAlpha = 73, // u32
    
    Size = 77
}

function CLAY_NEW(clay_id=undefined) {
    __clay_assert_layout_has_begun();
    
    static id_ptr_table = ds_map_create();
    
    static AllocClayID_handler = external_define(LIB_PATH, "AllocClayID", dll_cdecl, ty_string, 2, ty_string, ty_string);
    
    __LayoutPos += __ClayStruct.Size;
    buffer_seek(__LayoutBuffer, buffer_seek_start, __LayoutPos);
    
    var prev_pos = buffer_tell(__LayoutBuffer);
    
    var id_ptr = int64(0);
    if !is_undefined(clay_id) {
        if ds_map_exists(id_ptr_table, clay_id) {
            id_ptr = id_ptr_table[? clay_id];
        } else {
            static id_ref = buffer_create(buffer_sizeof(buffer_u64), buffer_fixed, 8);
            external_call(AllocClayID_handler, clay_id, buffer_get_address(id_ref));
            
            id_ptr = buffer_peek(id_ref, 0, buffer_u64);
            
            id_ptr_table[? clay_id] = id_ptr;
        }
    }
    
    buffer_write(__LayoutBuffer, buffer_u16, __StackDepth); //Stack depth
    buffer_write(__LayoutBuffer, buffer_u64, id_ptr); //ID
    buffer_write(__LayoutBuffer, buffer_u8, ClaySizing.Fit); //Width type
    buffer_write(__LayoutBuffer, buffer_u32, 0); //Width value
    buffer_write(__LayoutBuffer, buffer_u8, ClaySizing.Fit); //Height type
    buffer_write(__LayoutBuffer, buffer_u32, 0); //Height value
    buffer_write(__LayoutBuffer, buffer_u16, 0); //Left Padding
    buffer_write(__LayoutBuffer, buffer_u16, 0); //Right Padding
    buffer_write(__LayoutBuffer, buffer_u16, 0); //Top Padding
    buffer_write(__LayoutBuffer, buffer_u16, 0); //Bottom padding
    buffer_write(__LayoutBuffer, buffer_u16, 0); //Child Gap
    buffer_write(__LayoutBuffer, buffer_f32, 0); //Red
    buffer_write(__LayoutBuffer, buffer_f32, 0); //Green
    buffer_write(__LayoutBuffer, buffer_f32, 0); //Blue
    buffer_write(__LayoutBuffer, buffer_f32, 0); //Alpha
    buffer_write(__LayoutBuffer, buffer_u8, ClayLayoutDirection.LeftToRight); //Direction
    buffer_write(__LayoutBuffer, buffer_u8, fa_left); //Halign
    buffer_write(__LayoutBuffer, buffer_u8, fa_top); //Valign
    buffer_write(__LayoutBuffer, buffer_u64, 0); // Data ptr
    buffer_write(__LayoutBuffer, buffer_u16, 0); // FontID
    buffer_write(__LayoutBuffer, buffer_u16, 12); // FontSize
    buffer_write(__LayoutBuffer, buffer_f32, 255); // Text Red
    buffer_write(__LayoutBuffer, buffer_f32, 255); // Text Green
    buffer_write(__LayoutBuffer, buffer_f32, 255); // Text Blue
    buffer_write(__LayoutBuffer, buffer_f32, 255); // Text Alpha
    
    assert_eq(buffer_tell(__LayoutBuffer)-prev_pos, __ClayStruct.Size);
    
    __StackDepth += 1;
    __ElementAmount += 1;
}

function CLAY_WIDTH(type, value) {
    __clay_assert_layout_has_begun();
    
    buffer_poke(__LayoutBuffer, __LayoutPos+__ClayStruct.WidthType, buffer_u8, type);
    buffer_poke(__LayoutBuffer, __LayoutPos+__ClayStruct.WidthValue, buffer_u32, value);
}
function CLAY_HEIGHT(type, value) {
    __clay_assert_layout_has_begun();
    
    buffer_poke(__LayoutBuffer, __LayoutPos+__ClayStruct.HeightType, buffer_u8, type);
    buffer_poke(__LayoutBuffer, __LayoutPos+__ClayStruct.HeightValue, buffer_u32, type);
}
function CLAY_PADDING_ALL(value) {
    __clay_assert_layout_has_begun();
    
    buffer_seek(__LayoutBuffer, buffer_seek_start, __LayoutPos+__ClayStruct.PaddingLeft);
    buffer_write(__LayoutBuffer, buffer_u16, value);
    buffer_write(__LayoutBuffer, buffer_u16, value);
    buffer_write(__LayoutBuffer, buffer_u16, value);
    buffer_write(__LayoutBuffer, buffer_u16, value);
}
function CLAY_CHILD_GAP(value) {
    __clay_assert_layout_has_begun();
    
    buffer_poke(__LayoutBuffer, __LayoutPos+__ClayStruct.ChildGap, buffer_u16, value);
}
function CLAY_BACKGROUND_COLOR_RGBA(r, g, b, a) {
    __clay_assert_layout_has_begun();
    
    buffer_seek(__LayoutBuffer, buffer_seek_start, __LayoutPos+__ClayStruct.BackgroundColorRed);
    buffer_write(__LayoutBuffer, buffer_f32, r);
    buffer_write(__LayoutBuffer, buffer_f32, g);
    buffer_write(__LayoutBuffer, buffer_f32, b);
    buffer_write(__LayoutBuffer, buffer_f32, a)
}
function CLAY_DIRECTION(dir) {
    __clay_assert_layout_has_begun();
    
    buffer_poke(__LayoutBuffer, __LayoutPos+__ClayStruct.Direction, buffer_u8, dir);
}
function CLAY_BACKGROUND_COLOR(color) {
    __clay_assert_layout_has_begun();
    
    var r = color & (0xFF);
    var g = color & (0xFF_00);
    var b = color & (0xFF_00_00);
    CLAY_BACKGROUND_COLOR_RGBA(r, g, b, 255);
}
function CLAY_VALIGN(valign) {
    __clay_assert_layout_has_begun();
    
    buffer_poke(__LayoutBuffer, __LayoutPos+__ClayStruct.Valign, buffer_u8, valign);
}
function CLAY_HALIGN(halign) {
    __clay_assert_layout_has_begun();
    
    buffer_poke(__LayoutBuffer, __LayoutPos+__ClayStruct.Halign, buffer_u8, halign);
}
function CLAY_TEXT(text) {
    __clay_assert_layout_has_begun();
    
    static ptr_map = ds_map_create();
    
    var char_ptr = int64(0);
    if ds_map_exists(ptr_map, text) {
        char_ptr = ptr_map[? text];
    } else {
        char_ptr = __Clay_GameMakerAllocString(text);
        ptr_map[? text] = char_ptr;
    }
    assert_ne(char_ptr, 0);
    
    buffer_poke(__LayoutBuffer, __LayoutPos+__ClayStruct.Data, buffer_u64, char_ptr);
}
function CLAY_TEXT_FONT_SIZE(size) {
    __clay_assert_layout_has_begun();
    
    buffer_poke(__LayoutBuffer, __LayoutPos+__ClayStruct.FontSize, buffer_u16, size);
}
function CLAY_TEXT_COLOR_RGBA(r, g, b, a) {
    __clay_assert_layout_has_begun();
    
    buffer_seek(__LayoutBuffer, buffer_seek_start, __LayoutPos+__ClayStruct.FontColorRed);
    buffer_write(__LayoutBuffer, buffer_f32, r);
    buffer_write(__LayoutBuffer, buffer_f32, g);
    buffer_write(__LayoutBuffer, buffer_f32, b);
    buffer_write(__LayoutBuffer, buffer_f32, a);
}

globalvar __ClayGameMakerAllocString_Handler;
__ClayGameMakerAllocString_Handler = external_define(LIB_PATH, "GameMakerAllocString", dll_cdecl, ty_string, 2, ty_string, ty_string);
function __Clay_GameMakerAllocString(text) {
    var output_addr = buffer_get_address(global.extrn_output);
    var result = external_call(__ClayGameMakerAllocString_Handler, text, output_addr);
    assert_eq(result, "OK");
    return buffer_peek(global.extrn_output, 0, buffer_u64);
}

function CLAY_END() {
    __clay_assert_layout_has_begun();
    
    __StackDepth -= 1;
}
