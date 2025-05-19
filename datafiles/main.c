#include <math.h>
#include <inttypes.h>
#include <string.h>
#define CLAY_IMPLEMENTATION
#include "clay.h"
#include <stdio.h>

typedef struct {
    char* error_output;
    uint64_t screen_width;
    uint64_t screen_height;
} InitArgs;

static char** error_output = NULL;

void HandleClayErrors(Clay_ErrorData error_data) {
    printf("%s\n", error_data.errorText.chars);
    fflush(stdout);
    if (error_output != NULL) {
        strncpy(*error_output, error_data.errorText.chars, error_data.errorText.length);
    }
}

Clay_Dimensions MeasureText(Clay_StringSlice text, Clay_TextElementConfig *config, void* userData) {
    // Clay_TextElementConfig contains members such as fontId, fontSize, letterSpacing etc
    // Note: Clay_String->chars is not guaranteed to be null terminated
    return (Clay_Dimensions) {
            .width = text.length * config->fontSize, // <- this will only work for monospace fonts, see the renderers/ directory for more advanced text measurement
            .height = config->fontSize
    };
}

char* clay_init(InitArgs* args) {
    error_output = &args->error_output;

    uint64_t clay_required_memory = Clay_MinMemorySize();

    Clay_Arena clay_memory = (Clay_Arena) {
        .memory = malloc(clay_required_memory),
        .capacity = clay_required_memory
    };
    Clay_Dimensions clay_dimensions = (Clay_Dimensions) {
        .width = args->screen_width,
        .height = args->screen_height
    };

    Clay_Initialize(clay_memory, clay_dimensions, (Clay_ErrorHandler) {HandleClayErrors});
    Clay_SetMeasureTextFunction(&MeasureText, NULL);

    return "OK";
}

_Static_assert(sizeof(float) == 4, "Float should be 4 bytes long");
typedef struct {
    float screen_width;
    float screen_height;
    float mouse_pos_x;
    float mouse_pos_y;
    float mouse_wheel;
    uint32_t mouse_is_down;
    float delta_time; 
} UpdateArgs;

const Clay_Color WHITE = (Clay_Color) {255,255,255,255};
const Clay_Color RED = (Clay_Color) {255,0,0,255};

/* typedef struct { */
/*     const void* output_buffer; */
/*     uint32_t offset; */
/* } ClayGetStringArgs; */
/* char* clay_get_string(ClayGetStringArgs* args) { */
/*     if (args->output_buffer == NULL) { */
/*         return "Provided a null pointer"; */
/*     } */
/*     Clay_StringSlice* slice = (Clay_StringSlice*) (args->output_buffer + args->offset); */
/*     if (slice->length > 500) { */
/*         return "Maximum string length is 500"; */
/*     } */
/**/
/*     static char char_buf[500]; */
/*     strncpy(char_buf, slice->chars, slice->length); */
/*     char_buf[slice->length] = '\0'; */
/**/
/*     return (char*) char_buf; */
/* } */
char* cstring_get_string(const char* buf, double length) {
    if (floor(length) != length) {
        fprintf(stderr, "Provided length was not an integer: %lf", length);
    }

    static char char_buf[500];
    strncpy(char_buf, buf, length);
    char_buf[(int) length] = '\0';

    return char_buf;
}

char* clay_update(UpdateArgs* args_ptr, void* output) {
    UpdateArgs args = *args_ptr;
    
    Clay_SetLayoutDimensions((Clay_Dimensions) {args.screen_width, args.screen_height});
    Clay_SetPointerState((Clay_Vector2) {args.mouse_pos_x, args.mouse_pos_y}, args.mouse_is_down);
    Clay_UpdateScrollContainers(false, (Clay_Vector2) {0, args.mouse_wheel}, args.delta_time);

    Clay_BeginLayout();

    CLAY({ .id = CLAY_ID("OuterContainer"), .layout = { .sizing = {CLAY_SIZING_GROW(0), CLAY_SIZING_GROW(0)}, .padding = CLAY_PADDING_ALL(16), .childGap = 16 }, .backgroundColor = {250,250,255,255} }) {
        CLAY({
                .id = CLAY_ID("SideBar"),
                .layout = { .layoutDirection = CLAY_TOP_TO_BOTTOM, .sizing = { .width = CLAY_SIZING_FIXED(300), .height = CLAY_SIZING_GROW(0) }, .padding = CLAY_PADDING_ALL(16), .childGap = 16 },
                .backgroundColor = WHITE,
                }) {
            CLAY({ .id = CLAY_ID("ProfilePictureOuter"), .layout = { .sizing = { .width = CLAY_SIZING_GROW(0) }, .padding = CLAY_PADDING_ALL(16), .childGap = 16, .childAlignment = { .y = CLAY_ALIGN_Y_CENTER } }, .backgroundColor = RED }) {
                CLAY_TEXT(CLAY_STRING("Clay - UI Library"), CLAY_TEXT_CONFIG({ .fontSize = 24, .textColor = {255, 255, 255, 255} }));
            }

            // Standard C code like loops etc work inside components
            for (int i = 0; i < 5; i++) {
                //SidebarItemComponent();
            }

            CLAY({ .id = CLAY_ID("MainContent"), .layout = { .sizing = { .width = CLAY_SIZING_GROW(0), .height = CLAY_SIZING_GROW(0) } }, .backgroundColor = WHITE }) {}
        }
    }
    Clay_RenderCommandArray render_commands = Clay_EndLayout();

    *((uint32_t*) output) = render_commands.length;
    memcpy(output + sizeof(uint32_t), render_commands.internalArray, render_commands.length * sizeof(Clay_RenderCommand));

    return "OK";
}

