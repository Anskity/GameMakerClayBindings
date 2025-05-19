#include "main.c"

int main() {
    const int CAPACITY = 1024*1024*2;
    void* buffer = malloc(CAPACITY);

    InitArgs init_args;
    init_args.error_output = "HI";
    init_args.screen_width = 1280;
    init_args.screen_height = 720;

    clay_init(&init_args);

    UpdateArgs update_args;
    update_args.screen_width = 1280;
    update_args.screen_height = 720;
    update_args.delta_time = 1./60.;
    update_args.mouse_is_down = 0;
    update_args.mouse_pos_x = 0.;
    update_args.mouse_pos_y = 0.;
    update_args.mouse_wheel = 0.;

    void* output = malloc(1024*1024*4);

    clay_update(&update_args, output);

    return 0;
}
