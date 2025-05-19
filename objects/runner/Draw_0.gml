function SidebarItemComponent() {
    CLAY_NEW();
        CLAY_WIDTH(ClaySizing.Grow, 0);
        CLAY_HEIGHT(ClaySizing.Fixed, 50);
        CLAY_BACKGROUND_COLOR(c_orange);
    
    CLAY_END();
}

Clay_BeginLayout();

CLAY_NEW("OuterContainer")
CLAY_WIDTH(ClaySizing.Grow, 0);
CLAY_HEIGHT(ClaySizing.Grow, 0);
CLAY_PADDING(ClayPadding.All, 16);
CLAY_CHILD_GAP(16)
CLAY_BACKGROUND_COLOR_RGBA(250, 250, 255, 255);

    CLAY_NEW("SideBar");
    CLAY_DIRECTION(ClayDireciton.TopToBottom);
    CLAY_WIDTH(ClaySizing.Fixed, 300);
    CLAY_HEIGHT(ClaySizing.Grow, 0);
    CLAY_PADDING(16);
    CLAY_CHILD_GAP(16);
    CLAY_BACKGROUND_COLOR(c_white);

        CLAY_NEW("ProfilePictureOuter");
        CLAY_WIDTH(ClaySizing.Grow, 0);
        CLAY_PADDING(ClayPadding.All, 16);
        CLAY_CHILD_GAP(16);
        CLAY_VALIGN(fa_center);
        CLAY_BACKGROUND_COLOR(c_red);
            CLAY_TEXT("Clay - UI Library");
            CLAY_TEXT_FONT_SIZE(24);
            CLAY_TEXT_COLOR_RGBA(255, 255, 255, 255);
        CLAY_END();
        
        for (var i = 0; i < 5; ++i) {
                SidebarItemComponent();
        }

        CLAY_NEW("MainContent");
        CLAY_WIDTH(ClaySizing.Grow, 0);
        CLAY_HEIGHT(ClaySizing.Grow, 0);
        CLAY_BACKGROUND_COLOR(c_white);
        CLAY_END();
        
    CLAY_END();

CLAY_END();

clay_update();