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

char* GameMakerAllocString(char* text, char** output) {
    int len = strlen(text);
    char* text_copy = malloc(len);
    *output = text_copy;
    
    return "OK";
}

char* AllocClayID(char* id, Clay_ElementId** output) {
    Clay_String str;
    str.isStaticallyAllocated = false;
    str.length = strlen(id);
    str.chars = id;

    Clay_ElementId* element_id = malloc(sizeof(Clay_ElementId));
    *element_id = CLAY_SID(str);

    *output = element_id;

    return "OK";
}

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
    uint32_t element_amount;
} UpdateArgs;

enum SizingType : uint8_t {
    Fit,
    Grow,
    Percent,
    Fixed,
};

typedef enum SizingType SizingType;

#pragma pack(1)
typedef struct {
    SizingType type;
    uint32_t value;
} ElementSizing;
_Static_assert(sizeof(ElementSizing) == 5, "Element sizing is wrong");

typedef struct {
    float red;
    float green;
    float blue;
    float alpha;
} Color;

typedef struct {
    uint16_t left;
    uint16_t right;
    uint16_t top;
    uint16_t bottom;
} ElementPadding;

enum LayoutDirection : uint8_t {
    LeftToRight,
    TopToBottom,
};
typedef enum LayoutDirection LayoutDirection;

enum Halign : uint8_t {
    Left,
    Center,
    Right
};
typedef enum Halign Halign;

enum Valign : uint8_t {
    Top,
    Middle,
    Bottom,
};
typedef enum Valign Valign;

_Static_assert(sizeof(Clay_ElementId) == 32, "Clay ID should be 32 bytes long");
#pragma pack(1)
typedef struct {
    uint16_t stack_depth;
    Clay_ElementId* clay_id;
    ElementSizing width;
    ElementSizing height;
    ElementPadding padding;
    uint16_t child_gap;
    Color background_color;
    LayoutDirection direction;
    Halign halign;
    Valign valign;
    char* data;
    uint16_t font_id;
    uint16_t font_size;
    Color font_alpha;
} LayoutElement;
_Static_assert(sizeof(LayoutElement) == 77, "LayoutElement should be 77 bytes long");

typedef struct {
    LayoutElement* layout_buffer;
} PointerArgs;

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

void parse_element(LayoutElement* element_buffer, int* i, int element_amt) {
    LayoutElement* element = &element_buffer[*i];

    Color color = element->background_color;
    Clay_SizingAxis width_sizing;
    Clay_SizingAxis height_sizing;
    Clay_LayoutDirection direction;

    switch (element->width.type) {
        case Fit:
            width_sizing = CLAY_SIZING_FIT();
            break;
        case Grow:
            width_sizing = CLAY_SIZING_GROW(element->width.value);
            break;
        case Percent:
            width_sizing = CLAY_SIZING_PERCENT(element->width.value);
            break;
        case Fixed:
            width_sizing = CLAY_SIZING_FIXED(element->width.value);
            break;
        default:
            printf("Unknown type: %d", element->width.type);
            break;
    }
    switch (element->height.type) {
        case Fit:
            height_sizing = CLAY_SIZING_FIT();
            break;
        case Grow:
            height_sizing = CLAY_SIZING_GROW(element->height.value);
            break;
        case Percent:
            height_sizing = CLAY_SIZING_PERCENT(element->height.value);
            break;
        case Fixed:
            height_sizing = CLAY_SIZING_FIXED(element->height.value);
            break;
        default:
            printf("Unknown type: %d", element->height.type);
            break;
    }

    switch (element->direction) {
        case TopToBottom:
            direction = CLAY_TOP_TO_BOTTOM;
            break;
        case LeftToRight:
            direction = CLAY_LEFT_TO_RIGHT;
            break;
        default:
            printf("Unknown type: %d", element->direction);
            break;
    }

    Clay_Padding padding;
    padding.left = element->padding.left;
    padding.right = element->padding.right;
    padding.top = element->padding.top;
    padding.bottom = element->padding.bottom;

    Clay_ElementDeclaration element_config = {
        .layout = {
            .sizing = {width_sizing, height_sizing},
            .padding = padding,
            .childGap = element->child_gap,
            .layoutDirection = direction,
        },
        .backgroundColor = {color.red,color.green,color.blue,color.alpha},
    };

    if (element->clay_id != NULL) {
        element_config.id = *element->clay_id;
    }

    CLAY(element_config) {
        uint16_t stack_depth = element->stack_depth;
        for (;;) {
            *i += 1;
            if (*i >= element_amt) {
                break;
            }

            parse_element(element_buffer, i, element_amt);
            if (*i >= element_amt) {
                break;
            }

            if (element_buffer[*i].stack_depth < stack_depth) {
                break;
            }
        }
    }
    // CLAY({ .id = CLAY_ID("OuterContainer"), .layout = { .sizing = {CLAY_SIZING_GROW(0), CLAY_SIZING_GROW(0)}, .padding = CLAY_PADDING_ALL(16), .childGap = 16 }, .backgroundColor = {250,250,255,255} }) {
    // }

    return;
}

