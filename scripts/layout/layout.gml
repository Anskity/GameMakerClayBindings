globalvar __LayoutBuffer;
__LayoutBuffer = buffer_create(3*MB, buffer_fixed, 1);

globalvar __LayoutPos;
__LayoutPos = 0;

function Clay_BeginLayout() {
    __LayoutPos = 0;
}

enum __ClayStruct {
    ClayID = 0, //We are producing the ID externally
    WidthType = 16,
    WidthValue = 20,
    HeightType = 24,
    HeightValue = 28,
    PaddingType = 32,
    PaddingValue = 36,
    ChildGap = 40,
    BackgroundColorRed = 44,
    BackgroundColorGreen = 48,
    BackgroundColorBlue = 52,
    BackgroundColorAlpha = 56,
    Direction = 60,
    Halign = 64,
    Valign = 68,
    Data = 72, // Its a string pointer, if its NULL then this is not text
    
    Size = 80
}

function CLAY_NEW(clay_id=undefined) {
    
    
    __LayouPos += __ClayStruct.Size;
}
