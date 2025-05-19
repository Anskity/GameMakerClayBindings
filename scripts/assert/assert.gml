#macro TYPE_ARRAY "array"
#macro TYPE_NUMBER "number"

function assert_exists(value) {
    if is_undefined(value) {
        show_error("ASSERTION FAILED! VALUE IS UNDEFINED!", true);
    }
}

function assert_type(value, type) {
    assert_exists(value);
    assert_exists(type);
    
    if typeof(value) != type {
        show_error($"Unmatched type: typeof {value} != {type}", true);
    }
}