char* clay_update(UpdateArgs* args_ptr, void* output, PointerArgs* ptr_args_ptr) {
    UpdateArgs args = *args_ptr;
    PointerArgs ptr_args = *ptr_args_ptr;
    LayoutElement* layout_buffer = ptr_args.layout_buffer;
    
    Clay_SetLayoutDimensions((Clay_Dimensions) {args.screen_width, args.screen_height});
    Clay_SetPointerState((Clay_Vector2) {args.mouse_pos_x, args.mouse_pos_y}, args.mouse_is_down);
    Clay_UpdateScrollContainers(false, (Clay_Vector2) {0, args.mouse_wheel}, args.delta_time);

    Clay_BeginLayout();

    uint32_t stack_depth = 0;

    int i = 0;
    parse_element(layout_buffer, &i, args.element_amount);

    // CLAY({ .id = CLAY_ID("OuterContainer"), .layout = { .sizing = {CLAY_SIZING_GROW(0), CLAY_SIZING_GROW(0)}, .padding = CLAY_PADDING_ALL(16), .childGap = 16 }, .backgroundColor = {250,250,255,255} }) {
        // CLAY({
        //         .id = CLAY_ID("SideBar"),
        //         .layout = { .layoutDirection = CLAY_TOP_TO_BOTTOM, .sizing = { .width = CLAY_SIZING_FIXED(300), .height = CLAY_SIZING_GROW(0) }, .padding = CLAY_PADDING_ALL(16), .childGap = 16 },
        //         .backgroundColor = WHITE,
        //         }) {
        //     CLAY({ .id = CLAY_ID("ProfilePictureOuter"), .layout = { .sizing = { .width = CLAY_SIZING_GROW(0) }, .padding = CLAY_PADDING_ALL(16), .childGap = 16, .childAlignment = { .y = CLAY_ALIGN_Y_CENTER } }, .backgroundColor = RED }) {
        //         // CLAY_TEXT(CLAY_STRING("Clay - UI Library"), CLAY_TEXT_CONFIG({ .fontSize = 24, .textColor = {255, 255, 255, 255} }));
        //     }
        //
        //     // Standard C code like loops etc work inside components
        //     for (int i = 0; i < 5; i++) {
        //         //SidebarItemComponent();
        //     }
        //
        //     CLAY({ .id = CLAY_ID("MainContent"), .layout = { .sizing = { .width = CLAY_SIZING_GROW(0), .height = CLAY_SIZING_GROW(0) } }, .backgroundColor = WHITE }) {}
        // }
    // }
    Clay_RenderCommandArray render_commands = Clay_EndLayout();

    *((uint32_t*) output) = render_commands.length;

    memcpy(output + sizeof(uint32_t), render_commands.internalArray, render_commands.length * sizeof(Clay_RenderCommand));

    return "OK";
}

