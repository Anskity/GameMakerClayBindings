enum __ClayCommandType {
    None,
    Rectangle,
    Border,
    Text,
    Image,
    ScissorStart,
    ScissorEnd,
    Custom,
}

function clay_update() {
    static update_handler = external_define(LIB_PATH, "clay_update", dll_cdecl, ty_string, 2, ty_string, ty_string);
    static args_buffer = buffer_create(1024, buffer_fixed, 1);
    static output_buffer = buffer_create(20*MB, buffer_fixed, 1);
    
    var error_output = buffer_peek(__ClayErrorOutput, 0, buffer_string);
    if error_output != "" {
        show_error($"CLAY ERROR: {error_output}", true);
    }
    
    buffer_seek(args_buffer, buffer_seek_start, 0);
    buffer_write(args_buffer, buffer_f32, window_get_width());
    buffer_write(args_buffer, buffer_f32, window_get_height());
    buffer_write(args_buffer, buffer_f32, window_views_mouse_get_x());
    buffer_write(args_buffer, buffer_f32, window_views_mouse_get_y());
    buffer_write(args_buffer, buffer_f32, -mouse_wheel_down()-mouse_wheel_up());
    buffer_write(args_buffer, buffer_f32, mouse_check_button(mb_left));
    buffer_write(args_buffer, buffer_f32, delta_time);
    
    external_call(update_handler, buffer_get_address(args_buffer), buffer_get_address(output_buffer));
    
    buffer_seek(output_buffer, buffer_seek_start, 0);
    var commands_amt = buffer_read(output_buffer, buffer_u32);
    repeat commands_amt {
        var box_x = buffer_read(output_buffer, buffer_f32);
        var box_y = buffer_read(output_buffer, buffer_f32);
        var box_width = buffer_read(output_buffer, buffer_f32);
        var box_height = buffer_read(output_buffer, buffer_f32);
        
        var data_pos = buffer_tell(output_buffer);
        
        // Skipping through the render data
        buffer_read(output_buffer, buffer_u64);
        buffer_read(output_buffer, buffer_u64);
        buffer_read(output_buffer, buffer_u64);
        buffer_read(output_buffer, buffer_u64);
        buffer_read(output_buffer, buffer_u64);
        buffer_read(output_buffer, buffer_u64);
        
        var user_data_ptr = buffer_read(output_buffer, buffer_u64);
        var element_id = buffer_read(output_buffer, buffer_u32);
        var z_index = buffer_read(output_buffer, buffer_u16);
        var command_type = buffer_read(output_buffer, buffer_u8);
        buffer_read(output_buffer, buffer_u8); //Struct Padding
        
        var end_pos = buffer_tell(output_buffer);
        buffer_seek(output_buffer, buffer_seek_start, data_pos);
        
        switch command_type {
        case __ClayCommandType.None:
        break;
        case __ClayCommandType.Rectangle:{
            var red = buffer_read(output_buffer, buffer_f32);
            var green = buffer_read(output_buffer, buffer_f32);
            var blue = buffer_read(output_buffer, buffer_f32);
            var alpha = buffer_read(output_buffer, buffer_f32);
            
            var radius_top_left = buffer_read(output_buffer, buffer_f32);
            var radius_top_right = buffer_read(output_buffer, buffer_f32);
            var radius_bottom_left = buffer_read(output_buffer, buffer_f32);
            var radius_bottom_right = buffer_read(output_buffer, buffer_f32);
            
            // Different corner radius for different corners is not suported, so we'll get the average instead
            var radius = (radius_top_left + radius_top_right + radius_bottom_left + radius_bottom_right)/4;
            
            draw_set_color(make_color_rgb(red, green, blue));
            draw_set_alpha(alpha);
            draw_roundrect_ext(box_x, box_y, box_x+box_width, box_y+box_height, radius, radius, false);
            
            draw_set_color(c_white);
            draw_set_alpha(1);
        }break;
        case __ClayCommandType.Text:{
            var str_len = buffer_read(output_buffer, buffer_s32);
            buffer_read(output_buffer, buffer_u32); //Struct Padding
            var char_ptr = buffer_read(output_buffer, buffer_u64);
            buffer_read(output_buffer, buffer_u64); //Base char
            
            var text = cstring_get_string(ptr(char_ptr), str_len);
            
            var red = buffer_read(output_buffer, buffer_f32);
            var green = buffer_read(output_buffer, buffer_f32);
            var blue = buffer_read(output_buffer, buffer_f32);
            var alpha = buffer_read(output_buffer, buffer_f32);
            var font_id = buffer_read(output_buffer, buffer_u16);
            var font_size = buffer_read(output_buffer, buffer_u16);
            var letter_spacing = buffer_read(output_buffer, buffer_u16);
            var line_height = buffer_read(output_buffer, buffer_u16);
            
            draw_set_color(make_color_rgb(red, green, blue));
            draw_set_alpha(alpha);
            
            draw_text(box_x, box_y, text);
            
            draw_set_color(c_white);
            draw_set_alpha(1);
        }break;
        default:
            show_error($"Unhandled command type: {command_type}", true);
        }
        
        buffer_seek(output_buffer, buffer_seek_start, end_pos);
    }
}